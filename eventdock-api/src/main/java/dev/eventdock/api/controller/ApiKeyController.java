package dev.eventdock.api.controller;

import dev.eventdock.api.dto.ApiKeyResponse;
import dev.eventdock.api.dto.ApiKeySummaryDto;
import dev.eventdock.api.dto.CreateApiKeyRequest;
import dev.eventdock.api.service.ApiKeyService;
import dev.eventdock.api.security.FirebaseAuthFilter;
import dev.eventdock.api.exception.UnauthorizedException;
import dev.eventdock.api.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/projects/{projectId}/keys")
@Tag(name = "API Keys", description = "Project ingestion API key provisioning and revocation")
public class ApiKeyController {

    private final ApiKeyService apiKeyService;

    public ApiKeyController(ApiKeyService apiKeyService) {
        this.apiKeyService = apiKeyService;
    }

    @PostMapping
    @Operation(summary = "Generate a new project ingestion API key (secret displayed once)")
    public ResponseEntity<ApiResponse<ApiKeyResponse>> createApiKey(
            @PathVariable UUID projectId,
            @Valid @RequestBody CreateApiKeyRequest request,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        ApiKeyResponse response = apiKeyService.generateApiKey(userId, projectId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("API key generated successfully. Save this secret now; it will not be displayed again.", response));
    }

    @GetMapping
    @Operation(summary = "List active and revoked API keys for project")
    public ResponseEntity<ApiResponse<List<ApiKeySummaryDto>>> listApiKeys(
            @PathVariable UUID projectId,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        List<ApiKeySummaryDto> keys = apiKeyService.listApiKeys(userId, projectId);
        return ResponseEntity.ok(ApiResponse.ok(keys));
    }

    @DeleteMapping("/{keyId}")
    @Operation(summary = "Revoke an existing API key immediately")
    public ResponseEntity<ApiResponse<Void>> revokeApiKey(
            @PathVariable UUID projectId,
            @PathVariable UUID keyId,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        apiKeyService.revokeApiKey(userId, projectId, keyId);
        return ResponseEntity.ok(ApiResponse.ok("API key revoked successfully", null));
    }

    private UUID getAuthenticatedUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(FirebaseAuthFilter.AUTHENTICATED_USER_ID_ATTR);
        if (attr instanceof UUID uuid) {
            return uuid;
        }
        throw new UnauthorizedException("User authentication required");
    }
}
