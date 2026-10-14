package dev.eventdock.api.service;

import dev.eventdock.api.entity.UserEntity;
import dev.eventdock.api.repository.UserRepository;
import dev.eventdock.api.exception.BadRequestException;
import dev.eventdock.api.exception.ForbiddenException;
import dev.eventdock.api.exception.ResourceNotFoundException;
import dev.eventdock.api.dto.CreateProjectRequest;
import dev.eventdock.api.dto.ProjectDto;
import dev.eventdock.api.dto.UpdateProjectRequest;
import dev.eventdock.api.entity.ProjectEntity;
import dev.eventdock.api.repository.ProjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
public class ProjectService {

    private static final Pattern NON_LATIN = Pattern.compile("[^\\w-]");
    private static final Pattern WHITESPACE = Pattern.compile("[\\s]");

    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;

    public ProjectService(ProjectRepository projectRepository, UserRepository userRepository) {
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ProjectDto createProject(UUID userId, CreateProjectRequest request) {
        UserEntity owner = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String slug = request.getSlug();
        if (slug == null || slug.isBlank()) {
            slug = slugify(request.getName());
        } else {
            slug = slugify(slug);
        }

        // If slug collision, append random suffix
        if (projectRepository.existsBySlug(slug)) {
            slug = slug + "-" + UUID.randomUUID().toString().substring(0, 6);
        }

        ProjectEntity project = ProjectEntity.builder()
                .name(request.getName().trim())
                .slug(slug)
                .description(request.getDescription())
                .owner(owner)
                .retentionDays(request.getRetentionDays() != null ? request.getRetentionDays() : 30)
                .build();

        project = projectRepository.save(project);
        return mapToDto(project);
    }

    @Transactional(readOnly = true)
    public List<ProjectDto> listUserProjects(UUID userId) {
        return projectRepository.findAllByOwnerIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::mapToDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public ProjectDto getProjectById(UUID userId, UUID projectId) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found with ID: " + projectId));

        validateOwnership(userId, project);
        return mapToDto(project);
    }

    @Transactional
    public ProjectDto updateProject(UUID userId, UUID projectId, UpdateProjectRequest request) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found with ID: " + projectId));

        validateOwnership(userId, project);

        if (request.getName() != null && !request.getName().isBlank()) {
            project.setName(request.getName().trim());
        }
        if (request.getDescription() != null) {
            project.setDescription(request.getDescription());
        }
        if (request.getRetentionDays() != null) {
            project.setRetentionDays(request.getRetentionDays());
        }

        project = projectRepository.save(project);
        return mapToDto(project);
    }

    @Transactional
    public void deleteProject(UUID userId, UUID projectId) {
        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found with ID: " + projectId));

        validateOwnership(userId, project);
        projectRepository.delete(project);
    }

    public void validateOwnership(UUID userId, ProjectEntity project) {
        if (!project.getOwner().getId().equals(userId)) {
            throw new ForbiddenException("You do not have permission to access project: " + project.getId());
        }
    }

    private ProjectDto mapToDto(ProjectEntity entity) {
        return ProjectDto.builder()
                .id(entity.getId())
                .name(entity.getName())
                .slug(entity.getSlug())
                .description(entity.getDescription())
                .ownerId(entity.getOwner().getId())
                .retentionDays(entity.getRetentionDays())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    private String slugify(String input) {
        if (input == null) return "";
        String nowhitespace = WHITESPACE.matcher(input.trim()).replaceAll("-");
        String normalized = Normalizer.normalize(nowhitespace, Normalizer.Form.NFD);
        String slug = NON_LATIN.matcher(normalized).replaceAll("").toLowerCase(Locale.ENGLISH);
        return slug.replaceAll("-{2,}", "-").replaceAll("^-|-$", "");
    }
}
