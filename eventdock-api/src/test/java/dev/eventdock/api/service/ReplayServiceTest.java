package dev.eventdock.api.service;

import dev.eventdock.api.service.AuditService;
import dev.eventdock.api.entity.UserEntity;
import dev.eventdock.api.exception.BadRequestException;
import dev.eventdock.api.entity.DiagnosticEventEntity;
import dev.eventdock.api.repository.DiagnosticEventRepository;
import dev.eventdock.api.entity.ProjectEntity;
import dev.eventdock.api.service.ProjectService;
import dev.eventdock.api.dto.ReplayRequest;
import dev.eventdock.api.repository.ReplayAttemptRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.net.URI;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReplayServiceTest {

    @Mock
    private DiagnosticEventRepository eventRepository;

    @Mock
    private ReplayAttemptRepository replayRepository;

    @Mock
    private ProjectService projectService;

    @Mock
    private AuditService auditService;

    private ReplayService replayService;
    private UserEntity owner;
    private ProjectEntity project;
    private UUID userId;
    private UUID projectId;

    @BeforeEach
    void setUp() {
        replayService = new ReplayService(
                eventRepository,
                replayRepository,
                projectService,
                auditService,
                true,
                "localhost,127.0.0.1,api-dev.linkpeer.internal",
                2
        );

        userId = UUID.randomUUID();
        projectId = UUID.randomUUID();
        owner = UserEntity.builder().id(userId).email("dev@linkpeer.internal").build();
        project = ProjectEntity.builder().id(projectId).name("LinkPeer").owner(owner).build();
    }

    @Test
    @DisplayName("Should permit approved localhost target in local dev mode")
    void testValidateApprovedLocalhost() {
        URI uri = replayService.validateAndSanitizeDestination("http://localhost:8081", "/demo/fail");
        assertThat(uri).isNotNull();
        assertThat(uri.toString()).isEqualTo("http://localhost:8081/demo/fail");
    }

    @Test
    @DisplayName("Should reject non-HTTP protocols (e.g. file, ftp) to protect against SSRF")
    void testRejectNonHttpProtocols() {
        assertThatThrownBy(() -> replayService.validateAndSanitizeDestination("file:///etc/passwd", "/"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Only HTTP and HTTPS");

        assertThatThrownBy(() -> replayService.validateAndSanitizeDestination("ftp://192.168.1.1", "/"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Only HTTP and HTTPS");
    }

    @Test
    @DisplayName("Should require explicit confirmation before replaying state-changing POST requests")
    void testRequireConfirmationForUnsafeMethods() {
        UUID eventId = UUID.randomUUID();
        DiagnosticEventEntity event = DiagnosticEventEntity.builder()
                .id(eventId)
                .project(project)
                .httpMethod("POST")
                .requestUri("/posts")
                .build();

        when(eventRepository.findById(eventId)).thenReturn(Optional.of(event));
        doNothing().when(projectService).validateOwnership(userId, project);

        ReplayRequest request = ReplayRequest.builder()
                .destinationUrl("http://localhost:8081")
                .confirmUnsafeMethod(false) // Not confirmed!
                .build();

        assertThatThrownBy(() -> replayService.executeReplay(userId, eventId, request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("state-changing");
    }
}
