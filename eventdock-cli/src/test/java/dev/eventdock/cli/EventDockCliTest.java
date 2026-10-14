package dev.eventdock.cli;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import picocli.CommandLine;

import java.io.PrintWriter;
import java.io.StringWriter;

import static org.assertj.core.api.Assertions.assertThat;

class EventDockCliTest {

    @Test
    @DisplayName("Should display CLI help and exit with code 0")
    void testCliHelp() {
        EventDockCliApplication app = new EventDockCliApplication();
        CommandLine cmd = new CommandLine(app);

        StringWriter sw = new StringWriter();
        cmd.setOut(new PrintWriter(sw));

        int exitCode = cmd.execute("--help");

        assertThat(exitCode).isEqualTo(0);
        assertThat(sw.toString())
                .contains("eventdock")
                .contains("login")
                .contains("projects")
                .contains("events")
                .contains("replay")
                .contains("config");
    }

    @Test
    @DisplayName("Should display configuration status on 'config show'")
    void testConfigShow() {
        EventDockCliApplication app = new EventDockCliApplication();
        CommandLine cmd = new CommandLine(app);

        StringWriter sw = new StringWriter();
        cmd.setOut(new PrintWriter(sw));

        int exitCode = cmd.execute("config", "show");

        assertThat(exitCode).isEqualTo(0);
    }

    @Test
    @DisplayName("Should fail when required options are missing on 'events'")
    void testEventsMissingRequiredProject() {
        EventDockCliApplication app = new EventDockCliApplication();
        CommandLine cmd = new CommandLine(app);

        StringWriter sw = new StringWriter();
        cmd.setErr(new PrintWriter(sw));

        int exitCode = cmd.execute("events");

        assertThat(exitCode).isNotEqualTo(0);
        assertThat(sw.toString()).contains("Missing required option: '--project=<projectId>'");
    }
}
