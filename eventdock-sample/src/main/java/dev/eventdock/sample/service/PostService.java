package dev.eventdock.sample.service;

import dev.eventdock.sample.dto.PostDto;
import dev.eventdock.sample.dto.PostRequest;
import dev.eventdock.sample.entity.Post;
import dev.eventdock.sample.exception.DatabaseConnectionException;
import dev.eventdock.sample.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;

    public List<PostDto> getAllPosts() {
        return postRepository.findAll().stream()
                .map(this::toDto)
                .toList();
    }

    public PostDto getPostById(Long id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found with id: " + id));
        return toDto(post);
    }

    @Transactional
    public PostDto createPost(PostRequest request) {
        if (request.isSimulateDbFailure()) {
            throw new DatabaseConnectionException("Deadlock detected during insert into 'posts' partition");
        }

        Post post = Post.builder()
                .title(request.getTitle())
                .content(request.getContent() != null ? request.getContent() : "")
                .status("PUBLISHED")
                .build();

        Post saved = postRepository.save(post);
        return toDto(saved);
    }

    public void triggerDatabaseTimeout() {
        throw new DatabaseConnectionException("PostgreSQL connection timeout during query execution on table 'posts'");
    }

    private PostDto toDto(Post post) {
        return PostDto.builder()
                .id(post.getId())
                .title(post.getTitle())
                .content(post.getContent())
                .status(post.getStatus())
                .createdAt(post.getCreatedAt())
                .build();
    }
}
