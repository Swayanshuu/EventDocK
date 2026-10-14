package dev.eventdock.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IngestEventRequest {

    private String id;

    @NotBlank(message = "Request ID correlation is required")
    private String requestId;

    @NotBlank(message = "HTTP method is required")
    private String httpMethod;

    @NotBlank(message = "Request URI is required")
    private String requestUri;

    private String routeTemplate;

    @NotNull(message = "Status code is required")
    private Integer statusCode;

    private String errorType;
    private String errorMessage;
    private String stackTrace;
    private Long durationMs;
    private Instant occurredAt;
    private Map<String, Object> metadata;
    private String requestBody;
    private String responseBody;
    private String serviceName;
    private String environment;
}
