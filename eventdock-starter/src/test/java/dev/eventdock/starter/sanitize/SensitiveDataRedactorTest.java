package dev.eventdock.starter.sanitize;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.model.DiagnosticEvent;
import dev.eventdock.starter.model.RequestMetadata;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class SensitiveDataRedactorTest {

    private SensitiveDataRedactor redactor;
    private EventDockProperties properties;

    @BeforeEach
    void setUp() {
        properties = new EventDockProperties();
        properties.getCapture().setBodyEnabled(false);
        properties.getCapture().setMaxStackTraceFrames(5);
        redactor = new SensitiveDataRedactor(properties, new ObjectMapper());
    }

    @Test
    @DisplayName("Should sanitize diagnostic event and strip bodies by default")
    void testSanitizeEvent() {
        RequestMetadata metadata = RequestMetadata.builder()
                .headers(Map.of("Authorization", "Bearer topSecretToken", "Host", "api.linkpeer.internal"))
                .build();

        DiagnosticEvent event = DiagnosticEvent.builder()
                .metadata(metadata)
                .requestBody("{\"password\":\"mypass\"}")
                .responseBody("{\"token\":\"respToken\"}")
                .build();

        redactor.sanitizeEvent(event);

        assertThat(event.getMetadata().getHeaders())
                .containsEntry("Authorization", HeaderRedactor.REDACTED_PLACEHOLDER)
                .containsEntry("Host", "api.linkpeer.internal");

        assertThat(event.getRequestBody()).isNull();
        assertThat(event.getResponseBody()).isNull();
    }

    @Test
    @DisplayName("Should truncate deep stack traces to configured maximum frames")
    void testStackTraceFormatting() {
        Exception ex = new RuntimeException("Simulated failure in database driver");
        String formatted = redactor.formatStackTrace(ex);

        assertThat(formatted)
                .isNotNull()
                .contains("Simulated failure in database driver")
                .contains("frames omitted for brevity");
    }
}
