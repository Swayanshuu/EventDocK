package dev.eventdock.api.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.api.dto.FirebaseTokenPayload;
import dev.eventdock.api.exception.UnauthorizedException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class FirebaseAuthVerifierTest {

    private FirebaseAuthVerifier verifier;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        verifier = new FirebaseAuthVerifier(objectMapper, "eventdock-prod", true);
    }

    @Test
    @DisplayName("Should verify valid Firebase ID token payload successfully")
    void testVerifyValidToken() {
        long exp = Instant.now().plusSeconds(3600).getEpochSecond();
        String payloadJson = String.format("""
                {
                    "sub": "user_firebase_123",
                    "user_id": "user_firebase_123",
                    "email": "developer@linkpeer.internal",
                    "name": "Jane Developer",
                    "aud": "eventdock-prod",
                    "exp": %d
                }
                """, exp);

        String header = Base64.getUrlEncoder().withoutPadding().encodeToString("{\"alg\":\"RS256\"}".getBytes(StandardCharsets.UTF_8));
        String payload = Base64.getUrlEncoder().withoutPadding().encodeToString(payloadJson.getBytes(StandardCharsets.UTF_8));
        String signature = "mock_sig_part";
        String token = header + "." + payload + "." + signature;

        FirebaseTokenPayload result = verifier.verifyToken(token);

        assertThat(result).isNotNull();
        assertThat(result.getUid()).isEqualTo("user_firebase_123");
        assertThat(result.getEmail()).isEqualTo("developer@linkpeer.internal");
        assertThat(result.getName()).isEqualTo("Jane Developer");
    }

    @Test
    @DisplayName("Should reject expired Firebase ID token")
    void testRejectExpiredToken() {
        long exp = Instant.now().minusSeconds(100).getEpochSecond();
        String payloadJson = String.format("""
                {
                    "sub": "user_123",
                    "aud": "eventdock-prod",
                    "exp": %d
                }
                """, exp);

        String header = Base64.getUrlEncoder().withoutPadding().encodeToString("{\"alg\":\"RS256\"}".getBytes(StandardCharsets.UTF_8));
        String payload = Base64.getUrlEncoder().withoutPadding().encodeToString(payloadJson.getBytes(StandardCharsets.UTF_8));
        String token = header + "." + payload + ".sig";

        assertThatThrownBy(() -> verifier.verifyToken(token))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("expired");
    }

    @Test
    @DisplayName("Should support development mock tokens when mock mode is enabled")
    void testMockDevTokens() {
        FirebaseTokenPayload payload = verifier.verifyToken("dev_shibu");
        assertThat(payload.getUid()).isEqualTo("firebase_shibu");
        assertThat(payload.getEmail()).isEqualTo("shibu@linkpeer.internal");
    }
}
