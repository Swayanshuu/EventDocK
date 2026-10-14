package dev.eventdock.api.controller;

import dev.eventdock.api.security.FirebaseAuthFilter;
import dev.eventdock.api.exception.UnauthorizedException;
import dev.eventdock.api.dto.ApiResponse;
import dev.eventdock.api.dto.CreateProjectRequest;
import dev.eventdock.api.dto.ProjectDto;
import dev.eventdock.api.dto.UpdateProjectRequest;
import dev.eventdock.api.service.ProjectService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/projects")
@Tag(name = "Projects", description = "Project creation, settings, and lifecycle management")
public class ProjectController {

    private final ProjectService projectService;

    public ProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @PostMapping
    @Operation(summary = "Create a new project")
    public ResponseEntity<ApiResponse<ProjectDto>> createProject(
            @Valid @RequestBody CreateProjectRequest request,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        ProjectDto project = projectService.createProject(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Project created successfully", project));
    }

    @GetMapping
    @Operation(summary = "List all projects owned by authenticated user")
    public ResponseEntity<ApiResponse<List<ProjectDto>>> listProjects(HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        List<ProjectDto> projects = projectService.listUserProjects(userId);
        return ResponseEntity.ok(ApiResponse.ok(projects));
    }

    @GetMapping("/{projectId}")
    @Operation(summary = "Get project details by ID")
    public ResponseEntity<ApiResponse<ProjectDto>> getProject(
            @PathVariable UUID projectId,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        ProjectDto project = projectService.getProjectById(userId, projectId);
        return ResponseEntity.ok(ApiResponse.ok(project));
    }

    @PutMapping("/{projectId}")
    @Operation(summary = "Update project configuration")
    public ResponseEntity<ApiResponse<ProjectDto>> updateProject(
            @PathVariable UUID projectId,
            @Valid @RequestBody UpdateProjectRequest request,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        ProjectDto project = projectService.updateProject(userId, projectId, request);
        return ResponseEntity.ok(ApiResponse.ok("Project updated successfully", project));
    }

    @DeleteMapping("/{projectId}")
    @Operation(summary = "Delete project and all associated diagnostic events")
    public ResponseEntity<ApiResponse<Void>> deleteProject(
            @PathVariable UUID projectId,
            HttpServletRequest httpRequest) {
        UUID userId = getAuthenticatedUserId(httpRequest);
        projectService.deleteProject(userId, projectId);
        return ResponseEntity.ok(ApiResponse.ok("Project deleted successfully", null));
    }

    private UUID getAuthenticatedUserId(HttpServletRequest request) {
        Object attr = request.getAttribute(FirebaseAuthFilter.AUTHENTICATED_USER_ID_ATTR);
        if (attr instanceof UUID uuid) {
            return uuid;
        }
        throw new UnauthorizedException("User authentication required");
    }
}
