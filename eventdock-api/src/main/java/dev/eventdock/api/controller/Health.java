package dev.eventdock.api.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

/**
 * Public health check endpoint for cloud platforms (Render, Railway, AWS),
 * load balancers, and external uptime monitors.
 */
@RestController
@RequestMapping({"/health", "/api/v1/health"})
@Tag(name = "Health", description = "Health and readiness verification endpoints")
public class Health {

    @GetMapping
    @Operation(summary = "Service Health Check", description = "Verifies the EventDock API service is healthy and accepting traffic")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "service", "eventdock-api",
                "timestamp", Instant.now().toString()
        ));
    }
}
