package dev.eventdock.api.dto;

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
public class CreateApiKeyRequest {

    @NotBlank(message = "Key name or description is required (e.g. Production Ingestion)")
    @Size(min = 2, max = 100, message = "Key name must be between 2 and 100 characters")
    private String name;
}
