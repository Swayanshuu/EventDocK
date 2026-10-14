package dev.eventdock.sample.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PostDto {
    private Long id;
    private String title;
    private String content;
    private String status;
    private Instant createdAt;
}
