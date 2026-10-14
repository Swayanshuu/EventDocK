package dev.eventdock.api.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

public final class ApiKeyHashUtil {

    private ApiKeyHashUtil() {
    }

    public static String hashApiKey(String rawApiKey) {
        if (rawApiKey == null || rawApiKey.isBlank()) {
            throw new IllegalArgumentException("API key cannot be blank");
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(rawApiKey.trim().getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm unavailable", e);
        }
    }
}
