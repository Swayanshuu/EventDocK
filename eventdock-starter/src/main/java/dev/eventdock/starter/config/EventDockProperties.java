package dev.eventdock.starter.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.HashSet;
import java.util.Set;

/**
 * Configuration properties for the EventDock Spring Boot Starter.
 */
@ConfigurationProperties(prefix = "eventdock")
public class EventDockProperties {

    /**
     * Master switch to enable or disable EventDock diagnostic capture.
     */
    private boolean enabled = true;

    /**
     * Base URL of the EventDock API service (e.g. http://localhost:8080).
     */
    private String endpoint = "https://api.eventdock.swynx.dev";

    /**
     * Project ingestion API key (e.g. ed_live_...).
     */
    private String apiKey;

    /**
     * Logical application/service name (e.g. LinkPeer).
     */
    private String serviceName = "application";

    /**
     * Deployment environment (e.g. development, staging, production).
     */
    private String environment = "development";

    /**
     * Minimum HTTP status code threshold to trigger diagnostic event capture.
     * Default is 400.
     */
    private int minStatusCode = 400;

    /**
     * Capture 4xx client error status codes.
     */
    private boolean captureClientErrors = true;

    /**
     * Capture 5xx server error status codes.
     */
    private boolean captureServerErrors = true;

    /**
     * Paths to exclude from observation (e.g. actuator health checks).
     */
    private Set<String> excludedPaths = new HashSet<>(Set.of(
            "/actuator",
            "/actuator/**",
            "/favicon.ico",
            "/error"));

    private CaptureProperties capture = new CaptureProperties();
    private RedactionProperties redaction = new RedactionProperties();
    private QueueProperties queue = new QueueProperties();
    private NetworkProperties network = new NetworkProperties();

    public static class CaptureProperties {
        /**
         * Capture HTTP request and response bodies. False by default for privacy and
         * security.
         */
        private boolean bodyEnabled = false;

        /**
         * Maximum body length in characters to retain when body capture is enabled.
         */
        private int maxBodyLength = 4096;

        /**
         * Maximum stack trace lines/frames to preserve.
         */
        private int maxStackTraceFrames = 50;

        public boolean isBodyEnabled() {
            return bodyEnabled;
        }

        public void setBodyEnabled(boolean bodyEnabled) {
            this.bodyEnabled = bodyEnabled;
        }

        public int getMaxBodyLength() {
            return maxBodyLength;
        }

        public void setMaxBodyLength(int maxBodyLength) {
            this.maxBodyLength = maxBodyLength;
        }

        public int getMaxStackTraceFrames() {
            return maxStackTraceFrames;
        }

        public void setMaxStackTraceFrames(int maxStackTraceFrames) {
            this.maxStackTraceFrames = maxStackTraceFrames;
        }
    }

    public static class RedactionProperties {
        /**
         * Header names (case-insensitive) to redact with ***REDACTED***.
         */
        private Set<String> headers = new HashSet<>(Set.of(
                "authorization",
                "proxy-authorization",
                "cookie",
                "set-cookie",
                "x-api-key",
                "x-auth-token",
                "x-eventdock-api-key"));

        /**
         * Sensitive JSON keys to redact when body capture is enabled.
         */
        private Set<String> bodyFields = new HashSet<>(Set.of(
                "password",
                "secret",
                "token",
                "accessToken",
                "refreshToken",
                "apiKey",
                "cardNumber",
                "cvv",
                "ssn",
                "privateKey"));

        public Set<String> getHeaders() {
            return headers;
        }

        public void setHeaders(Set<String> headers) {
            this.headers = headers;
        }

        public Set<String> getBodyFields() {
            return bodyFields;
        }

        public void setBodyFields(Set<String> bodyFields) {
            this.bodyFields = bodyFields;
        }
    }

    public static class QueueProperties {
        /**
         * Maximum bounded capacity of the asynchronous reporting queue.
         */
        private int capacity = 500;

        /**
         * Batch size for dispatching queued events.
         */
        private int batchSize = 25;

        /**
         * Interval in milliseconds for polling and flushing queued events.
         */
        private long flushIntervalMs = 1000;

        public int getCapacity() {
            return capacity;
        }

        public void setCapacity(int capacity) {
            this.capacity = capacity;
        }

        public int getBatchSize() {
            return batchSize;
        }

        public void setBatchSize(int batchSize) {
            this.batchSize = batchSize;
        }

        public long getFlushIntervalMs() {
            return flushIntervalMs;
        }

        public void setFlushIntervalMs(long flushIntervalMs) {
            this.flushIntervalMs = flushIntervalMs;
        }
    }

    public static class NetworkProperties {
        /**
         * Connection timeout in milliseconds.
         */
        private int connectTimeoutMs = 2000;

        /**
         * Read timeout in milliseconds.
         */
        private int readTimeoutMs = 3000;

        public int getConnectTimeoutMs() {
            return connectTimeoutMs;
        }

        public void setConnectTimeoutMs(int connectTimeoutMs) {
            this.connectTimeoutMs = connectTimeoutMs;
        }

        public int getReadTimeoutMs() {
            return readTimeoutMs;
        }

        public void setReadTimeoutMs(int readTimeoutMs) {
            this.readTimeoutMs = readTimeoutMs;
        }
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getEndpoint() {
        return endpoint;
    }

    public void setEndpoint(String endpoint) {
        this.endpoint = endpoint;
    }

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String getServiceName() {
        return serviceName;
    }

    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }

    public String getEnvironment() {
        return environment;
    }

    public void setEnvironment(String environment) {
        this.environment = environment;
    }

    public int getMinStatusCode() {
        return minStatusCode;
    }

    public void setMinStatusCode(int minStatusCode) {
        this.minStatusCode = minStatusCode;
    }

    public boolean isCaptureClientErrors() {
        return captureClientErrors;
    }

    public void setCaptureClientErrors(boolean captureClientErrors) {
        this.captureClientErrors = captureClientErrors;
    }

    public boolean isCaptureServerErrors() {
        return captureServerErrors;
    }

    public void setCaptureServerErrors(boolean captureServerErrors) {
        this.captureServerErrors = captureServerErrors;
    }

    public Set<String> getExcludedPaths() {
        return excludedPaths;
    }

    public void setExcludedPaths(Set<String> excludedPaths) {
        this.excludedPaths = excludedPaths;
    }

    public CaptureProperties getCapture() {
        return capture;
    }

    public void setCapture(CaptureProperties capture) {
        this.capture = capture;
    }

    public RedactionProperties getRedaction() {
        return redaction;
    }

    public void setRedaction(RedactionProperties redaction) {
        this.redaction = redaction;
    }

    public QueueProperties getQueue() {
        return queue;
    }

    public void setQueue(QueueProperties queue) {
        this.queue = queue;
    }

    public NetworkProperties getNetwork() {
        return network;
    }

    public void setNetwork(NetworkProperties network) {
        this.network = network;
    }
}
