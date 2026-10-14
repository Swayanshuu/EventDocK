package dev.eventdock.starter.sanitize;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class BodyRedactorTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("Should mask sensitive JSON keys and leave non-sensitive keys intact")
    void testJsonFieldRedaction() {
        BodyRedactor redactor = new BodyRedactor(
                objectMapper,
                Set.of("password", "token", "ssn"),
                4096
        );

        String json = """
                {
                    "username": "shibu_dev",
                    "password": "superSecretPassword123!",
                    "details": {
                        "email": "dev@linkpeer.internal",
                        "token": "tok_xyz_987",
                        "age": 28
                    }
                }
                """;

        String result = redactor.redactAndTruncate(json);

        assertThat(result)
                .contains("\"username\":\"shibu_dev\"")
                .contains("\"password\":\"***REDACTED***\"")
                .contains("\"email\":\"dev@linkpeer.internal\"")
                .contains("\"token\":\"***REDACTED***\"")
                .contains("\"age\":28")
                .doesNotContain("superSecretPassword123!")
                .doesNotContain("tok_xyz_987");
    }

    @Test
    @DisplayName("Should truncate payloads exceeding max body length")
    void testBodyLengthTruncation() {
        BodyRedactor redactor = new BodyRedactor(objectMapper, Set.of(), 20);
        String largeBody = "This is a very long text string exceeding the limit";

        String result = redactor.redactAndTruncate(largeBody);

        assertThat(result).isNotNull();
        assertThat(result).contains("... [truncated]");
        assertThat(result.startsWith("This is a very long ")).isTrue();
    }
}
