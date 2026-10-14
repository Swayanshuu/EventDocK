package dev.eventdock.api.service;

import dev.eventdock.api.entity.AuditLogEntity;
import dev.eventdock.api.repository.AuditLogRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuditService {

    private static final Logger log = LoggerFactory.getLogger(AuditService.class);

    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordAction(UUID projectId, UUID userId, String action, String resourceType, String resourceId, String details) {
        try {
            AuditLogEntity logEntity = AuditLogEntity.builder()
                    .projectId(projectId)
                    .userId(userId)
                    .action(action)
                    .resourceType(resourceType)
                    .resourceId(resourceId)
                    .details(details)
                    .build();

            auditLogRepository.save(logEntity);
        } catch (Exception e) {
            log.warn("Failed to write audit log entry: {}", e.getMessage());
        }
    }
}
