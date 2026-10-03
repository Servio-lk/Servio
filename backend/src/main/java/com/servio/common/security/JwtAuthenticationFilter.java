package com.servio.common.security;

import com.servio.admin.repository.MechanicRepository;
import com.servio.auth.entity.Profile;
import com.servio.auth.repository.ProfileRepository;
import com.servio.common.util.JwtTokenProvider;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtTokenProvider jwtTokenProvider;
    private final ProfileRepository profileRepository;
    private final MechanicRepository mechanicRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String token = extractTokenFromRequest(request);
            String requestURI = request.getRequestURI();

            if (StringUtils.hasText(token)) {
                boolean valid = jwtTokenProvider.validateToken(token);
                logger.info("JWT validation for " + requestURI + ": " + (valid ? "VALID" : "INVALID")
                        + ", token prefix: " + token.substring(0, Math.min(20, token.length())));
                if (valid) {
                    String userId = jwtTokenProvider.getUserIdFromToken(token);
                    String role = jwtTokenProvider.getRoleFromToken(token);

                    if (role == null || "USER".equalsIgnoreCase(role) || "authenticated".equalsIgnoreCase(role)) {
                        try {
                            UUID userUuid = UUID.fromString(userId);
                            Profile profile = profileRepository.findById(userUuid).orElse(null);
                            if (profile != null) {
                                if (Boolean.TRUE.equals(profile.getIsAdmin()) || "ADMIN".equalsIgnoreCase(profile.getRole())) {
                                    role = "ADMIN";
                                } else if ("MECHANIC".equalsIgnoreCase(profile.getRole()) || "STAFF".equalsIgnoreCase(profile.getRole())) {
                                    role = "MECHANIC";
                                } else if (profile.getEmail() != null && mechanicRepository.findByEmailIgnoreCase(profile.getEmail()).isPresent()) {
                                    role = "MECHANIC";
                                }
                            }
                        } catch (Exception ignored) {
                        }
                    }

                    logger.info("Authenticated user id=" + userId + ", role=" + role + " for " + requestURI);

                    // Store authority WITHOUT "ROLE_" prefix so it matches hasAuthority('ADMIN') in
                    // controllers
                    SimpleGrantedAuthority authority = new SimpleGrantedAuthority(role);

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(userId,
                            null, Collections.singletonList(authority));
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } else {
                logger.info("No JWT token found in request to: " + requestURI);
            }
        } catch (Exception e) {
            logger.error("Could not set user authentication", e);
        }

        filterChain.doFilter(request, response);
    }

    private String extractTokenFromRequest(HttpServletRequest request) {
        // Fallback to Bearer token for backward compatibility
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        // Extract token from cookie
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if ("servio_token".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }
}
