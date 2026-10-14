package dev.eventdock.api.entity;

import dev.eventdock.api.entity.ProjectEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "events")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DiagnosticEventEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private ProjectEntity project;

    @Column(nullable = false, length = 100)
    private String requestId;

    @Column(nullable = false, length = 16)
    private String httpMethod;

    @Column(length = 255)
    private String routeTemplate;

    @Column(nullable = false, length = 1024)
    private String requestUri;

    @Column(nullable = false)
    private Integer statusCode;

    @Column(length = 255)
    private String errorType;

    @Column(columnDefinition = "TEXT")
    private String sanitizedErrorMessage;

    @Column(columnDefinition = "TEXT")
    private String stackTrace;

    private Long durationMs;

    @Column(nullable = false)
    private Instant occurredAt;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant receivedAt;

    @Column(length = 100)
    private String serviceName;

    @Column(length = 50)
    private String environment;

    @Column(columnDefinition = "TEXT")
    private String metadataJson;

    @Column(columnDefinition = "TEXT")
    private String requestBody;

    @Column(columnDefinition = "TEXT")
    private String responseBody;
}
