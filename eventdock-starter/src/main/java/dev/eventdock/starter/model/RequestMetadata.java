package dev.eventdock.starter.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

/**
 * Encapsulates safe, non-sensitive request metadata captured during an observed API request.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RequestMetadata implements Serializable {

    private static final long serialVersionUID = 1L;

    @Builder.Default
    private Map<String, String> headers = new HashMap<>();

    @Builder.Default
    private Map<String, String> queryParams = new HashMap<>();

    private String clientIp;
    private String contentType;
    private String userAgent;
    private Long contentLength;
}
