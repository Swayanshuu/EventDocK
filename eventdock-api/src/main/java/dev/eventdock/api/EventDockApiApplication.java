package dev.eventdock.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.File;
import java.nio.file.Files;
import java.util.List;

@SpringBootApplication
public class EventDockApiApplication {

    public static void main(String[] args) {
        loadDotenvIfPresent();
        SpringApplication.run(EventDockApiApplication.class, args);
    }

    private static void loadDotenvIfPresent() {
        File[] candidates = new File[] {
                new File(".env"),
                new File("../.env")
        };

        for (File file : candidates) {
            if (file.exists() && file.isFile()) {
                try {
                    List<String> lines = Files.readAllLines(file.toPath());
                    for (String line : lines) {
                        line = line.trim();
                        if (line.isEmpty() || line.startsWith("#") || !line.contains("=")) {
                            continue;
                        }
                        int eq = line.indexOf('=');
                        String key = line.substring(0, eq).trim();
                        String val = line.substring(eq + 1).trim();
                        if ((val.startsWith("\"") && val.endsWith("\"")) || (val.startsWith("'") && val.endsWith("'"))) {
                            val = val.substring(1, val.length() - 1);
                        }
                        if (System.getProperty(key) == null && System.getenv(key) == null) {
                            System.setProperty(key, val);
                        }
                    }
                    break;
                } catch (Exception ignored) {
                }
            }
        }
    }
}
