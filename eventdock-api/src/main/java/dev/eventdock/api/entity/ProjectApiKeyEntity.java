package dev.eventdock.api.entity;

import dev.eventdock.api.entity.ProjectEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "project_api_keys")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProjectApiKeyEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private ProjectEntity project;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 16)
    private String keyPrefix;

    @Column(nullable = false, unique = true, length = 64)
    private String keyHash;

    @Column(nullable = false)
    @Builder.Default
    private Boolean revoked = false;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant revokedAt;
}
