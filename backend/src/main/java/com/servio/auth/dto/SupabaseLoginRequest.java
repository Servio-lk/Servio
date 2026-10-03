package com.servio.auth.dto;

import com.servio.auth.entity.Role;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SupabaseLoginRequest {
    @NotBlank(message = "Access token is required")
    private String accessToken;

    private String email;

    private String fullName;

    private String phone;

    private String specialization;

    private String role;
}
