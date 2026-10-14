package dev.eventdock.starter.filter;

import dev.eventdock.starter.capture.DiagnosticEventFactory;
import dev.eventdock.starter.capture.RequestMetadataCollector;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.instrumentation.EventDockExceptionObserver;
import dev.eventdock.starter.model.DiagnosticEvent;
import dev.eventdock.starter.reporting.EventDockReporter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Servlet filter that wraps HTTP request lifecycle, propagates correlation IDs,
 * detects configured API failures, and submits sanitized diagnostic events to EventDock.
 */
public class EventDockRequestFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(EventDockRequestFilter.class);
    public static final String REPORTED_ATTR = "dev.eventdock.reported";

    private final EventDockProperties properties;
    private final DiagnosticEventFactory eventFactory;
    private final EventDockReporter reporter;
    private final RequestMetadataCollector metadataCollector;
    private final AntPathMatcher pathMatcher = new AntPathMatcher();

    public EventDockRequestFilter(EventDockProperties properties,
                                  DiagnosticEventFactory eventFactory,
                                  EventDockReporter reporter,
                                  RequestMetadataCollector metadataCollector) {
        this.properties = properties;
        this.eventFactory = eventFactory;
        this.reporter = reporter;
        this.metadataCollector = metadataCollector;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (!properties.isEnabled() || isPathExcluded(request.getRequestURI())) {
            filterChain.doFilter(request, response);
            return;
        }

        long startTime = System.currentTimeMillis();
        String correlationId = metadataCollector.resolveOrGenerateCorrelationId(request);

        // Propagate correlation ID in outgoing response headers
        if (response.getHeader(RequestMetadataCollector.CORRELATION_ID_HEADER) == null) {
            response.setHeader(RequestMetadataCollector.CORRELATION_ID_HEADER, correlationId);
        }

        Throwable unhandledException = null;
        try {
            filterChain.doFilter(request, response);
        } catch (Throwable t) {
            unhandledException = t;
            throw t;
        } finally {
            long durationMs = System.currentTimeMillis() - startTime;
            processFailureObservation(request, response, durationMs, unhandledException);
        }
    }

    private void processFailureObservation(HttpServletRequest request,
                                           HttpServletResponse response,
                                           long durationMs,
                                           Throwable unhandledException) {
        // Enforce strict deduplication: exactly one diagnostic event per request
        if (Boolean.TRUE.equals(request.getAttribute(REPORTED_ATTR))) {
            return;
        }

        int statusCode = response.getStatus();
        if (unhandledException != null && statusCode < 400) {
            statusCode = HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
        }

        Throwable capturedException = unhandledException;
        if (capturedException == null) {
            Object attrEx = request.getAttribute(EventDockExceptionObserver.EXCEPTION_ATTR);
            if (attrEx instanceof Throwable t) {
                capturedException = t;
            }
        }

        boolean isFailure = shouldCapture(statusCode, capturedException);
        if (isFailure) {
            request.setAttribute(REPORTED_ATTR, Boolean.TRUE);

            try {
                DiagnosticEvent event = eventFactory.createEvent(
                        request,
                        statusCode,
                        durationMs,
                        capturedException,
                        null,
                        null
                );

                reporter.report(event);
            } catch (Exception e) {
                log.debug("Failed to record EventDock diagnostic event for request [{}]: {}",
                        request.getAttribute(RequestMetadataCollector.CORRELATION_ID_ATTR), e.getMessage());
            }
        }
    }

    private boolean shouldCapture(int statusCode, Throwable exception) {
        if (exception != null) {
            return true;
        }

        if (statusCode < properties.getMinStatusCode()) {
            return false;
        }

        if (statusCode >= 400 && statusCode < 500 && !properties.isCaptureClientErrors()) {
            return false;
        }

        if (statusCode >= 500 && !properties.isCaptureServerErrors()) {
            return false;
        }

        return statusCode >= 400;
    }

    private boolean isPathExcluded(String uri) {
        if (uri == null || properties.getExcludedPaths() == null) {
            return false;
        }
        for (String pattern : properties.getExcludedPaths()) {
            if (pathMatcher.match(pattern, uri)) {
                return true;
            }
        }
        return false;
    }
}
