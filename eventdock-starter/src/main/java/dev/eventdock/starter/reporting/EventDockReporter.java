package dev.eventdock.starter.reporting;

import dev.eventdock.starter.model.DiagnosticEvent;

/**
 * Contract for submitting diagnostic events to the EventDock platform.
 */
public interface EventDockReporter extends AutoCloseable {

    /**
     * Submit a diagnostic event for reporting.
     *
     * @param event the sanitized diagnostic event
     */
    void report(DiagnosticEvent event);

    @Override
    default void close() {
    }
}
