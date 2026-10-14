package dev.eventdock.cli.command;

import dev.eventdock.cli.config.CliConfig;
import picocli.CommandLine.Command;

import java.util.concurrent.Callable;

@Command(name = "config", description = "Inspect CLI configuration and local authentication status",
        subcommands = {ConfigCommand.ShowSubcommand.class})
public class ConfigCommand implements Callable<Integer> {

    @Override
    public Integer call() {
        return new ShowSubcommand().call();
    }

    @Command(name = "show", description = "Show current configuration settings")
    public static class ShowSubcommand implements Callable<Integer> {
        @Override
        public Integer call() {
            CliConfig config = CliConfig.load();
            System.out.println("EventDock CLI Configuration:");
            System.out.println("  Config File: " + CliConfig.getConfigFilePath());
            System.out.println("  API URL:     " + config.getApiUrl());
            System.out.println("  User:        " + (config.getUserEmail() != null ? config.getUserEmail() : "(not authenticated)"));
            System.out.println("  Token:       " + (config.getToken() != null ? mask(config.getToken()) : "(none)"));
            return 0;
        }

        private String mask(String token) {
            if (token == null || token.length() <= 8) return "***";
            return token.substring(0, 4) + "..." + token.substring(token.length() - 4);
        }
    }
}
