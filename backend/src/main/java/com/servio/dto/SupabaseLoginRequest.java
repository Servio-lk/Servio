package com.servio.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SupabaseLoginRequest {
    @NotBlank(message = "Access token is required")
    private String accessToken;

    @NotBlank(message = "Email is required")
    private String email;

    @NotBlank(message = "Full name is required")
    private String fullName;

    private String phone;

    @NotBlank(message = "Role is required")
    private String role;
}
