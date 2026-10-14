package dev.eventdock.api.controller;

import dev.eventdock.api.security.ApiKeyAuthenticationFilter;
import dev.eventdock.api.security.FirebaseAuthFilter;
import dev.eventdock.api.exception.UnauthorizedException;
import dev.eventdock.api.dto.ApiResponse;
import dev.eventdock.api.dto.EventDetailDto;
import dev.eventdock.api.dto.EventSummaryDto;
import dev.eventdock.api.dto.IngestEventRequest;
import dev.eventdock.api.dto.IngestEventResponse;
import dev.eventdock.api.service.EventService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@Tag(name = "Diagnostic Events", description = "SDK failure ingestion and developer event inspection")
public class EventController {

    private final EventService eventService;

    public EventController(EventService eventService) {
        this.eventService = eventService;
    }

    @PostMapping({"/events", "/events/ingest"})
    @Operation(summary = "Ingest diagnostic event from Spring Boot Starter (SDK API Key required)")
    public ResponseEntity<ApiResponse<IngestEventResponse>> ingestEvent(
            @Valid @RequestBody IngestEventRequest request,
            HttpServletRequest httpRequest) {
        Object projectIdAttr = httpRequest.getAttribute(ApiKeyAuthenticationFilter.AUTHENTICATED_PROJECT_ID_ATTR);
        if (!(projectIdAttr instanceof UUID projectId)) {
            throw new UnauthorizedException("Valid X-EventDock-Api-Key header is required for event ingestion");
        }

        IngestEventResponse response = eventService.ingestEvent(projectId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Diagnostic event accepted", response));
    }

    @GetMapping("/projects/{projectId}/events")
    @Operation(summary = "Query and filter diagnostic events for a project (paginated)")
    public ResponseEntity<ApiResponse<Page<EventSummaryDto>>> listEvents(
            @PathVariable UUID projectId,
            @RequestParam(required = false) Integer statusCode,
            @RequestParam(required = false) String method,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        PageRequest pageRequest = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)), Sort.by("occurredAt").descending());

        Page<EventSummaryDto> result = eventService.listEvents(userId, projectId, statusCode, method, search, pageRequest);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @GetMapping("/events/{eventId}")
    @Operation(summary = "Inspect detailed diagnostic event and sanitized stack trace")
    public ResponseEntity<ApiResponse<EventDetailDto>> getEventDetail(
            @PathVariable UUID eventId,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        EventDetailDto detail = eventService.getEventDetail(userId, eventId);
        return ResponseEntity.ok(ApiResponse.ok(detail));
    }

    private UUID getAuthenticatedUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(FirebaseAuthFilter.AUTHENTICATED_USER_ID_ATTR);
        if (attr instanceof UUID uuid) {
            return uuid;
        }
        throw new UnauthorizedException("User authentication required (Firebase Bearer token)");
    }
}
