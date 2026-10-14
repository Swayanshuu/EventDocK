package dev.eventdock.starter.reporting;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.model.DiagnosticEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;

/**
 * HTTP reporter that sends diagnostic events to the EventDock backend asynchronously.
 */
public class HttpEventDockReporter implements EventDockReporter {

    private static final Logger log = LoggerFactory.getLogger(HttpEventDockReporter.class);
    private static final String API_KEY_HEADER = "X-EventDock-Api-Key";

    private final EventDockProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final AsyncEventQueue asyncQueue;
    private final URI ingestionUri;

    public HttpEventDockReporter(EventDockProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();

        String baseEndpoint = properties.getEndpoint() != null ? properties.getEndpoint().strip() : "http://localhost:8080";
        if (baseEndpoint.endsWith("/")) {
            baseEndpoint = baseEndpoint.substring(0, baseEndpoint.length() - 1);
        }
        this.ingestionUri = URI.create(baseEndpoint + "/api/v1/events");

        int connectTimeout = properties.getNetwork().getConnectTimeoutMs();
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofMillis(connectTimeout > 0 ? connectTimeout : 2000))
                .build();

        this.asyncQueue = new AsyncEventQueue(properties.getQueue(), this::dispatchBatch);
    }

    @Override
    public void report(DiagnosticEvent event) {
        if (!properties.isEnabled() || event == null) {
            return;
        }

        if (properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            log.debug("EventDock API key is not configured; skipping event report for request {}", event.getRequestId());
            return;
        }

        asyncQueue.enqueue(event);
    }

    private void dispatchBatch(List<DiagnosticEvent> events) {
        for (DiagnosticEvent event : events) {
            sendSingleEvent(event);
        }
    }

    public boolean sendSingleEvent(DiagnosticEvent event) {
        try {
            String jsonPayload = objectMapper.writeValueAsString(event);

            int readTimeout = properties.getNetwork().getReadTimeoutMs();
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(ingestionUri)
                    .timeout(Duration.ofMillis(readTimeout > 0 ? readTimeout : 3000))
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .header(API_KEY_HEADER, properties.getApiKey())
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                log.debug("Diagnostic event [{}] successfully delivered to EventDock (HTTP {})",
                        event.getRequestId(), response.statusCode());
                return true;
            } else {
                log.warn("EventDock backend rejected event [{}] with HTTP {}: {}",
                        event.getRequestId(), response.statusCode(), response.body());
                return false;
            }
        } catch (Exception e) {
            // Never compromise the host application if EventDock is offline or failing
            log.debug("Failed to deliver diagnostic event [{}] to EventDock: {}",
                    event.getRequestId(), e.getMessage());
            return false;
        }
    }

    public AsyncEventQueue getAsyncQueue() {
        return asyncQueue;
    }

    @Override
    public void close() {
        asyncQueue.close();
    }
}
