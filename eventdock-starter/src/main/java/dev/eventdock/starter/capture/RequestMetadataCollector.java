package dev.eventdock.starter.capture;

import dev.eventdock.starter.model.RequestMetadata;
import jakarta.servlet.http.HttpServletRequest;

import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

/**
 * Extracts safe request attributes, headers, and parameters from Jakarta HttpServletRequest.
 */
public class RequestMetadataCollector {

    public static final String CORRELATION_ID_HEADER = "X-Request-Id";
    public static final String ALT_CORRELATION_ID_HEADER = "X-Correlation-Id";
    public static final String CORRELATION_ID_ATTR = "dev.eventdock.correlationId";

    public RequestMetadata collect(HttpServletRequest request) {
        if (request == null) {
            return new RequestMetadata();
        }

        Map<String, String> headers = new HashMap<>();
        Enumeration<String> headerNames = request.getHeaderNames();
        if (headerNames != null) {
            while (headerNames.hasMoreElements()) {
                String headerName = headerNames.nextElement();
                headers.put(headerName, request.getHeader(headerName));
            }
        }

        Map<String, String> queryParams = new HashMap<>();
        Map<String, String[]> parameterMap = request.getParameterMap();
        if (parameterMap != null) {
            for (Map.Entry<String, String[]> entry : parameterMap.entrySet()) {
                if (entry.getValue() != null && entry.getValue().length > 0) {
                    queryParams.put(entry.getKey(), String.join(",", entry.getValue()));
                }
            }
        }

        String clientIp = extractClientIp(request);
        String contentType = request.getContentType();
        String userAgent = request.getHeader("User-Agent");
        long contentLength = request.getContentLengthLong();

        return new RequestMetadata(
                headers,
                queryParams,
                clientIp,
                contentType,
                userAgent,
                contentLength >= 0 ? contentLength : null
        );
    }

    public String resolveOrGenerateCorrelationId(HttpServletRequest request) {
        if (request == null) {
            return java.util.UUID.randomUUID().toString();
        }

        Object existingAttr = request.getAttribute(CORRELATION_ID_ATTR);
        if (existingAttr != null) {
            return existingAttr.toString();
        }

        String headerId = request.getHeader(CORRELATION_ID_HEADER);
        if (headerId == null || headerId.isBlank()) {
            headerId = request.getHeader(ALT_CORRELATION_ID_HEADER);
        }

        if (headerId == null || headerId.isBlank()) {
            headerId = java.util.UUID.randomUUID().toString();
        }

        request.setAttribute(CORRELATION_ID_ATTR, headerId);
        return headerId;
    }

    private String extractClientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            // First IP in list is client
            int commaIdx = xff.indexOf(',');
            return commaIdx > 0 ? xff.substring(0, commaIdx).trim() : xff.trim();
        }
        return request.getRemoteAddr();
    }
}
