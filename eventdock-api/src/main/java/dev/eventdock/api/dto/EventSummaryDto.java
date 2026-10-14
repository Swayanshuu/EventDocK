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
public class EventSummaryDto {
    private UUID id;
    private UUID projectId;
    private String requestId;
    private String httpMethod;
    private String routeTemplate;
    private String requestUri;
    private Integer statusCode;
    private String errorType;
    private String sanitizedErrorMessage;
    private Long durationMs;
    private Instant occurredAt;
    private Instant receivedAt;
    private String serviceName;
    private String environment;
}
