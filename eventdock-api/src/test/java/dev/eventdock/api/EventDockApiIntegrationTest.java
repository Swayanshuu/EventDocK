package dev.eventdock.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.api.dto.ApiKeyResponse;
import dev.eventdock.api.dto.CreateApiKeyRequest;
import dev.eventdock.api.security.ApiKeyAuthenticationFilter;
import dev.eventdock.api.dto.IngestEventRequest;
import dev.eventdock.api.dto.CreateProjectRequest;
import dev.eventdock.api.dto.ProjectDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EventDockApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("Should return UP from Actuator health endpoint")
    void testActuatorHealth() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    @DisplayName("End-to-End: Authenticate with Firebase dev token, create project, generate API key, and ingest event")
    void testEndToEndFlow() throws Exception {
        String devToken = "dev_integration_user";

        // 1. Create Project
        CreateProjectRequest createProj = CreateProjectRequest.builder()
                .name("LinkPeer Staging")
                .description("LinkPeer staging environment")
                .retentionDays(30)
                .build();

        MvcResult projResult = mockMvc.perform(post("/api/v1/projects")
                        .header("Authorization", "Bearer " + devToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createProj)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("LinkPeer Staging"))
                .andReturn();

        String projJson = projResult.getResponse().getContentAsString();
        String projId = objectMapper.readTree(projJson).get("data").get("id").asText();

        // 2. Generate API Key
        CreateApiKeyRequest createKey = CreateApiKeyRequest.builder()
                .name("Staging Ingestion Key")
                .build();

        MvcResult keyResult = mockMvc.perform(post("/api/v1/projects/" + projId + "/keys")
                        .header("Authorization", "Bearer " + devToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createKey)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.rawKey").exists())
                .andReturn();

        String keyJson = keyResult.getResponse().getContentAsString();
        String rawApiKey = objectMapper.readTree(keyJson).get("data").get("rawKey").asText();
        assertThat(rawApiKey).startsWith("ed_live_");

        // 3. Ingest Diagnostic Event via API Key
        IngestEventRequest ingestReq = IngestEventRequest.builder()
                .requestId("corr-xyz-987")
                .httpMethod("POST")
                .requestUri("/posts")
                .routeTemplate("/posts")
                .statusCode(500)
                .errorType("java.sql.SQLException")
                .errorMessage("Database connection pool exhausted")
                .stackTrace("java.sql.SQLException: connection timeout\n\tat linkpeer.PostService.save")
                .durationMs(145L)
                .metadata(Map.of("User-Agent", "LinkPeerClient/1.0"))
                .build();

        mockMvc.perform(post("/api/v1/events")
                        .header(ApiKeyAuthenticationFilter.API_KEY_HEADER, rawApiKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(ingestReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("RECEIVED"));

        // 4. Query Events via Dashboard/CLI token
        mockMvc.perform(get("/api/v1/projects/" + projId + "/events")
                        .header("Authorization", "Bearer " + devToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].statusCode").value(500))
                .andExpect(jsonPath("$.data.content[0].requestId").value("corr-xyz-987"));
    }
}
