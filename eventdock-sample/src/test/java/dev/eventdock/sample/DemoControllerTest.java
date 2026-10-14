package dev.eventdock.sample;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.sample.dto.PostRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class DemoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("GET /demo/success should return HTTP 200 with correlation ID header")
    void testSuccessEndpoint() throws Exception {
        mockMvc.perform(get("/demo/success"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.status").value("ok"));
    }

    @Test
    @DisplayName("GET /demo/fail should return HTTP 500 without crashing even if EventDock backend is offline")
    void testFailEndpointWithGracefulDegradation() throws Exception {
        mockMvc.perform(get("/demo/fail"))
                .andExpect(status().isInternalServerError())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.error").value("Database Error"))
                .andExpect(jsonPath("$.message").value("PostgreSQL connection timeout during query execution on table 'posts'"));
    }

    @Test
    @DisplayName("GET /demo/bad-request should return HTTP 400")
    void testBadRequestEndpoint() throws Exception {
        mockMvc.perform(get("/demo/bad-request"))
                .andExpect(status().isBadRequest())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.error").value("Bad Request"));
    }

    @Test
    @DisplayName("GET /demo/not-found should return HTTP 404")
    void testNotFoundEndpoint() throws Exception {
        mockMvc.perform(get("/demo/not-found"))
                .andExpect(status().isNotFound())
                .andExpect(header().exists("X-Request-Id"));
    }

    @Test
    @DisplayName("POST /demo/posts should create post or trigger 500 when simulated database failure is active")
    void testCreatePostEndpoint() throws Exception {
        // Valid post creation
        PostRequest validPost = PostRequest.builder()
                .title("Hello LinkPeer World")
                .content("Excited to share our developer update!")
                .simulateDbFailure(false)
                .build();

        mockMvc.perform(post("/demo/posts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validPost)))
                .andExpect(status().isCreated())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.status").value("PUBLISHED"));

        // Simulated failure post
        PostRequest failingPost = PostRequest.builder()
                .title("Failing post")
                .simulateDbFailure(true)
                .build();

        mockMvc.perform(post("/demo/posts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(failingPost)))
                .andExpect(status().isInternalServerError())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.error").value("Database Error"));
    }
}
