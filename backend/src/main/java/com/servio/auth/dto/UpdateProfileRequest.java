package com.servio.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {
    @NotBlank(message = "Full name is required")
    @Size(max = 100, message = "Full name must be 100 characters or fewer")
    private String fullName;

    @Pattern(regexp = "^$|^\\+?[0-9\\s-]{9,20}$", message = "Enter a valid phone number")
    private String phone;

    @Size(max = 500, message = "Bio must be 500 characters or fewer")
    private String bio;

    @Size(max = 500, message = "Avatar URL must be 500 characters or fewer")
    private String avatarUrl;
}
