package dev.eventdock.starter.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.starter.capture.DiagnosticEventFactory;
import dev.eventdock.starter.capture.RequestMetadataCollector;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.instrumentation.EventDockExceptionObserver;
import dev.eventdock.starter.model.DiagnosticEvent;
import dev.eventdock.starter.reporting.EventDockReporter;
import dev.eventdock.starter.sanitize.SensitiveDataRedactor;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class EventDockRequestFilterTest {

    private EventDockProperties properties;
    private RequestMetadataCollector metadataCollector;
    private SensitiveDataRedactor redactor;
    private DiagnosticEventFactory eventFactory;
    private List<DiagnosticEvent> reportedEvents;
    private EventDockReporter testReporter;
    private EventDockRequestFilter filter;

    @BeforeEach
    void setUp() {
        properties = new EventDockProperties();
        properties.setMinStatusCode(400);
        properties.setCaptureClientErrors(true);
        properties.setCaptureServerErrors(true);

        metadataCollector = new RequestMetadataCollector();
        redactor = new SensitiveDataRedactor(properties, new ObjectMapper());
        eventFactory = new DiagnosticEventFactory(properties, metadataCollector, redactor);
        reportedEvents = new ArrayList<>();
        testReporter = reportedEvents::add;

        filter = new EventDockRequestFilter(properties, eventFactory, testReporter, metadataCollector);
    }

    @Test
    @DisplayName("Should report event when response status is HTTP 500")
    void testCaptures500Error() throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/posts");
        MockHttpServletResponse response = new MockHttpServletResponse();

        FilterChain chain = (req, res) -> {
            ((MockHttpServletResponse) res).setStatus(500);
        };

        filter.doFilter(request, response, chain);

        assertThat(response.getHeader(RequestMetadataCollector.CORRELATION_ID_HEADER)).isNotNull();
        assertThat(reportedEvents).hasSize(1);

        DiagnosticEvent event = reportedEvents.get(0);
        assertThat(event.getStatusCode()).isEqualTo(500);
        assertThat(event.getHttpMethod()).isEqualTo("POST");
        assertThat(event.getRequestUri()).isEqualTo("/posts");
        assertThat(event.getRequestId()).isEqualTo(response.getHeader(RequestMetadataCollector.CORRELATION_ID_HEADER));
    }

    @Test
    @DisplayName("Should capture exception recorded by EventDockExceptionObserver")
    void testCapturesExceptionFromAttribute() throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/demo/fail");
        MockHttpServletResponse response = new MockHttpServletResponse();

        Exception simulatedEx = new IllegalStateException("Database connection pool exhausted");

        FilterChain chain = (req, res) -> {
            req.setAttribute(EventDockExceptionObserver.EXCEPTION_ATTR, simulatedEx);
            ((MockHttpServletResponse) res).setStatus(500);
        };

        filter.doFilter(request, response, chain);

        assertThat(reportedEvents).hasSize(1);
        DiagnosticEvent event = reportedEvents.get(0);
        assertThat(event.getErrorType()).isEqualTo(IllegalStateException.class.getName());
        assertThat(event.getErrorMessage()).contains("Database connection pool exhausted");
        assertThat(event.getStackTrace()).contains("IllegalStateException");
    }

    @Test
    @DisplayName("Should not report when request is successful (HTTP 200)")
    void testIgnoresSuccessfulRequest() throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/posts/123");
        MockHttpServletResponse response = new MockHttpServletResponse();

        FilterChain chain = (req, res) -> {
            ((MockHttpServletResponse) res).setStatus(200);
        };

        filter.doFilter(request, response, chain);

        assertThat(reportedEvents).isEmpty();
        assertThat(response.getHeader(RequestMetadataCollector.CORRELATION_ID_HEADER)).isNotNull();
    }

    @Test
    @DisplayName("Should skip observation for excluded paths like /actuator")
    void testSkipsExcludedPaths() throws ServletException, IOException {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/actuator/health");
        MockHttpServletResponse response = new MockHttpServletResponse();

        FilterChain chain = (req, res) -> {
            ((MockHttpServletResponse) res).setStatus(503);
        };

        filter.doFilter(request, response, chain);

        assertThat(reportedEvents).isEmpty();
    }
}
