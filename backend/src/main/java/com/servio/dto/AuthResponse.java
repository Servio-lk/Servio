package com.servio.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {
    private boolean success;
    private String message;
    private AuthData data;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class AuthData {
        private UserResponse user;
        private String token;
    }
}
