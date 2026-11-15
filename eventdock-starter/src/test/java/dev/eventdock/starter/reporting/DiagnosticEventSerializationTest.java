package dev.eventdock.starter.reporting;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.model.DiagnosticEvent;
import dev.eventdock.starter.model.RequestMetadata;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNoException;

class DiagnosticEventSerializationTest {

    @Test
    @DisplayName("Serializing DiagnosticEvent with Instant field succeeds and produces valid ISO-8601 string")
    void testDiagnosticEventSerializationWithInstant() throws Exception {
        Instant fixedInstant = Instant.parse("2026-11-15T22:30:00Z");

        DiagnosticEvent event = DiagnosticEvent.builder()
                .id("evt-12345")
                .requestId("req-67890")
                .httpMethod("POST")
                .requestUri("/posts/not-a-number")
                .routeTemplate("/posts/{id}")
                .statusCode(500)
                .errorType("java.lang.NullPointerException")
                .errorMessage("Cannot invoke method on null object")
                .stackTrace("java.lang.NullPointerException: Cannot invoke...\n\tat com.test.Service.run(Service.java:42)")
                .durationMs(150)
                .occurredAt(fixedInstant)
                .serviceName("linkpeer-backend")
                .environment("development")
                .metadata(new RequestMetadata(
                        Map.of("content-type", "application/json"),
                        Map.of("page", "1"),
                        "127.0.0.1",
                        "application/json",
                        "Mozilla/5.0",
                        128L
                ))
                .build();

        ObjectMapper mapper = HttpEventDockReporter.configureObjectMapper(new ObjectMapper());

        // Must not throw InvalidDefinitionException for java.time.Instant
        assertThatNoException().isThrownBy(() -> mapper.writeValueAsString(event));

        String json = mapper.writeValueAsString(event);

        assertThat(json).isNotNull();
        assertThat(json).contains("\"occurredAt\":\"2026-11-15T22:30:00Z\"");
        assertThat(json).contains("\"serviceName\":\"linkpeer-backend\"");
        assertThat(json).contains("\"statusCode\":500");
        assertThat(json).contains("\"errorType\":\"java.lang.NullPointerException\"");

        // Verify deserialization back to DiagnosticEvent preserves Instant precision
        DiagnosticEvent deserialized = mapper.readValue(json, DiagnosticEvent.class);
        assertThat(deserialized.getOccurredAt()).isEqualTo(fixedInstant);
        assertThat(deserialized.getId()).isEqualTo("evt-12345");
        assertThat(deserialized.getStatusCode()).isEqualTo(500);
    }

    @Test
    @DisplayName("HttpEventDockReporter successfully configures vanilla ObjectMapper to serialize Instant")
    void testHttpEventDockReporterWithVanillaObjectMapper() {
        EventDockProperties properties = new EventDockProperties();
        properties.setApiKey("ed_live_test_key");

        // Pass a completely unconfigured ObjectMapper (simulating host apps with bare ObjectMapper)
        ObjectMapper vanillaMapper = new ObjectMapper();
        HttpEventDockReporter reporter = new HttpEventDockReporter(properties, vanillaMapper);

        DiagnosticEvent event = DiagnosticEvent.builder()
                .occurredAt(Instant.now())
                .statusCode(404)
                .build();

        assertThatNoException().isThrownBy(() -> {
            String json = reporter.getObjectMapper().writeValueAsString(event);
            assertThat(json).contains("\"statusCode\":404");
            assertThat(json).contains("\"occurredAt\":");
        });

        reporter.close();
    }
}
