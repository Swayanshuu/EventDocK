package dev.eventdock.api.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.eventdock.api.exception.ResourceNotFoundException;
import dev.eventdock.api.dto.EventDetailDto;
import dev.eventdock.api.dto.EventSummaryDto;
import dev.eventdock.api.dto.IngestEventRequest;
import dev.eventdock.api.dto.IngestEventResponse;
import dev.eventdock.api.entity.DiagnosticEventEntity;
import dev.eventdock.api.repository.DiagnosticEventRepository;
import dev.eventdock.api.entity.ProjectEntity;
import dev.eventdock.api.repository.ProjectRepository;
import dev.eventdock.api.service.ProjectService;
import jakarta.persistence.criteria.Predicate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class EventService {

    private final DiagnosticEventRepository eventRepository;
    private final ProjectRepository projectRepository;
    private final ProjectService projectService;
    private final ObjectMapper objectMapper;

    @Value("${eventdock.limits.max-stack-trace-chars:32768}")
    private int maxStackTraceChars;

    public EventService(DiagnosticEventRepository eventRepository,
                        ProjectRepository projectRepository,
                        ProjectService projectService,
                        ObjectMapper objectMapper) {
        this.eventRepository = eventRepository;
        this.projectRepository = projectRepository;
        this.projectService = projectService;
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
    }

    @Transactional
    public IngestEventResponse ingestEvent(UUID projectId, IngestEventRequest request) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found for ingestion: " + projectId));

        String sanitizedStackTrace = request.getStackTrace();
        if (sanitizedStackTrace != null && sanitizedStackTrace.length() > maxStackTraceChars) {
            sanitizedStackTrace = sanitizedStackTrace.substring(0, maxStackTraceChars) + "\n... [stack trace truncated]";
        }

        String metadataJson = null;
        if (request.getMetadata() != null) {
            try {
                metadataJson = objectMapper.writeValueAsString(request.getMetadata());
            } catch (Exception e) {
                metadataJson = "{}";
            }
        }

        DiagnosticEventEntity entity = DiagnosticEventEntity.builder()
                .project(project)
                .requestId(request.getRequestId())
                .httpMethod(request.getHttpMethod().toUpperCase())
                .routeTemplate(request.getRouteTemplate())
                .requestUri(request.getRequestUri())
                .statusCode(request.getStatusCode())
                .errorType(request.getErrorType())
                .sanitizedErrorMessage(request.getErrorMessage())
                .stackTrace(sanitizedStackTrace)
                .durationMs(request.getDurationMs())
                .occurredAt(request.getOccurredAt() != null ? request.getOccurredAt() : Instant.now())
                .serviceName(request.getServiceName() != null ? request.getServiceName() : project.getName())
                .environment(request.getEnvironment() != null ? request.getEnvironment() : "production")
                .metadataJson(metadataJson)
                .requestBody(request.getRequestBody())
                .responseBody(request.getResponseBody())
                .build();

        entity = eventRepository.save(entity);

        return IngestEventResponse.builder()
                .id(entity.getId())
                .status("RECEIVED")
                .receivedAt(entity.getReceivedAt() != null ? entity.getReceivedAt() : Instant.now())
                .build();
    }

    @Transactional(readOnly = true)
    public Page<EventSummaryDto> listEvents(UUID userId,
                                            UUID projectId,
                                            Integer statusCode,
                                            String httpMethod,
                                            String search,
                                            Pageable pageable) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

        projectService.validateOwnership(userId, project);

        Specification<DiagnosticEventEntity> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("project").get("id"), projectId));

            if (statusCode != null) {
                predicates.add(cb.equal(root.get("statusCode"), statusCode));
            }
            if (httpMethod != null && !httpMethod.isBlank()) {
                predicates.add(cb.equal(root.get("httpMethod"), httpMethod.trim().toUpperCase()));
            }
            if (search != null && !search.isBlank()) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                Predicate uriMatch = cb.like(cb.lower(root.get("requestUri")), pattern);
                Predicate errorMatch = cb.like(cb.lower(root.get("errorType")), pattern);
                predicates.add(cb.or(uriMatch, errorMatch));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return eventRepository.findAll(spec, pageable).map(this::mapToSummaryDto);
    }

    @Transactional(readOnly = true)
    public EventDetailDto getEventDetail(UUID userId, UUID eventId) {
        DiagnosticEventEntity entity = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with ID: " + eventId));

        projectService.validateOwnership(userId, entity.getProject());

        return EventDetailDto.builder()
                .id(entity.getId())
                .projectId(entity.getProject().getId())
                .projectName(entity.getProject().getName())
                .requestId(entity.getRequestId())
                .httpMethod(entity.getHttpMethod())
                .routeTemplate(entity.getRouteTemplate())
                .requestUri(entity.getRequestUri())
                .statusCode(entity.getStatusCode())
                .errorType(entity.getErrorType())
                .sanitizedErrorMessage(entity.getSanitizedErrorMessage())
                .stackTrace(entity.getStackTrace())
                .durationMs(entity.getDurationMs())
                .occurredAt(entity.getOccurredAt())
                .receivedAt(entity.getReceivedAt())
                .serviceName(entity.getServiceName())
                .environment(entity.getEnvironment())
                .metadataJson(entity.getMetadataJson())
                .requestBody(entity.getRequestBody())
                .responseBody(entity.getResponseBody())
                .build();
    }

    private EventSummaryDto mapToSummaryDto(DiagnosticEventEntity entity) {
        return EventSummaryDto.builder()
                .id(entity.getId())
                .projectId(entity.getProject().getId())
                .requestId(entity.getRequestId())
                .httpMethod(entity.getHttpMethod())
                .routeTemplate(entity.getRouteTemplate())
                .requestUri(entity.getRequestUri())
                .statusCode(entity.getStatusCode())
                .errorType(entity.getErrorType())
                .sanitizedErrorMessage(entity.getSanitizedErrorMessage())
                .durationMs(entity.getDurationMs())
                .occurredAt(entity.getOccurredAt())
                .receivedAt(entity.getReceivedAt())
                .serviceName(entity.getServiceName())
                .environment(entity.getEnvironment())
                .build();
    }
}
