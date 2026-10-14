package dev.eventdock.api.security;

import dev.eventdock.api.entity.ProjectApiKeyEntity;
import dev.eventdock.api.repository.ProjectApiKeyRepository;
import dev.eventdock.api.security.ApiKeyHashUtil;
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
import java.util.Optional;

@Component
public class ApiKeyAuthenticationFilter extends OncePerRequestFilter {

    public static final String API_KEY_HEADER = "X-EventDock-Api-Key";
    public static final String AUTHENTICATED_PROJECT_ID_ATTR = "authenticatedProjectId";

    private final ProjectApiKeyRepository apiKeyRepository;

    public ApiKeyAuthenticationFilter(ProjectApiKeyRepository apiKeyRepository) {
        this.apiKeyRepository = apiKeyRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String rawApiKey = request.getHeader(API_KEY_HEADER);

        if (rawApiKey != null && !rawApiKey.isBlank()) {
            try {
                String hash = ApiKeyHashUtil.hashApiKey(rawApiKey);
                Optional<ProjectApiKeyEntity> keyOpt = apiKeyRepository.findByKeyHashAndRevokedFalse(hash);

                if (keyOpt.isPresent()) {
                    ProjectApiKeyEntity keyEntity = keyOpt.get();
                    request.setAttribute(AUTHENTICATED_PROJECT_ID_ATTR, keyEntity.getProject().getId());

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            "apiKey:" + keyEntity.getKeyPrefix(),
                            null,
                            Collections.singletonList(new SimpleGrantedAuthority("ROLE_INGEST"))
                    );

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (Exception e) {
                // Ignore parsing errors and let security chain reject if unauthorized
            }
        }

        filterChain.doFilter(request, response);
    }
}
