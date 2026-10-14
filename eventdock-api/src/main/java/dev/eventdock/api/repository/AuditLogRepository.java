package dev.eventdock.api.repository;

import dev.eventdock.api.entity.AuditLogEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLogEntity, UUID> {
    Page<AuditLogEntity> findAllByProjectIdOrderByCreatedAtDesc(UUID projectId, Pageable pageable);
}
