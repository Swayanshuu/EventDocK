package dev.eventdock.api.repository;

import dev.eventdock.api.entity.ReplayAttemptEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ReplayAttemptRepository extends JpaRepository<ReplayAttemptEntity, UUID> {
    List<ReplayAttemptEntity> findAllByEventIdOrderByStartedAtDesc(UUID eventId);
}
