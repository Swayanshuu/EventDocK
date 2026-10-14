package dev.eventdock.sample.controller;

import dev.eventdock.sample.dto.PostDto;
import dev.eventdock.sample.dto.PostRequest;
import dev.eventdock.sample.exception.DatabaseConnectionException;
import dev.eventdock.sample.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class DemoController {

    private final PostService postService;

    // Standard JPA REST Endpoints
    @GetMapping("/api/posts")
    public ResponseEntity<List<PostDto>> getPosts() {
        return ResponseEntity.ok(postService.getAllPosts());
    }

    @GetMapping("/api/posts/{id}")
    public ResponseEntity<PostDto> getPostById(@PathVariable Long id) {
        return ResponseEntity.ok(postService.getPostById(id));
    }

    @PostMapping({"/api/posts", "/demo/posts"})
    public ResponseEntity<Map<String, Object>> createPost(@Valid @RequestBody PostRequest request) {
        PostDto created = postService.createPost(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "id", created.getId().toString(),
                "title", created.getTitle(),
                "content", created.getContent() != null ? created.getContent() : "",
                "status", created.getStatus()
        ));
    }

    // Failure Simulation Endpoints for EventDock capture
    @GetMapping({"/demo/success"})
    public ResponseEntity<Map<String, Object>> getSuccess() {
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "message", "LinkPeer feed retrieved successfully",
                "totalPosts", postService.getAllPosts().size()
        ));
    }

    @GetMapping({"/demo/fail", "/api/posts/fail-db"})
    public ResponseEntity<Void> triggerFailure() {
        postService.triggerDatabaseTimeout();
        return ResponseEntity.ok().build();
    }

    @GetMapping("/demo/bad-request")
    public ResponseEntity<Map<String, Object>> getBadRequest() {
        return ResponseEntity.badRequest().body(Map.of(
                "error", "Bad Request",
                "message", "Missing required query parameter 'targetId'"
        ));
    }

    @GetMapping({"/demo/not-found", "/api/posts/fail-404"})
    public ResponseEntity<Void> getNotFound() {
        throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Resource not found at /demo/not-found");
    }

    @ExceptionHandler(DatabaseConnectionException.class)
    public ResponseEntity<Map<String, String>> handleDatabaseException(DatabaseConnectionException ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "error", "Database Error",
                "message", ex.getMessage()
        ));
    }
}
