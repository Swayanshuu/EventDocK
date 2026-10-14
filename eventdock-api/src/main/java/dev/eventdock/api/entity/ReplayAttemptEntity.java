package dev.eventdock.api.entity;

import dev.eventdock.api.entity.DiagnosticEventEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "replay_attempts")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReplayAttemptEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private DiagnosticEventEntity event;

    @Column(nullable = false, length = 100)
    private String initiatedBy;

    @Column(nullable = false, length = 1024)
    private String destinationUrl;

    @Column(nullable = false)
    private Instant startedAt;

    private Instant completedAt;

    private Integer responseStatus;

    private Long durationMs;

    @Column(nullable = false, length = 50)
    private String outcome;

    @Column(columnDefinition = "TEXT")
    private String safeErrorSummary;
}
