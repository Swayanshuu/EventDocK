package dev.eventdock.starter;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.starter.capture.DiagnosticEventFactory;
import dev.eventdock.starter.capture.RequestMetadataCollector;
import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.filter.EventDockRequestFilter;
import dev.eventdock.starter.instrumentation.EventDockExceptionObserver;
import dev.eventdock.starter.reporting.EventDockReporter;
import dev.eventdock.starter.reporting.HttpEventDockReporter;
import dev.eventdock.starter.sanitize.SensitiveDataRedactor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;

/**
 * Spring Boot AutoConfiguration for EventDock developer diagnostics integration.
 */
@AutoConfiguration
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
@ConditionalOnProperty(prefix = "eventdock", name = "enabled", havingValue = "true", matchIfMissing = true)
@EnableConfigurationProperties(EventDockProperties.class)
public class EventDockAutoConfiguration {

    private static final Logger log = LoggerFactory.getLogger(EventDockAutoConfiguration.class);

    public EventDockAutoConfiguration(EventDockProperties properties) {
        log.info("EventDock diagnostic starter active for service '{}' [{}] (endpoint: {})",
                properties.getServiceName(), properties.getEnvironment(), properties.getEndpoint());
    }

    @Bean
    @ConditionalOnMissingBean
    public RequestMetadataCollector eventDockRequestMetadataCollector() {
        return new RequestMetadataCollector();
    }

    @Bean
    @ConditionalOnMissingBean
    public SensitiveDataRedactor eventDockSensitiveDataRedactor(EventDockProperties properties,
                                                                ObjectProvider<ObjectMapper> objectMapperProvider) {
        ObjectMapper mapper = objectMapperProvider.getIfAvailable(ObjectMapper::new);
        return new SensitiveDataRedactor(properties, HttpEventDockReporter.configureObjectMapper(mapper));
    }

    @Bean
    @ConditionalOnMissingBean
    public DiagnosticEventFactory eventDockDiagnosticEventFactory(EventDockProperties properties,
                                                                 RequestMetadataCollector metadataCollector,
                                                                 SensitiveDataRedactor redactor) {
        return new DiagnosticEventFactory(properties, metadataCollector, redactor);
    }

    @Bean(destroyMethod = "close")
    @ConditionalOnMissingBean
    public EventDockReporter eventDockReporter(EventDockProperties properties,
                                              ObjectProvider<ObjectMapper> objectMapperProvider) {
        ObjectMapper mapper = objectMapperProvider.getIfAvailable(ObjectMapper::new);
        return new HttpEventDockReporter(properties, mapper);
    }

    @Bean
    @ConditionalOnMissingBean
    public EventDockRequestFilter eventDockRequestFilter(EventDockProperties properties,
                                                        DiagnosticEventFactory eventFactory,
                                                        EventDockReporter reporter,
                                                        RequestMetadataCollector metadataCollector) {
        return new EventDockRequestFilter(properties, eventFactory, reporter, metadataCollector);
    }

    @Bean
    @ConditionalOnMissingBean
    public EventDockExceptionObserver eventDockExceptionObserver() {
        return new EventDockExceptionObserver();
    }
}
