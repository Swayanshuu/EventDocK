package dev.eventdock.api.repository;

import dev.eventdock.api.entity.ProjectEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProjectRepository extends JpaRepository<ProjectEntity, UUID> {
    List<ProjectEntity> findAllByOwnerIdOrderByCreatedAtDesc(UUID ownerId);
    Optional<ProjectEntity> findBySlug(String slug);
    boolean existsBySlug(String slug);
}
