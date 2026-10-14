package dev.eventdock.api.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.api.entity.UserEntity;
import dev.eventdock.api.dto.EventDetailDto;
import dev.eventdock.api.dto.IngestEventRequest;
import dev.eventdock.api.dto.IngestEventResponse;
import dev.eventdock.api.entity.DiagnosticEventEntity;
import dev.eventdock.api.repository.DiagnosticEventRepository;
import dev.eventdock.api.entity.ProjectEntity;
import dev.eventdock.api.repository.ProjectRepository;
import dev.eventdock.api.service.ProjectService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock
    private DiagnosticEventRepository eventRepository;

    @Mock
    private ProjectRepository projectRepository;

    @Mock
    private ProjectService projectService;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private EventService eventService;

    private ProjectEntity project;
    private UUID projectId;
    private UUID userId;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(eventService, "maxStackTraceChars", 1000);
        projectId = UUID.randomUUID();
        userId = UUID.randomUUID();
        UserEntity owner = UserEntity.builder().id(userId).email("dev@linkpeer.internal").build();
        project = ProjectEntity.builder().id(projectId).name("LinkPeer").owner(owner).build();
    }

    @Test
    @DisplayName("Should ingest diagnostic event and persist entity")
    void testIngestEvent() {
        when(projectRepository.findById(projectId)).thenReturn(Optional.of(project));
        when(eventRepository.save(any(DiagnosticEventEntity.class))).thenAnswer(invocation -> {
            DiagnosticEventEntity entity = invocation.getArgument(0);
            entity.setId(UUID.randomUUID());
            entity.setReceivedAt(Instant.now());
            return entity;
        });

        IngestEventRequest request = IngestEventRequest.builder()
                .requestId("req-12345")
                .httpMethod("POST")
                .requestUri("/posts")
                .routeTemplate("/posts")
                .statusCode(500)
                .errorType("java.sql.SQLException")
                .errorMessage("Connection to PostgreSQL failed")
                .stackTrace("java.sql.SQLException: Connection failed\n\tat org.postgresql.Driver.connect")
                .durationMs(120L)
                .metadata(Map.of("User-Agent", "Mozilla/5.0"))
                .build();

        IngestEventResponse response = eventService.ingestEvent(projectId, request);

        assertThat(response).isNotNull();
        assertThat(response.getStatus()).isEqualTo("RECEIVED");
        assertThat(response.getId()).isNotNull();

        verify(eventRepository).save(any(DiagnosticEventEntity.class));
    }

    @Test
    @DisplayName("Should retrieve event detail when authorized")
    void testGetEventDetail() {
        UUID eventId = UUID.randomUUID();
        DiagnosticEventEntity entity = DiagnosticEventEntity.builder()
                .id(eventId)
                .project(project)
                .requestId("req-abc")
                .httpMethod("GET")
                .requestUri("/demo/fail")
                .statusCode(500)
                .occurredAt(Instant.now())
                .build();

        when(eventRepository.findById(eventId)).thenReturn(Optional.of(entity));
        doNothing().when(projectService).validateOwnership(userId, project);

        EventDetailDto detail = eventService.getEventDetail(userId, eventId);

        assertThat(detail).isNotNull();
        assertThat(detail.getId()).isEqualTo(eventId);
        assertThat(detail.getProjectName()).isEqualTo("LinkPeer");
        assertThat(detail.getStatusCode()).isEqualTo(500);
    }
}
