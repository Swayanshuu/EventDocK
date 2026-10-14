package dev.eventdock.api.service;

import dev.eventdock.api.dto.ApiKeyResponse;
import dev.eventdock.api.dto.CreateApiKeyRequest;
import dev.eventdock.api.entity.ProjectApiKeyEntity;
import dev.eventdock.api.repository.ProjectApiKeyRepository;
import dev.eventdock.api.service.AuditService;
import dev.eventdock.api.entity.UserEntity;
import dev.eventdock.api.entity.ProjectEntity;
import dev.eventdock.api.repository.ProjectRepository;
import dev.eventdock.api.service.ProjectService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ApiKeyServiceTest {

    @Mock
    private ProjectApiKeyRepository apiKeyRepository;

    @Mock
    private ProjectRepository projectRepository;

    @Mock
    private ProjectService projectService;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private ApiKeyService apiKeyService;

    private UserEntity owner;
    private ProjectEntity project;
    private UUID userId;
    private UUID projectId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        projectId = UUID.randomUUID();
        owner = UserEntity.builder().id(userId).email("dev@linkpeer.internal").build();
        project = ProjectEntity.builder().id(projectId).name("LinkPeer").owner(owner).build();
    }

    @Test
    @DisplayName("Should generate raw key starting with ed_live_ and save SHA-256 hash")
    void testGenerateApiKey() {
        when(projectRepository.findById(projectId)).thenReturn(Optional.of(project));
        doNothing().when(projectService).validateOwnership(userId, project);
        when(apiKeyRepository.save(any(ProjectApiKeyEntity.class))).thenAnswer(invocation -> {
            ProjectApiKeyEntity entity = invocation.getArgument(0);
            entity.setId(UUID.randomUUID());
            return entity;
        });

        CreateApiKeyRequest request = CreateApiKeyRequest.builder().name("Production Ingestion").build();
        ApiKeyResponse response = apiKeyService.generateApiKey(userId, projectId, request);

        assertThat(response).isNotNull();
        assertThat(response.getRawKey()).startsWith("ed_live_");
        assertThat(response.getKeyPrefix()).hasSize(16);
        assertThat(response.getName()).isEqualTo("Production Ingestion");
        assertThat(response.getRevoked()).isFalse();

        verify(apiKeyRepository).save(any(ProjectApiKeyEntity.class));
        verify(auditService).recordAction(eq(projectId), eq(userId), eq("API_KEY_CREATED"), anyString(), anyString(), anyString());
    }
}
