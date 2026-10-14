package dev.eventdock.api.security;

import dev.eventdock.api.dto.FirebaseTokenPayload;
import dev.eventdock.api.entity.UserEntity;
import dev.eventdock.api.service.AuthService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

/**
 * Filter that intercepts Firebase ID tokens in the Authorization header,
 * verifies them, resolves or creates the local UserEntity, and populates SecurityContext.
 */
@Component
public class FirebaseAuthFilter extends OncePerRequestFilter {

    public static final String AUTHENTICATED_USER_ID_ATTR = "authenticatedUserId";
    public static final String AUTHENTICATED_FIREBASE_UID_ATTR = "authenticatedFirebaseUid";

    private final FirebaseAuthVerifier firebaseAuthVerifier;
    private final AuthService authService;

    public FirebaseAuthFilter(FirebaseAuthVerifier firebaseAuthVerifier, AuthService authService) {
        this.firebaseAuthVerifier = firebaseAuthVerifier;
        this.authService = authService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7).trim();
            try {
                FirebaseTokenPayload payload = firebaseAuthVerifier.verifyToken(token);
                UserEntity user = authService.getOrCreateUser(payload);

                request.setAttribute(AUTHENTICATED_USER_ID_ATTR, user.getId());
                request.setAttribute(AUTHENTICATED_FIREBASE_UID_ATTR, user.getFirebaseUid());

                SimpleGrantedAuthority authority = new SimpleGrantedAuthority("ROLE_" + user.getRole());
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        user.getEmail(),
                        null,
                        Collections.singletonList(authority)
                );

                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (Exception e) {
                // Invalid token - clear context
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }
}
