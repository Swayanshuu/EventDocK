package dev.eventdock.starter.sanitize;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.model.DiagnosticEvent;
import dev.eventdock.starter.model.RequestMetadata;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Map;

/**
 * Top-level redaction orchestrator for scrubbing sensitive data from diagnostic events.
 */
public class SensitiveDataRedactor {

    private final HeaderRedactor headerRedactor;
    private final BodyRedactor bodyRedactor;
    private final int maxStackTraceFrames;
    private final boolean bodyEnabled;

    public SensitiveDataRedactor(EventDockProperties properties, ObjectMapper objectMapper) {
        this.headerRedactor = new HeaderRedactor(properties.getRedaction().getHeaders());
        this.bodyRedactor = new BodyRedactor(
                objectMapper,
                properties.getRedaction().getBodyFields(),
                properties.getCapture().getMaxBodyLength()
        );
        this.maxStackTraceFrames = properties.getCapture().getMaxStackTraceFrames();
        this.bodyEnabled = properties.getCapture().isBodyEnabled();
    }

    public RequestMetadata redactMetadata(RequestMetadata raw) {
        if (raw == null) {
            return new RequestMetadata();
        }
        Map<String, String> redactedHeaders = headerRedactor.redact(raw.getHeaders());
        return new RequestMetadata(
                redactedHeaders,
                raw.getQueryParams(),
                raw.getClientIp(),
                raw.getContentType(),
                raw.getUserAgent(),
                raw.getContentLength()
        );
    }

    public String redactBody(String body) {
        if (!bodyEnabled || body == null) {
            return null;
        }
        return bodyRedactor.redactAndTruncate(body);
    }

    public String formatStackTrace(Throwable throwable) {
        if (throwable == null) {
            return null;
        }
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        throwable.printStackTrace(pw);
        String fullTrace = sw.toString();

        String[] lines = fullTrace.split("\\r?\\n");
        if (lines.length <= maxStackTraceFrames) {
            return fullTrace;
        }

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < maxStackTraceFrames && i < lines.length; i++) {
            sb.append(lines[i]).append("\n");
        }
        sb.append("\t... [").append(lines.length - maxStackTraceFrames).append(" frames omitted for brevity]");
        return sb.toString();
    }

    public void sanitizeEvent(DiagnosticEvent event) {
        if (event == null) {
            return;
        }
        if (event.getMetadata() != null) {
            event.setMetadata(redactMetadata(event.getMetadata()));
        }
        if (!bodyEnabled) {
            event.setRequestBody(null);
            event.setResponseBody(null);
        } else {
            event.setRequestBody(redactBody(event.getRequestBody()));
            event.setResponseBody(redactBody(event.getResponseBody()));
        }
    }
}
