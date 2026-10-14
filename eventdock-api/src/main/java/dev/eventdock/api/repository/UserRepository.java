package dev.eventdock.api.repository;

import dev.eventdock.api.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, UUID> {
    Optional<UserEntity> findByFirebaseUid(String firebaseUid);
    Optional<UserEntity> findByEmail(String email);
    boolean existsByFirebaseUid(String firebaseUid);
}
