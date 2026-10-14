package dev.eventdock.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReplayRequest {

    @NotBlank(message = "Destination target URL is required (e.g. http://localhost:8081)")
    private String destinationUrl;

    /**
     * Explicit confirmation required when replaying state-changing methods (POST, PUT, DELETE, PATCH).
     */
    @Builder.Default
    private boolean confirmUnsafeMethod = false;
}
