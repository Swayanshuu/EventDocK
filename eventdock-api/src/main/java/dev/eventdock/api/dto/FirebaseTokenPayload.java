package dev.eventdock.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FirebaseTokenPayload {
    private String uid;
    private String email;
    private String name;
    private Boolean emailVerified;
}
