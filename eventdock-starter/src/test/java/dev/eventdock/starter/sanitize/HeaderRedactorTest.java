package dev.eventdock.starter.sanitize;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class HeaderRedactorTest {

    @Test
    @DisplayName("Should redact sensitive headers case-insensitively and preserve safe headers")
    void testRedactHeaders() {
        Set<String> sensitiveHeaders = Set.of("authorization", "cookie", "x-api-key");
        HeaderRedactor redactor = new HeaderRedactor(sensitiveHeaders);

        Map<String, String> rawHeaders = Map.of(
                "Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...",
                "Cookie", "SESSIONID=xyz987",
                "X-Api-Key", "secret-key-12345",
                "User-Agent", "Mozilla/5.0",
                "Content-Type", "application/json"
        );

        Map<String, String> sanitized = redactor.redact(rawHeaders);

        assertThat(sanitized)
                .containsEntry("Authorization", HeaderRedactor.REDACTED_PLACEHOLDER)
                .containsEntry("Cookie", HeaderRedactor.REDACTED_PLACEHOLDER)
                .containsEntry("X-Api-Key", HeaderRedactor.REDACTED_PLACEHOLDER)
                .containsEntry("User-Agent", "Mozilla/5.0")
                .containsEntry("Content-Type", "application/json");
    }

    @Test
    @DisplayName("Should handle null or empty headers gracefully")
    void testNullOrEmptyHeaders() {
        HeaderRedactor redactor = new HeaderRedactor(Set.of("authorization"));
        assertThat(redactor.redact(null)).isEmpty();
        assertThat(redactor.redact(Map.of())).isEmpty();
    }
}
