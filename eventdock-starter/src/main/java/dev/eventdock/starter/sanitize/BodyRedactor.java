package dev.eventdock.starter.sanitize;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.databind.node.TextNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Redacts sensitive fields in JSON request/response bodies and enforces size constraints.
 */
public class BodyRedactor {

    private static final Logger log = LoggerFactory.getLogger(BodyRedactor.class);
    public static final String REDACTED_VALUE = "***REDACTED***";

    private final ObjectMapper objectMapper;
    private final Set<String> sensitiveFieldsLower;
    private final int maxBodyLength;

    public BodyRedactor(ObjectMapper objectMapper, Set<String> sensitiveFields, int maxBodyLength) {
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
        this.sensitiveFieldsLower = sensitiveFields != null
                ? sensitiveFields.stream().map(String::toLowerCase).collect(Collectors.toSet())
                : Set.of();
        this.maxBodyLength = maxBodyLength > 0 ? maxBodyLength : 4096;
    }

    public String redactAndTruncate(String rawBody) {
        if (rawBody == null || rawBody.isBlank()) {
            return null;
        }

        String sanitized;
        try {
            // Attempt to parse as JSON tree
            JsonNode rootNode = objectMapper.readTree(rawBody);
            redactNode(rootNode);
            sanitized = objectMapper.writeValueAsString(rootNode);
        } catch (Exception e) {
            // Non-JSON or malformed payload: fallback to safe masking or length limit
            log.debug("Body is not valid JSON; applying fallback length truncation");
            sanitized = rawBody;
        }

        if (sanitized.length() > maxBodyLength) {
            return sanitized.substring(0, maxBodyLength) + "... [truncated]";
        }
        return sanitized;
    }

    private void redactNode(JsonNode node) {
        if (node.isObject()) {
            ObjectNode objectNode = (ObjectNode) node;
            Iterator<Map.Entry<String, JsonNode>> fields = objectNode.fields();
            while (fields.hasNext()) {
                Map.Entry<String, JsonNode> field = fields.next();
                String fieldName = field.getKey();
                if (fieldName != null && sensitiveFieldsLower.contains(fieldName.toLowerCase())) {
                    field.setValue(new TextNode(REDACTED_VALUE));
                } else {
                    redactNode(field.getValue());
                }
            }
        } else if (node.isArray()) {
            ArrayNode arrayNode = (ArrayNode) node;
            for (JsonNode child : arrayNode) {
                redactNode(child);
            }
        }
    }
}
