package com.servio.common.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponse {
    private UUID id;
    private String supabaseId; // UUID for Supabase users
    private String fullName;
    private String email;
    private String phone;
    private String role;
    private LocalDateTime createdAt;
}
