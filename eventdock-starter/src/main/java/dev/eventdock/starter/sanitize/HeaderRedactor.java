package dev.eventdock.starter.sanitize;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Sanitizes HTTP header maps by replacing sensitive header values with ***REDACTED***.
 */
public class HeaderRedactor {

    public static final String REDACTED_PLACEHOLDER = "***REDACTED***";

    private final Set<String> sensitiveHeadersLower;

    public HeaderRedactor(Set<String> sensitiveHeaders) {
        if (sensitiveHeaders == null) {
            this.sensitiveHeadersLower = Set.of();
        } else {
            this.sensitiveHeadersLower = sensitiveHeaders.stream()
                    .map(String::toLowerCase)
                    .collect(Collectors.toSet());
        }
    }

    public Map<String, String> redact(Map<String, String> rawHeaders) {
        if (rawHeaders == null || rawHeaders.isEmpty()) {
            return Map.of();
        }

        Map<String, String> result = new HashMap<>();
        for (Map.Entry<String, String> entry : rawHeaders.entrySet()) {
            String key = entry.getKey();
            if (key != null && sensitiveHeadersLower.contains(key.toLowerCase())) {
                result.put(key, REDACTED_PLACEHOLDER);
            } else {
                result.put(key, entry.getValue());
            }
        }
        return result;
    }
}
