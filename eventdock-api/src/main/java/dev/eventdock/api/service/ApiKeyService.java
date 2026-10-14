package dev.eventdock.api.service;

import dev.eventdock.api.dto.ApiKeyResponse;
import dev.eventdock.api.dto.ApiKeySummaryDto;
import dev.eventdock.api.dto.CreateApiKeyRequest;
import dev.eventdock.api.entity.ProjectApiKeyEntity;
import dev.eventdock.api.repository.ProjectApiKeyRepository;
import dev.eventdock.api.security.ApiKeyHashUtil;
import dev.eventdock.api.service.AuditService;
import dev.eventdock.api.exception.ResourceNotFoundException;
import dev.eventdock.api.entity.ProjectEntity;
import dev.eventdock.api.repository.ProjectRepository;
import dev.eventdock.api.service.ProjectService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
public class ApiKeyService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final ProjectApiKeyRepository apiKeyRepository;
    private final ProjectRepository projectRepository;
    private final ProjectService projectService;
    private final AuditService auditService;

    public ApiKeyService(ProjectApiKeyRepository apiKeyRepository,
                         ProjectRepository projectRepository,
                         ProjectService projectService,
                         AuditService auditService) {
        this.apiKeyRepository = apiKeyRepository;
        this.projectRepository = projectRepository;
        this.projectService = projectService;
        this.auditService = auditService;
    }

    @Transactional
    public ApiKeyResponse generateApiKey(UUID userId, UUID projectId, CreateApiKeyRequest request) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

        projectService.validateOwnership(userId, project);

        // Generate raw secret: ed_live_ + 32 cryptographically random alphanumeric chars
        byte[] randomBytes = new byte[24];
        SECURE_RANDOM.nextBytes(randomBytes);
        String randomSuffix = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
        String rawKey = "ed_live_" + randomSuffix;

        String keyPrefix = rawKey.substring(0, 16);
        String keyHash = ApiKeyHashUtil.hashApiKey(rawKey);

        ProjectApiKeyEntity entity = ProjectApiKeyEntity.builder()
                .project(project)
                .name(request.getName().trim())
                .keyPrefix(keyPrefix)
                .keyHash(keyHash)
                .revoked(false)
                .build();

        entity = apiKeyRepository.save(entity);

        auditService.recordAction(projectId, userId, "API_KEY_CREATED", "PROJECT_API_KEY", entity.getId().toString(), "Created key: " + entity.getName());

        return ApiKeyResponse.builder()
                .id(entity.getId())
                .name(entity.getName())
                .keyPrefix(entity.getKeyPrefix())
                .createdAt(entity.getCreatedAt())
                .revoked(entity.getRevoked())
                .rawKey(rawKey)
                .build();
    }

    @Transactional(readOnly = true)
    public List<ApiKeySummaryDto> listApiKeys(UUID userId, UUID projectId) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

        projectService.validateOwnership(userId, project);

        return apiKeyRepository.findAllByProjectIdOrderByCreatedAtDesc(projectId)
                .stream()
                .map(k -> ApiKeySummaryDto.builder()
                        .id(k.getId())
                        .name(k.getName())
                        .keyPrefix(k.getKeyPrefix())
                        .revoked(k.getRevoked())
                        .createdAt(k.getCreatedAt())
                        .revokedAt(k.getRevokedAt())
                        .build())
                .toList();
    }

    @Transactional
    public void revokeApiKey(UUID userId, UUID projectId, UUID keyId) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

        projectService.validateOwnership(userId, project);

        ProjectApiKeyEntity key = apiKeyRepository.findById(keyId)
                .orElseThrow(() -> new ResourceNotFoundException("API key not found: " + keyId));

        if (!key.getProject().getId().equals(projectId)) {
            throw new ResourceNotFoundException("API key does not belong to project: " + projectId);
        }

        key.setRevoked(true);
        key.setRevokedAt(Instant.now());
        apiKeyRepository.save(key);

        auditService.recordAction(projectId, userId, "API_KEY_REVOKED", "PROJECT_API_KEY", key.getId().toString(), "Revoked key: " + key.getName());
    }
}
