package dev.eventdock.api.dto;

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
public class ApiKeyResponse {
    private UUID id;
    private String name;
    private String keyPrefix;
    private Instant createdAt;
    private Boolean revoked;
    private String rawKey; // Provided ONLY upon key creation!
}
