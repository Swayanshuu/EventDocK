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
public class ReplayResponseDto {
    private UUID id;
    private UUID eventId;
    private String initiatedBy;
    private String destinationUrl;
    private Instant startedAt;
    private Instant completedAt;
    private Integer responseStatus;
    private Long durationMs;
    private String outcome;
    private String safeErrorSummary;
    private String responseSnippet;
}
