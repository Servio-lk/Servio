package com.servio.common.util;

import com.servio.auth.entity.Role;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {
    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${supabase.jwt.secret:}")
    private String supabaseJwtSecret;

    @Value("${jwt.expiration:86400000}") // Default 24 hours in milliseconds
    private long jwtExpirationMs;

    public String generateToken(UUID userId, Role role) {
        return generateToken(userId.toString(), role.name());
    }

    // Updated to include Role in the token generation (Long userId - legacy)
    public String generateToken(Long userId, Role role) {
        return generateToken(userId.toString(), role.name());
    }

    // String userId version - supports UUID from Supabase profiles
    public String generateToken(String userId, String role) {
        SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
        return Jwts.builder()
                .subject(userId)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtExpirationMs))
                .signWith(key)
                .compact();
    }

    public String getUserIdFromToken(String token) {
        Claims claims = getAllClaimsFromToken(token);
        return claims.getSubject(); // Returns the raw subject string (Long or UUID)
    }

    public String getRoleFromToken(String token) {
        Claims claims = getAllClaimsFromToken(token);
        String role = claims.get("role", String.class);
        if (role == null || "authenticated".equalsIgnoreCase(role)) {
            Object userMetadataObj = claims.get("user_metadata");
            if (userMetadataObj instanceof java.util.Map) {
                Object metaRole = ((java.util.Map<?, ?>) userMetadataObj).get("role");
                if (metaRole != null) {
                    return metaRole.toString().toUpperCase();
                }
            }
            Object appMetadataObj = claims.get("app_metadata");
            if (appMetadataObj instanceof java.util.Map) {
                Object metaRole = ((java.util.Map<?, ?>) appMetadataObj).get("role");
                if (metaRole != null) {
                    return metaRole.toString().toUpperCase();
                }
            }
            return "USER";
        }
        return role;
    }

    public boolean validateToken(String token) {
        try {
            getAllClaimsFromToken(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private Claims getAllClaimsFromToken(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
            return Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (Exception e) {
            if (supabaseJwtSecret != null && !supabaseJwtSecret.isBlank()) {
                try {
                    SecretKey supabaseKey = Keys.hmacShaKeyFor(supabaseJwtSecret.getBytes());
                    return Jwts.parser()
                            .verifyWith(supabaseKey)
                            .build()
                            .parseSignedClaims(token)
                            .getPayload();
                } catch (Exception ignored) {
                    try {
                        byte[] decoded = java.util.Base64.getDecoder().decode(supabaseJwtSecret);
                        SecretKey b64Key = Keys.hmacShaKeyFor(decoded);
                        return Jwts.parser()
                                .verifyWith(b64Key)
                                .build()
                                .parseSignedClaims(token)
                                .getPayload();
                    } catch (Exception ignored2) {
                    }
                }
            }
            throw e;
        }
    }
}