package dev.eventdock.cli;

import dev.eventdock.cli.command.*;
import picocli.CommandLine;
import picocli.CommandLine.Command;

@Command(name = "eventdock",
        description = "EventDock CLI: Developer platform to inspect and reproduce API failures",
        mixinStandardHelpOptions = true,
        version = "1.0.0",
        subcommands = {
                LoginCommand.class,
                ProjectsCommand.class,
                EventsCommand.class,
                ReplayCommand.class,
                ConfigCommand.class
        })
public class EventDockCliApplication implements Runnable {

    public static void main(String[] args) {
        int exitCode = new CommandLine(new EventDockCliApplication()).execute(args);
        System.exit(exitCode);
    }

    @Override
    public void run() {
        CommandLine.usage(this, System.out);
    }
}
