package dev.eventdock.api.service;

import dev.eventdock.api.service.AuditService;
import dev.eventdock.api.exception.BadRequestException;
import dev.eventdock.api.exception.ResourceNotFoundException;
import dev.eventdock.api.entity.DiagnosticEventEntity;
import dev.eventdock.api.repository.DiagnosticEventRepository;
import dev.eventdock.api.service.ProjectService;
import dev.eventdock.api.dto.ReplayRequest;
import dev.eventdock.api.dto.ReplayResponseDto;
import dev.eventdock.api.entity.ReplayAttemptEntity;
import dev.eventdock.api.repository.ReplayAttemptRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.InetAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ReplayService {

    private static final Logger log = LoggerFactory.getLogger(ReplayService.class);

    private final DiagnosticEventRepository eventRepository;
    private final ReplayAttemptRepository replayRepository;
    private final ProjectService projectService;
    private final AuditService auditService;
    private final HttpClient httpClient;

    private final boolean allowLocalDev;
    private final Set<String> allowedHosts;
    private final int timeoutSeconds;

    public ReplayService(
            DiagnosticEventRepository eventRepository,
            ReplayAttemptRepository replayRepository,
            ProjectService projectService,
            AuditService auditService,
            @Value("${eventdock.replay.allow-local-dev:true}") boolean allowLocalDev,
            @Value("${eventdock.replay.allowed-hosts:localhost,127.0.0.1,eventdock-sample,api-dev.linkpeer.internal}") String allowedHosts,
            @Value("${eventdock.replay.timeout-seconds:10}") int timeoutSeconds) {
        this.eventRepository = eventRepository;
        this.replayRepository = replayRepository;
        this.projectService = projectService;
        this.auditService = auditService;
        this.allowLocalDev = allowLocalDev;
        this.timeoutSeconds = timeoutSeconds > 0 ? timeoutSeconds : 10;

        this.allowedHosts = Arrays.stream(allowedHosts.split(","))
                .map(String::trim)
                .map(String::toLowerCase)
                .collect(Collectors.toSet());

        // SSRF protection: NEVER follow automatic HTTP redirects!
        this.httpClient = HttpClient.newBuilder()
                .followRedirects(HttpClient.Redirect.NEVER)
                .connectTimeout(Duration.ofSeconds(this.timeoutSeconds))
                .build();
    }

    @Transactional
    public ReplayResponseDto executeReplay(UUID userId, UUID eventId, ReplayRequest request) {
        DiagnosticEventEntity event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with ID: " + eventId));

        projectService.validateOwnership(userId, event.getProject());

        // 1. Strict Destination & SSRF Validation
        URI destinationUri = validateAndSanitizeDestination(request.getDestinationUrl(), event.getRequestUri());

        // 2. State-Changing Method Safety Check
        String method = event.getHttpMethod().toUpperCase();
        boolean isUnsafeMethod = Set.of("POST", "PUT", "DELETE", "PATCH").contains(method);
        if (isUnsafeMethod && !request.isConfirmUnsafeMethod()) {
            throw new BadRequestException("Method '" + method + "' is state-changing. Please confirm replay execution with confirmUnsafeMethod=true.");
        }

        Instant startedAt = Instant.now();
        UUID replayId = UUID.randomUUID();

        // 3. Assemble Replay HTTP Request
        HttpRequest.Builder reqBuilder = HttpRequest.newBuilder()
                .uri(destinationUri)
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .header("X-EventDock-Replay-Id", replayId.toString())
                .header("X-EventDock-Original-Request-Id", event.getRequestId());

        if (event.getRequestBody() != null && !event.getRequestBody().isBlank() && !"GET".equalsIgnoreCase(method)) {
            reqBuilder.method(method, HttpRequest.BodyPublishers.ofString(event.getRequestBody()));
            reqBuilder.header("Content-Type", "application/json");
        } else if ("POST".equalsIgnoreCase(method)) {
            reqBuilder.POST(HttpRequest.BodyPublishers.noBody());
        } else if ("PUT".equalsIgnoreCase(method)) {
            reqBuilder.PUT(HttpRequest.BodyPublishers.noBody());
        } else if ("DELETE".equalsIgnoreCase(method)) {
            reqBuilder.DELETE();
        } else {
            reqBuilder.GET();
        }

        ReplayAttemptEntity attempt = ReplayAttemptEntity.builder()
                .id(replayId)
                .event(event)
                .initiatedBy(userId.toString())
                .destinationUrl(destinationUri.toString())
                .startedAt(startedAt)
                .build();

        String responseSnippet = null;
        try {
            HttpResponse<String> httpResponse = httpClient.send(reqBuilder.build(), HttpResponse.BodyHandlers.ofString());
            long durationMs = Duration.between(startedAt, Instant.now()).toMillis();

            attempt.setCompletedAt(Instant.now());
            attempt.setResponseStatus(httpResponse.statusCode());
            attempt.setDurationMs(durationMs);

            if (httpResponse.statusCode() >= 200 && httpResponse.statusCode() < 400) {
                attempt.setOutcome("SUCCESS");
                attempt.setSafeErrorSummary(null);
            } else {
                attempt.setOutcome("REPRODUCED_FAILURE");
                attempt.setSafeErrorSummary("Target returned HTTP " + httpResponse.statusCode());
            }

            responseSnippet = httpResponse.body();
            if (responseSnippet != null && responseSnippet.length() > 500) {
                responseSnippet = responseSnippet.substring(0, 500) + "... [truncated]";
            }

        } catch (Exception e) {
            long durationMs = Duration.between(startedAt, Instant.now()).toMillis();
            attempt.setCompletedAt(Instant.now());
            attempt.setOutcome("NETWORK_ERROR");
            attempt.setDurationMs(durationMs);
            attempt.setSafeErrorSummary("Replay connection failure: " + e.getMessage());
        }

        attempt = replayRepository.save(attempt);

        auditService.recordAction(
                event.getProject().getId(),
                userId,
                "REQUEST_REPLAYED",
                "REPLAY_ATTEMPT",
                attempt.getId().toString(),
                "Replayed " + method + " against " + destinationUri + " (Outcome: " + attempt.getOutcome() + ")"
        );

        return ReplayResponseDto.builder()
                .id(attempt.getId())
                .eventId(event.getId())
                .initiatedBy(attempt.getInitiatedBy())
                .destinationUrl(attempt.getDestinationUrl())
                .startedAt(attempt.getStartedAt())
                .completedAt(attempt.getCompletedAt())
                .responseStatus(attempt.getResponseStatus())
                .durationMs(attempt.getDurationMs())
                .outcome(attempt.getOutcome())
                .safeErrorSummary(attempt.getSafeErrorSummary())
                .responseSnippet(responseSnippet)
                .build();
    }

    @Transactional(readOnly = true)
    public List<ReplayResponseDto> listReplayHistory(UUID userId, UUID eventId) {
        DiagnosticEventEntity event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with ID: " + eventId));

        projectService.validateOwnership(userId, event.getProject());

        return replayRepository.findAllByEventIdOrderByStartedAtDesc(eventId)
                .stream()
                .map(a -> ReplayResponseDto.builder()
                        .id(a.getId())
                        .eventId(a.getEvent().getId())
                        .initiatedBy(a.getInitiatedBy())
                        .destinationUrl(a.getDestinationUrl())
                        .startedAt(a.getStartedAt())
                        .completedAt(a.getCompletedAt())
                        .responseStatus(a.getResponseStatus())
                        .durationMs(a.getDurationMs())
                        .outcome(a.getOutcome())
                        .safeErrorSummary(a.getSafeErrorSummary())
                        .build())
                .toList();
    }

    public URI validateAndSanitizeDestination(String rawDestination, String originalPath) {
        if (rawDestination == null || rawDestination.isBlank()) {
            throw new BadRequestException("Destination URL cannot be blank");
        }

        URI baseUri;
        try {
            baseUri = URI.create(rawDestination.trim());
        } catch (Exception e) {
            throw new BadRequestException("Invalid destination URL format: " + rawDestination);
        }

        String scheme = baseUri.getScheme();
        if (scheme == null || (!scheme.equalsIgnoreCase("http") && !scheme.equalsIgnoreCase("https"))) {
            throw new BadRequestException("Only HTTP and HTTPS protocols are permitted for replay");
        }

        String host = baseUri.getHost();
        if (host == null || host.isBlank()) {
            throw new BadRequestException("Destination URL must contain a valid hostname");
        }

        // Perform DNS resolution check & SSRF defense
        try {
            InetAddress[] addresses = InetAddress.getAllByName(host);
            for (InetAddress addr : addresses) {
                boolean isRestricted = isRestrictedAddress(addr);
                if (isRestricted) {
                    boolean isExplicitlyAllowedLocal = allowLocalDev && allowedHosts.contains(host.toLowerCase());
                    if (!isExplicitlyAllowedLocal) {
                        throw new BadRequestException("Destination host '" + host + "' resolves to a restricted private or link-local address (" + addr.getHostAddress() + ")");
                    }
                }
            }
        } catch (BadRequestException bre) {
            throw bre;
        } catch (Exception e) {
            throw new BadRequestException("Unable to resolve DNS for replay destination host '" + host + "': " + e.getMessage());
        }

        // Append original request path if base destination does not include specific path
        String path = baseUri.getPath();
        if (path == null || path.isBlank() || "/".equals(path)) {
            path = originalPath;
        }

        int port = baseUri.getPort();
        String portStr = port > 0 ? ":" + port : "";

        return URI.create(scheme + "://" + host + portStr + path);
    }

    private boolean isRestrictedAddress(InetAddress addr) {
        if (addr.isLoopbackAddress() || addr.isLinkLocalAddress() || addr.isSiteLocalAddress() || addr.isAnyLocalAddress()) {
            return true;
        }
        byte[] bytes = addr.getAddress();
        if (bytes.length == 4) {
            int b0 = bytes[0] & 0xFF;
            int b1 = bytes[1] & 0xFF;
            // 10.0.0.0/8
            if (b0 == 10) return true;
            // 172.16.0.0/12
            if (b0 == 172 && (b1 >= 16 && b1 <= 31)) return true;
            // 192.168.0.0/16
            if (b0 == 192 && b1 == 168) return true;
            // 169.254.0.0/16 (Cloud Metadata & Link-local)
            if (b0 == 169 && b1 == 254) return true;
        }
        return false;
    }
}
