package dev.eventdock.cli.command;

import com.fasterxml.jackson.databind.JsonNode;
import dev.eventdock.cli.client.EventDockApiClient;
import dev.eventdock.cli.config.CliConfig;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.util.concurrent.Callable;

@Command(name = "events", description = "Browse, query, and inspect diagnostic failure events",
        subcommands = {EventsCommand.InspectSubcommand.class})
public class EventsCommand implements Callable<Integer> {

    @Option(names = {"--project", "-p"}, description = "Project UUID", required = true)
    private String projectId;

    @Option(names = {"--status", "-s"}, description = "Filter by HTTP status code (e.g. 500)")
    private Integer statusCode;

    @Option(names = {"--limit", "-l"}, description = "Number of events to display", defaultValue = "15")
    private int limit;

    @Override
    public Integer call() {
        CliConfig config = CliConfig.load();
        if (config.getToken() == null || config.getToken().isBlank()) {
            System.err.println("Error: Not authenticated. Please run 'eventdock login' first.");
            return 1;
        }

        try {
            EventDockApiClient client = new EventDockApiClient(config);
            JsonNode response = client.listEvents(projectId, statusCode, 0, limit);
            JsonNode events = response.path("data").path("content");

            if (!events.isArray() || events.isEmpty()) {
                System.out.println("No diagnostic failure events found matching criteria for project " + projectId);
                return 0;
            }

            System.out.printf("%-38s %-6s %-7s %-25s %-30s %s%n",
                    "EVENT ID", "STATUS", "METHOD", "ROUTE", "ERROR TYPE", "OCCURRED AT");
            System.out.println("-".repeat(125));

            for (JsonNode ev : events) {
                System.out.printf("%-38s %-6d %-7s %-25s %-30s %s%n",
                        ev.path("id").asText(),
                        ev.path("statusCode").asInt(),
                        ev.path("httpMethod").asText(),
                        truncate(ev.path("requestUri").asText(), 24),
                        truncate(ev.path("errorType").asText("N/A"), 29),
                        ev.path("occurredAt").asText());
            }
            return 0;
        } catch (Exception e) {
            System.err.println("Failed to fetch events: " + e.getMessage());
            return 1;
        }
    }

    private String truncate(String text, int max) {
        if (text == null) return "";
        return text.length() <= max ? text : text.substring(0, max - 3) + "...";
    }

    @Command(name = "inspect", description = "Inspect complete diagnostic event details and stack trace")
    public static class InspectSubcommand implements Callable<Integer> {

        @Parameters(index = "0", description = "Event UUID to inspect")
        private String eventId;

        @Override
        public Integer call() {
            CliConfig config = CliConfig.load();
            if (config.getToken() == null || config.getToken().isBlank()) {
                System.err.println("Error: Not authenticated. Please run 'eventdock login' first.");
                return 1;
            }

            try {
                EventDockApiClient client = new EventDockApiClient(config);
                JsonNode response = client.getEventDetail(eventId);
                JsonNode d = response.path("data");

                System.out.println("=".repeat(80));
                System.out.println(" EVENT DIAGNOSTIC REPORT: " + d.path("id").asText());
                System.out.println("=".repeat(80));
                System.out.println("Request ID:      " + d.path("requestId").asText());
                System.out.println("HTTP Method:     " + d.path("httpMethod").asText());
                System.out.println("Request URI:     " + d.path("requestUri").asText());
                System.out.println("Status Code:     " + d.path("statusCode").asInt());
                System.out.println("Duration:        " + d.path("durationMs").asLong() + " ms");
                System.out.println("Service:         " + d.path("serviceName").asText() + " (" + d.path("environment").asText() + ")");
                System.out.println("Occurred At:     " + d.path("occurredAt").asText());
                System.out.println("-".repeat(80));
                System.out.println("Error Type:      " + d.path("errorType").asText());
                System.out.println("Error Message:   " + d.path("sanitizedErrorMessage").asText());
                System.out.println("-".repeat(80));
                System.out.println("SANITIZED STACK TRACE:");
                String stackTrace = d.path("stackTrace").asText("(No stack trace available)");
                System.out.println(stackTrace);
                System.out.println("-".repeat(80));
                if (!d.path("metadataJson").isMissingNode()) {
                    System.out.println("METADATA & HEADERS:");
                    System.out.println(d.path("metadataJson").asText("{}"));
                }
                return 0;
            } catch (Exception e) {
                System.err.println("Failed to inspect event: " + e.getMessage());
                return 1;
            }
        }
    }
}
