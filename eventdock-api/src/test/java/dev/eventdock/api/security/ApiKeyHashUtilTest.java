package dev.eventdock.api.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ApiKeyHashUtilTest {

    @Test
    @DisplayName("Should generate deterministic 64-character hex SHA-256 hash")
    void testHashApiKey() {
        String key = "ed_live_abcdef1234567890abcdef1234567890";
        String hash1 = ApiKeyHashUtil.hashApiKey(key);
        String hash2 = ApiKeyHashUtil.hashApiKey(key);

        assertThat(hash1).isNotNull().hasSize(64);
        assertThat(hash1).isEqualTo(hash2);
    }

    @Test
    @DisplayName("Should reject blank or null keys")
    void testRejectBlankKeys() {
        assertThatThrownBy(() -> ApiKeyHashUtil.hashApiKey(null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> ApiKeyHashUtil.hashApiKey("   "))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
