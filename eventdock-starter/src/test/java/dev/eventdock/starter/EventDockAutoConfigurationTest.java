package dev.eventdock.starter;

import dev.eventdock.starter.capture.DiagnosticEventFactory;
import dev.eventdock.starter.capture.RequestMetadataCollector;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.filter.EventDockRequestFilter;
import dev.eventdock.starter.instrumentation.EventDockExceptionObserver;
import dev.eventdock.starter.reporting.EventDockReporter;
import dev.eventdock.starter.sanitize.SensitiveDataRedactor;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.test.context.runner.WebApplicationContextRunner;

import static org.assertj.core.api.Assertions.assertThat;

class EventDockAutoConfigurationTest {

    private final WebApplicationContextRunner contextRunner = new WebApplicationContextRunner()
            .withConfiguration(AutoConfigurations.of(EventDockAutoConfiguration.class));

    @Test
    @DisplayName("Should load all EventDock starter beans when enabled")
    void testAutoConfigurationLoadsBeans() {
        contextRunner
                .withPropertyValues(
                        "eventdock.enabled=true",
                        "eventdock.api-key=ed_live_test_key_123",
                        "eventdock.service-name=TestApp"
                )
                .run(context -> {
                    assertThat(context).hasSingleBean(EventDockProperties.class);
                    assertThat(context).hasSingleBean(RequestMetadataCollector.class);
                    assertThat(context).hasSingleBean(SensitiveDataRedactor.class);
                    assertThat(context).hasSingleBean(DiagnosticEventFactory.class);
                    assertThat(context).hasSingleBean(EventDockReporter.class);
                    assertThat(context).hasSingleBean(EventDockRequestFilter.class);
                    assertThat(context).hasSingleBean(EventDockExceptionObserver.class);
                });
    }

    @Test
    @DisplayName("Should back off when eventdock.enabled is false")
    void testAutoConfigurationBacksOffWhenDisabled() {
        contextRunner
                .withPropertyValues("eventdock.enabled=false")
                .run(context -> {
                    assertThat(context).doesNotHaveBean(EventDockRequestFilter.class);
                    assertThat(context).doesNotHaveBean(EventDockReporter.class);
                });
    }
}
