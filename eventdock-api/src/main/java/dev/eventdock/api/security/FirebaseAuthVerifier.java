package dev.eventdock.api.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.api.dto.FirebaseTokenPayload;
import dev.eventdock.api.exception.UnauthorizedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;

/**
 * Validates and decodes Firebase Auth ID tokens.
 */
@Component
public class FirebaseAuthVerifier {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAuthVerifier.class);

    private final ObjectMapper objectMapper;
    private final String expectedProjectId;
    private final boolean mockEnabled;

    public FirebaseAuthVerifier(
            ObjectMapper objectMapper,
            @Value("${eventdock.auth.firebase.project-id:}") String expectedProjectId,
            @Value("${eventdock.auth.firebase.mock-enabled:true}") boolean mockEnabled) {
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
        this.expectedProjectId = expectedProjectId != null ? expectedProjectId.trim() : "";
        this.mockEnabled = mockEnabled;
    }

    public FirebaseTokenPayload verifyToken(String token) {
        if (token == null || token.isBlank()) {
            throw new UnauthorizedException("Missing authentication token");
        }

        // Support dev mock token for local testing: dev_token_<uid> or test_<uid>
        if (mockEnabled && (token.startsWith("dev_") || token.startsWith("test_"))) {
            String uid = token.replace("dev_", "").replace("test_", "");
            return FirebaseTokenPayload.builder()
                    .uid("firebase_" + uid)
                    .email(uid + "@linkpeer.internal")
                    .name("Developer " + uid)
                    .emailVerified(true)
                    .build();
        }

        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new UnauthorizedException("Malformed Firebase JWT token structure");
            }

            // Decode JWT payload (part 1)
            byte[] payloadBytes = Base64.getUrlDecoder().decode(parts[1]);
            String payloadJson = new String(payloadBytes, StandardCharsets.UTF_8);
            JsonNode claims = objectMapper.readTree(payloadJson);

            // Verify expiration
            if (claims.has("exp")) {
                long expSeconds = claims.get("exp").asLong();
                if (Instant.now().getEpochSecond() > expSeconds) {
                    throw new UnauthorizedException("Firebase token has expired");
                }
            }

            // Verify project id audience if configured
            if (!expectedProjectId.isEmpty() && claims.has("aud")) {
                String aud = claims.get("aud").asText();
                if (!expectedProjectId.equals(aud)) {
                    throw new UnauthorizedException("Invalid token audience for project: " + aud);
                }
            }

            // Extract uid
            String uid = null;
            if (claims.has("user_id")) {
                uid = claims.get("user_id").asText();
            } else if (claims.has("sub")) {
                uid = claims.get("sub").asText();
            }

            if (uid == null || uid.isBlank()) {
                throw new UnauthorizedException("Firebase token missing user ID claim");
            }

            String email = claims.has("email") ? claims.get("email").asText() : uid + "@firebase.user";
            String name = claims.has("name") ? claims.get("name").asText() : email;
            boolean emailVerified = claims.has("email_verified") && claims.get("email_verified").asBoolean();

            return FirebaseTokenPayload.builder()
                    .uid(uid)
                    .email(email)
                    .name(name)
                    .emailVerified(emailVerified)
                    .build();

        } catch (UnauthorizedException ue) {
            throw ue;
        } catch (Exception e) {
            log.debug("Firebase token verification failed: {}", e.getMessage());
            throw new UnauthorizedException("Invalid Firebase authentication token: " + e.getMessage());
        }
    }
}
