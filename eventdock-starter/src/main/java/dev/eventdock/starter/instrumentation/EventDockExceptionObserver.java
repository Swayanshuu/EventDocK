package dev.eventdock.starter.instrumentation;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.web.servlet.HandlerExceptionResolver;
import org.springframework.web.servlet.ModelAndView;

/**
 * Spring MVC HandlerExceptionResolver that records exceptions in request attributes
 * so that EventDock can capture stack traces and error details even when exceptions
 * are subsequently handled by @ExceptionHandler, Spring ErrorController, or custom error views.
 */
public class EventDockExceptionObserver implements HandlerExceptionResolver, Ordered {

    public static final String EXCEPTION_ATTR = "dev.eventdock.exception";

    @Override
    public int getOrder() {
        // Run with highest precedence to observe the exception before other resolvers handle it
        return Ordered.HIGHEST_PRECEDENCE;
    }

    @Override
    public ModelAndView resolveException(HttpServletRequest request,
                                         HttpServletResponse response,
                                         Object handler,
                                         Exception ex) {
        if (request != null && ex != null) {
            // Store exception in request attribute without consuming or altering the exception
            request.setAttribute(EXCEPTION_ATTR, ex);
        }
        // Return null to allow subsequent resolvers (@ExceptionHandler, DefaultHandlerExceptionResolver)
        // to process the exception normally.
        return null;
    }
}
