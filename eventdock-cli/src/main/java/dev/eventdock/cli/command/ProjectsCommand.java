package dev.eventdock.cli.command;

import com.fasterxml.jackson.databind.JsonNode;
import dev.eventdock.cli.client.EventDockApiClient;
import dev.eventdock.cli.config.CliConfig;
import picocli.CommandLine.Command;

import java.util.concurrent.Callable;

@Command(name = "projects", description = "List registered EventDock projects")
public class ProjectsCommand implements Callable<Integer> {

    @Override
    public Integer call() {
        CliConfig config = CliConfig.load();
        if (config.getToken() == null || config.getToken().isBlank()) {
            System.err.println("Error: Not authenticated. Please run 'eventdock login' first.");
            return 1;
        }

        try {
            EventDockApiClient client = new EventDockApiClient(config);
            JsonNode response = client.listProjects();
            JsonNode projects = response.path("data");

            if (!projects.isArray() || projects.isEmpty()) {
                System.out.println("No projects found. Create one through the EventDock dashboard or API.");
                return 0;
            }

            System.out.printf("%-38s %-25s %-25s %s%n", "PROJECT ID", "NAME", "SLUG", "RETENTION");
            System.out.println("-".repeat(105));
            for (JsonNode p : projects) {
                System.out.printf("%-38s %-25s %-25s %d days%n",
                        p.path("id").asText(),
                        p.path("name").asText(),
                        p.path("slug").asText(),
                        p.path("retentionDays").asInt());
            }
            return 0;
        } catch (Exception e) {
            System.err.println("Failed to retrieve projects: " + e.getMessage());
            return 1;
        }
    }
}
