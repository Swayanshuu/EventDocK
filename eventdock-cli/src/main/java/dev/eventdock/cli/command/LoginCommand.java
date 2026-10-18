package dev.eventdock.cli.command;

import com.sun.net.httpserver.HttpServer;
import dev.eventdock.cli.client.EventDockApiClient;
import dev.eventdock.cli.config.CliConfig;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;

import java.awt.Desktop;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Scanner;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

@Command(name = "login", description = "Authenticate CLI session using Google Sign-In")
public class LoginCommand implements Callable<Integer> {

    @Option(names = {"--url"}, description = "EventDock API Base URL", defaultValue = "https://api.eventdock.swynx.dev")
    private String apiUrl;

    @Option(names = {"--web-url"}, description = "EventDock Dashboard URL", defaultValue = "https://eventdock.swynx.dev")
    private String webUrl;

    @Option(names = {"--token"}, description = "Direct Google/Firebase ID Token (for headless / CI environments)")
    private String directToken;

    @Override
    public Integer call() {
        if (directToken != null && !directToken.isBlank()) {
            return authenticateWithToken(directToken, "google-cli-user");
        }

        int callbackPort = 8976;
        String loginUrl = webUrl + "/?cli_port=" + callbackPort;

        System.out.println("=================================================");
        System.out.println("  EventDock CLI - Google Authentication");
        System.out.println("=================================================");
        System.out.println("Opening Google Login in your default web browser...");
        System.out.println("URL: " + loginUrl);
        System.out.println();

        AtomicReference<String> capturedToken = new AtomicReference<>();
        AtomicReference<String> capturedEmail = new AtomicReference<>();
        CountDownLatch latch = new CountDownLatch(1);
        HttpServer server = null;

        try {
            server = HttpServer.create(new InetSocketAddress("127.0.0.1", callbackPort), 0);
            server.createContext("/callback", exchange -> {
                exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
                exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, OPTIONS");

                if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                    exchange.sendResponseHeaders(204, -1);
                    return;
                }

                String query = exchange.getRequestURI().getQuery();
                if (query != null) {
                    for (String param : query.split("&")) {
                        String[] pair = param.split("=", 2);
                        if (pair.length == 2) {
                            if ("token".equals(pair[0])) {
                                capturedToken.set(java.net.URLDecoder.decode(pair[1], StandardCharsets.UTF_8));
                            } else if ("email".equals(pair[0])) {
                                capturedEmail.set(java.net.URLDecoder.decode(pair[1], StandardCharsets.UTF_8));
                            }
                        }
                    }
                }

                byte[] html = ("<!DOCTYPE html><html><head><title>EventDock CLI Login</title></head>"
                        + "<body style='background:#0B0F19;color:#F8FAFC;font-family:system-ui,-apple-system,sans-serif;"
                        + "display:flex;align-items:center;justify-content:center;height:100vh;margin:0;'>"
                        + "<div style='text-align:center;padding:40px;background:#151D2E;border-radius:12px;border:1px solid #1E293B;'>"
                        + "<h2 style='color:#38BDF8;margin-bottom:8px;'>✓ Google Authentication Successful!</h2>"
                        + "<p style='color:#94A3B8;margin-bottom:0;'>You may now close this browser tab and return to your terminal.</p>"
                        + "</div></body></html>").getBytes(StandardCharsets.UTF_8);

                exchange.getResponseHeaders().set("Content-Type", "text/html; charset=UTF-8");
                exchange.sendResponseHeaders(200, html.length);
                exchange.getResponseBody().write(html);
                exchange.getResponseBody().close();

                latch.countDown();
            });
            server.start();

            // Open browser
            openBrowser(loginUrl);

            System.out.println("Waiting for Google authentication in browser (up to 120s)...");
            boolean received = latch.await(120, TimeUnit.SECONDS);

            if (received && capturedToken.get() != null) {
                return authenticateWithToken(capturedToken.get(), capturedEmail.get());
            }

            System.out.println("\nBrowser callback timed out or was not received.");
            System.out.print("If your browser opened, copy your token or paste it here (or press Enter to cancel): ");
            Scanner scanner = new Scanner(System.in);
            String manualToken = scanner.nextLine().trim();
            if (!manualToken.isBlank()) {
                return authenticateWithToken(manualToken, "google-cli-user");
            }

            System.err.println("Google authentication cancelled.");
            return 1;
        } catch (Exception e) {
            System.err.println("Could not start local login server: " + e.getMessage());
            System.out.print("Please paste your Google / Firebase ID token manually: ");
            Scanner scanner = new Scanner(System.in);
            String manualToken = scanner.nextLine().trim();
            if (!manualToken.isBlank()) {
                return authenticateWithToken(manualToken, "google-cli-user");
            }
            return 1;
        } finally {
            if (server != null) {
                server.stop(0);
            }
        }
    }

    private Integer authenticateWithToken(String token, String fallbackEmail) {
        CliConfig config = CliConfig.builder()
                .apiUrl(apiUrl)
                .token(token)
                .build();

        try {
            EventDockApiClient client = new EventDockApiClient(config);
            var response = client.getProfile();
            String email = response.path("data").path("email").asText(fallbackEmail != null ? fallbackEmail : "user@gmail.com");
            config.setUserEmail(email);
            config.save();

            System.out.println();
            System.out.println("✓ Successfully authenticated via Google as: " + email);
            System.out.println("✓ Credentials saved to: " + CliConfig.getConfigFilePath());
            return 0;
        } catch (Exception e) {
            System.err.println("Verification failed with EventDock API: " + e.getMessage());
            return 1;
        }
    }

    private void openBrowser(String url) {
        try {
            if (Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
                Desktop.getDesktop().browse(new URI(url));
                return;
            }
        } catch (Throwable ignored) {
        }

        String os = System.getProperty("os.name", "").toLowerCase();
        try {
            if (os.contains("win")) {
                new ProcessBuilder("rundll32", "url.dll,FileProtocolHandler", url).start();
            } else if (os.contains("mac")) {
                new ProcessBuilder("open", url).start();
            } else {
                new ProcessBuilder("xdg-open", url).start();
            }
        } catch (Exception ignored) {
            System.out.println("(Please open " + url + " manually in your browser)");
        }
    }
}
