package dev.eventdock.api.controller;

import dev.eventdock.api.security.FirebaseAuthFilter;
import dev.eventdock.api.exception.UnauthorizedException;
import dev.eventdock.api.dto.ApiResponse;
import dev.eventdock.api.dto.ReplayRequest;
import dev.eventdock.api.dto.ReplayResponseDto;
import dev.eventdock.api.service.ReplayService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/events/{eventId}/replays")
@Tag(name = "Replays", description = "Controlled request replay and local destination forwarding")
public class ReplayController {

    private final ReplayService replayService;

    public ReplayController(ReplayService replayService) {
        this.replayService = replayService;
    }

    @PostMapping
    @Operation(summary = "Replay a failed request against an approved target URL")
    public ResponseEntity<ApiResponse<ReplayResponseDto>> executeReplay(
            @PathVariable UUID eventId,
            @Valid @RequestBody ReplayRequest request,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        ReplayResponseDto response = replayService.executeReplay(userId, eventId, request);
        return ResponseEntity.ok(ApiResponse.ok("Replay attempt executed", response));
    }

    @GetMapping
    @Operation(summary = "Get historical replay attempts for an event")
    public ResponseEntity<ApiResponse<List<ReplayResponseDto>>> listReplays(
            @PathVariable UUID eventId,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        List<ReplayResponseDto> history = replayService.listReplayHistory(userId, eventId);
        return ResponseEntity.ok(ApiResponse.ok(history));
    }

    private UUID getAuthenticatedUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(FirebaseAuthFilter.AUTHENTICATED_USER_ID_ATTR);
        if (attr instanceof UUID uuid) {
            return uuid;
        }
        throw new UnauthorizedException("User authentication required");
    }
}
