package dev.eventdock.api.repository;

import dev.eventdock.api.entity.ProjectApiKeyEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProjectApiKeyRepository extends JpaRepository<ProjectApiKeyEntity, UUID> {
    Optional<ProjectApiKeyEntity> findByKeyHashAndRevokedFalse(String keyHash);
    List<ProjectApiKeyEntity> findAllByProjectIdOrderByCreatedAtDesc(UUID projectId);
}
