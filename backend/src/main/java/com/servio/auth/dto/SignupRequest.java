package com.servio.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Pattern;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SignupRequest {
    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Valid email is required")
    @Email(message = "Valid email is required")
    private String email;

    @NotBlank(message = "Phone is optional but must be valid if provided")
    private String phone;

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters long")
    @Pattern(regexp = "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z]).{8,}$", message = "Password must include uppercase, lowercase, and a number")
    private String password;
}
