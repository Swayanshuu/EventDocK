package dev.eventdock.api.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateProjectRequest {

    @NotBlank(message = "Project name is required")
    @Size(min = 2, max = 150, message = "Project name must be between 2 and 150 characters")
    private String name;

    private String slug;

    private String description;

    @Min(value = 1, message = "Retention must be at least 1 day")
    @Max(value = 365, message = "Retention cannot exceed 365 days")
    @Builder.Default
    private Integer retentionDays = 30;
}
