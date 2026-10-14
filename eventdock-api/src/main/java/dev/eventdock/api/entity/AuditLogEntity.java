package dev.eventdock.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditLogEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID projectId;

    private UUID userId;

    @Column(nullable = false, length = 100)
    private String action;

    @Column(nullable = false, length = 50)
    private String resourceType;

    @Column(length = 100)
    private String resourceId;

    @Column(length = 45)
    private String ipAddress;

    @Column(columnDefinition = "TEXT")
    private String details;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant createdAt;
}
