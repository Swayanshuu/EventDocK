package dev.eventdock.api.service;

import dev.eventdock.api.entity.UserEntity;
import dev.eventdock.api.repository.UserRepository;
import dev.eventdock.api.exception.ForbiddenException;
import dev.eventdock.api.dto.CreateProjectRequest;
import dev.eventdock.api.dto.ProjectDto;
import dev.eventdock.api.entity.ProjectEntity;
import dev.eventdock.api.repository.ProjectRepository;
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
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProjectServiceTest {

    @Mock
    private ProjectRepository projectRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ProjectService projectService;

    private UserEntity owner;
    private UUID ownerId;

    @BeforeEach
    void setUp() {
        ownerId = UUID.randomUUID();
        owner = UserEntity.builder()
                .id(ownerId)
                .firebaseUid("fb_123")
                .email("owner@linkpeer.internal")
                .displayName("Owner")
                .build();
    }

    @Test
    @DisplayName("Should create project and generate slug from name")
    void testCreateProject() {
        when(userRepository.findById(ownerId)).thenReturn(Optional.of(owner));
        when(projectRepository.existsBySlug("linkpeer-backend")).thenReturn(false);
        when(projectRepository.save(any(ProjectEntity.class))).thenAnswer(invocation -> {
            ProjectEntity entity = invocation.getArgument(0);
            entity.setId(UUID.randomUUID());
            return entity;
        });

        CreateProjectRequest request = CreateProjectRequest.builder()
                .name("LinkPeer Backend")
                .description("Core social networking API")
                .retentionDays(45)
                .build();

        ProjectDto result = projectService.createProject(ownerId, request);

        assertThat(result).isNotNull();
        assertThat(result.getName()).isEqualTo("LinkPeer Backend");
        assertThat(result.getSlug()).isEqualTo("linkpeer-backend");
        assertThat(result.getRetentionDays()).isEqualTo(45);
        assertThat(result.getOwnerId()).isEqualTo(ownerId);
    }

    @Test
    @DisplayName("Should enforce project ownership and throw ForbiddenException on unauthorized access")
    void testValidateOwnership() {
        UUID otherUserId = UUID.randomUUID();
        ProjectEntity project = ProjectEntity.builder()
                .id(UUID.randomUUID())
                .name("Private Project")
                .owner(owner)
                .build();

        assertThatThrownBy(() -> projectService.validateOwnership(otherUserId, project))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("permission");
    }
}
