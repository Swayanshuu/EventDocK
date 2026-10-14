package dev.eventdock.starter.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;

/**
 * Diagnostic event payload representing an observed API failure reported to EventDock.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DiagnosticEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    @Builder.Default
    private String id = UUID.randomUUID().toString();

    private String requestId;
    private String httpMethod;
    private String requestUri;
    private String routeTemplate;
    private int statusCode;
    private String errorType;
    private String errorMessage;
    private String stackTrace;
    private long durationMs;

    @Builder.Default
    private Instant occurredAt = Instant.now();

    @Builder.Default
    private RequestMetadata metadata = new RequestMetadata();

    private String requestBody;
    private String responseBody;
    private String serviceName;
    private String environment;
}
