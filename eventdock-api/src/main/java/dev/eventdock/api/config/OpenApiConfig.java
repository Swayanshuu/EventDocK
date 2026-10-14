package dev.eventdock.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI eventDockOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("EventDock Platform API")
                        .version("1.0.0")
                        .description("REST API for EventDock developer platform to detect, inspect, and reproduce API failures")
                        .contact(new Contact().name("EventDock Team").url("https://eventdock.dev"))
                        .license(new License().name("Apache 2.0").url("https://www.apache.org/licenses/LICENSE-2.0")))
                .servers(java.util.List.of(
                        new io.swagger.v3.oas.models.servers.Server().url("http://localhost:8080").description("Local Development Server"),
                        new io.swagger.v3.oas.models.servers.Server().url("https://api.eventdock.swynx.dev").description("Production Gateway")
                ))
                .addSecurityItem(new SecurityRequirement().addList("FirebaseAuth"))
                .addSecurityItem(new SecurityRequirement().addList("ApiKeyAuth"))
                .components(new Components()
                        .addSecuritySchemes("FirebaseAuth", new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Firebase Auth ID token (Bearer <token>)"))
                        .addSecuritySchemes("ApiKeyAuth", new SecurityScheme()
                                .type(SecurityScheme.Type.APIKEY)
                                .in(SecurityScheme.In.HEADER)
                                .name("X-EventDock-Api-Key")
                                .description("Project SDK Ingestion API Key (ed_live_...)")));
    }
}
