package dev.eventdock.cli.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.cli.config.CliConfig;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class EventDockApiClient {

    private final CliConfig config;
    private final HttpClient httpClient;
    private final ObjectMapper mapper;

    public EventDockApiClient(CliConfig config) {
        this.config = config != null ? config : CliConfig.load();
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        this.mapper = new ObjectMapper();
    }

    public JsonNode getProfile() throws Exception {
        return sendGet("/api/v1/auth/me");
    }

    public JsonNode listProjects() throws Exception {
        return sendGet("/api/v1/projects");
    }

    public JsonNode listEvents(String projectId, Integer statusCode, int page, int size) throws Exception {
        StringBuilder url = new StringBuilder("/api/v1/projects/" + projectId + "/events?page=" + page + "&size=" + size);
        if (statusCode != null) {
            url.append("&statusCode=").append(statusCode);
        }
        return sendGet(url.toString());
    }

    public JsonNode getEventDetail(String eventId) throws Exception {
        return sendGet("/api/v1/events/" + eventId);
    }

    public JsonNode executeReplay(String eventId, String targetUrl, boolean confirm) throws Exception {
        String body = String.format("""
                {
                    "destinationUrl": "%s",
                    "confirmUnsafeMethod": %b
                }
                """, targetUrl, confirm);

        return sendPost("/api/v1/events/" + eventId + "/replays", body);
    }

    private JsonNode sendGet(String path) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(config.getApiUrl() + path))
                .timeout(Duration.ofSeconds(10))
                .header("Accept", "application/json");

        if (config.getToken() != null && !config.getToken().isBlank()) {
            builder.header("Authorization", "Bearer " + config.getToken());
        }

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 400) {
            throw new RuntimeException("API returned HTTP " + response.statusCode() + ": " + response.body());
        }
        return mapper.readTree(response.body());
    }

    private JsonNode sendPost(String path, String jsonBody) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(config.getApiUrl() + path))
                .timeout(Duration.ofSeconds(10))
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody));

        if (config.getToken() != null && !config.getToken().isBlank()) {
            builder.header("Authorization", "Bearer " + config.getToken());
        }

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 400) {
            throw new RuntimeException("API returned HTTP " + response.statusCode() + ": " + response.body());
        }
        return mapper.readTree(response.body());
    }
}
