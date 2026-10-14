package dev.eventdock.cli.command;

import com.fasterxml.jackson.databind.JsonNode;
import dev.eventdock.cli.client.EventDockApiClient;
import dev.eventdock.cli.config.CliConfig;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.util.concurrent.Callable;

@Command(name = "replay", description = "Replay a failed request against a local or staging target URL")
public class ReplayCommand implements Callable<Integer> {

    @Parameters(index = "0", description = "Event UUID to replay")
    private String eventId;

    @Option(names = {"--target", "-t"}, description = "Destination target URL (e.g. http://localhost:8081)", required = true)
    private String targetUrl;

    @Option(names = {"--confirm", "-y"}, description = "Acknowledge and confirm replaying potentially state-changing methods (POST/PUT/DELETE)")
    private boolean confirm;

    @Override
    public Integer call() {
        CliConfig config = CliConfig.load();
        if (config.getToken() == null || config.getToken().isBlank()) {
            System.err.println("Error: Not authenticated. Please run 'eventdock login' first.");
            return 1;
        }

        System.out.println("Dispatching replay request for event " + eventId + " to destination " + targetUrl + "...");

        try {
            EventDockApiClient client = new EventDockApiClient(config);
            JsonNode response = client.executeReplay(eventId, targetUrl, confirm);
            JsonNode r = response.path("data");

            System.out.println("=".repeat(75));
            System.out.println(" REPLAY ATTEMPT SUMMARY");
            System.out.println("=".repeat(75));
            System.out.println("Replay ID:       " + r.path("id").asText());
            System.out.println("Destination:     " + r.path("destinationUrl").asText());
            System.out.println("Outcome:         " + r.path("outcome").asText());
            System.out.println("HTTP Status:     " + r.path("responseStatus").asText("N/A"));
            System.out.println("Duration:        " + r.path("durationMs").asLong() + " ms");
            if (!r.path("safeErrorSummary").isNull() && !r.path("safeErrorSummary").asText().isBlank()) {
                System.out.println("Error Summary:   " + r.path("safeErrorSummary").asText());
            }
            if (!r.path("responseSnippet").isNull() && !r.path("responseSnippet").asText().isBlank()) {
                System.out.println("Response Snippet:");
                System.out.println(r.path("responseSnippet").asText());
            }
            System.out.println("=".repeat(75));
            return 0;
        } catch (Exception e) {
            System.err.println("Replay execution failed: " + e.getMessage());
            return 1;
        }
    }
}
