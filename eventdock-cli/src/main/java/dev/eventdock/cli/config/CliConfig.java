package dev.eventdock.cli.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CliConfig {

    @Builder.Default
    private String apiUrl = "https://api.eventdock.swynx.dev";

    private String token;
    private String userEmail;

    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static Path getConfigFilePath() {
        String userHome = System.getProperty("user.home", ".");
        return Paths.get(userHome, ".eventdock", "credentials.json");
    }

    public static CliConfig load() {
        Path path = getConfigFilePath();
        if (Files.exists(path)) {
            try {
                return MAPPER.readValue(path.toFile(), CliConfig.class);
            } catch (Exception e) {
                // Return default on parse failure
            }
        }
        return CliConfig.builder().build();
    }

    public void save() {
        try {
            Path path = getConfigFilePath();
            Files.createDirectories(path.getParent());
            MAPPER.writerWithDefaultPrettyPrinter().writeValue(path.toFile(), this);
        } catch (Exception e) {
            System.err.println("Warning: Failed to persist credentials to " + getConfigFilePath() + ": " + e.getMessage());
        }
    }
}
