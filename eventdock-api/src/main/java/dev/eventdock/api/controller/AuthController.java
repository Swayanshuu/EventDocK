package dev.eventdock.api.controller;

import dev.eventdock.api.dto.UserDto;
import dev.eventdock.api.service.AuthService;
import dev.eventdock.api.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Firebase user profile and identity management")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @GetMapping("/me")
    @Operation(summary = "Get current authenticated user profile from Firebase identity")
    public ResponseEntity<ApiResponse<UserDto>> getCurrentUser(HttpServletRequest request) {
        UUID userId = (UUID) request.getAttribute("authenticatedUserId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure("Authentication required (Firebase Bearer token)"));
        }
        UserDto profile = authService.getUserProfile(userId);
        return ResponseEntity.ok(ApiResponse.ok(profile));
    }
}
