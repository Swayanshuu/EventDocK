package dev.eventdock.api.service;

import dev.eventdock.api.dto.FirebaseTokenPayload;
import dev.eventdock.api.dto.UserDto;
import dev.eventdock.api.entity.UserEntity;
import dev.eventdock.api.repository.UserRepository;
import dev.eventdock.api.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;

    public AuthService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional
    public UserEntity getOrCreateUser(FirebaseTokenPayload payload) {
        return userRepository.findByFirebaseUid(payload.getUid())
                .map(existing -> {
                    // Sync email or display name if updated in Firebase
                    if (payload.getEmail() != null && !payload.getEmail().equals(existing.getEmail())) {
                        existing.setEmail(payload.getEmail());
                    }
                    if (payload.getName() != null && !payload.getName().equals(existing.getDisplayName())) {
                        existing.setDisplayName(payload.getName());
                    }
                    return userRepository.save(existing);
                })
                .orElseGet(() -> {
                    UserEntity newUser = UserEntity.builder()
                            .firebaseUid(payload.getUid())
                            .email(payload.getEmail() != null ? payload.getEmail() : payload.getUid() + "@firebase.user")
                            .displayName(payload.getName() != null ? payload.getName() : payload.getEmail())
                            .role("DEVELOPER")
                            .build();
                    return userRepository.save(newUser);
                });
    }

    @Transactional(readOnly = true)
    public UserDto getUserProfile(UUID userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + userId));

        return UserDto.builder()
                .id(user.getId())
                .firebaseUid(user.getFirebaseUid())
                .email(user.getEmail())
                .displayName(user.getDisplayName())
                .role(user.getRole())
                .build();
    }
}
