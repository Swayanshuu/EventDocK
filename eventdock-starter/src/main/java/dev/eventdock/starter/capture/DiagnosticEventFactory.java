package dev.eventdock.starter.capture;

import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.model.DiagnosticEvent;
import dev.eventdock.starter.model.RequestMetadata;
import dev.eventdock.starter.sanitize.SensitiveDataRedactor;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;

import java.time.Instant;

/**
 * Factory responsible for assembling and sanitizing DiagnosticEvent instances from HTTP lifecycle data.
 */
public class DiagnosticEventFactory {

    private static final String BEST_MATCHING_PATTERN_ATTR =
            "org.springframework.web.servlet.HandlerMapping.bestMatchingPattern";

    private final EventDockProperties properties;
    private final RequestMetadataCollector metadataCollector;
    private final SensitiveDataRedactor redactor;

    public DiagnosticEventFactory(EventDockProperties properties,
                                  RequestMetadataCollector metadataCollector,
                                  SensitiveDataRedactor redactor) {
        this.properties = properties;
        this.metadataCollector = metadataCollector;
        this.redactor = redactor;
    }

    public DiagnosticEvent createEvent(HttpServletRequest request,
                                       int statusCode,
                                       long durationMs,
                                       Throwable throwable,
                                       String requestBody,
                                       String responseBody) {
        DiagnosticEvent event = new DiagnosticEvent();
        String correlationId = metadataCollector.resolveOrGenerateCorrelationId(request);

        event.setRequestId(correlationId);
        event.setHttpMethod(request != null ? request.getMethod() : "UNKNOWN");
        event.setRequestUri(request != null ? request.getRequestURI() : "/");

        if (request != null) {
            Object bestPattern = request.getAttribute(BEST_MATCHING_PATTERN_ATTR);
            if (bestPattern != null) {
                event.setRouteTemplate(bestPattern.toString());
            } else {
                event.setRouteTemplate(event.getRequestUri());
            }
        }

        event.setStatusCode(statusCode);
        event.setDurationMs(durationMs);
        event.setOccurredAt(Instant.now());
        event.setServiceName(properties.getServiceName());
        event.setEnvironment(properties.getEnvironment());

        if (throwable != null) {
            event.setErrorType(throwable.getClass().getName());
            event.setErrorMessage(throwable.getMessage() != null ? throwable.getMessage() : throwable.toString());
            event.setStackTrace(redactor.formatStackTrace(throwable));
        } else {
            event.setErrorType("HTTP_" + statusCode);
            try {
                HttpStatus status = HttpStatus.valueOf(statusCode);
                event.setErrorMessage(status.getReasonPhrase());
            } catch (Exception e) {
                event.setErrorMessage("HTTP Error " + statusCode);
            }
        }

        RequestMetadata rawMetadata = metadataCollector.collect(request);
        event.setMetadata(rawMetadata);
        event.setRequestBody(requestBody);
        event.setResponseBody(responseBody);

        // Apply all redaction policies
        redactor.sanitizeEvent(event);

        return event;
    }
}
