package com.servio.controller;

import com.servio.dto.SignupRequest;
import com.servio.dto.LoginRequest;
import com.servio.dto.MechanicRegistrationLookupDto;
import com.servio.dto.SupabaseLoginRequest;
import com.servio.dto.UserResponse;
import com.servio.dto.AuthResponse;
import com.servio.dto.ApiResponse;
import com.servio.service.AuthService;
import com.servio.service.MechanicService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Validated
@Tag(name = "Auth", description = "Authentication and User Registration APIs")
public class AuthController {
    private final AuthService authService;
    private final MechanicService mechanicService;

    @PostMapping("/signup")
    @Operation(summary = "Register a new user")
    public ResponseEntity<AuthResponse> signup(@Valid @RequestBody SignupRequest request) {
        try {
            AuthResponse response = authService.signup(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(AuthResponse.builder()
                            .success(false)
                            .message(e.getMessage())
                            .build());
        }
    }

    @PostMapping("/login")
    @Operation(summary = "Login an existing user")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(AuthResponse.builder()
                            .success(false)
                            .message(e.getMessage())
                            .build());
        }
    }

    @PostMapping("/supabase-login")
    @Operation(summary = "Login with Supabase JWT")
    public ResponseEntity<AuthResponse> supabaseLogin(@Valid @RequestBody SupabaseLoginRequest request) {
        try {
            AuthResponse response = authService.loginWithSupabase(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(AuthResponse.builder()
                            .success(false)
                            .message(e.getMessage())
                            .build());
        }
    }

    @GetMapping("/mechanic-registration")
    public ResponseEntity<ApiResponse<MechanicRegistrationLookupDto>> mechanicRegistration(
            @RequestParam String email
    ) {
        return mechanicService.findRegistrationByEmail(email)
                .map(mechanic -> {
                    if (Boolean.FALSE.equals(mechanic.getIsActive())) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                .body(ApiResponse.<MechanicRegistrationLookupDto>error(
                                        "Mechanic registration is inactive",
                                        null
                                ));
                    }

                    return ResponseEntity.ok(
                            ApiResponse.success("Mechanic registration found", mechanic)
                    );
                })
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error("No mechanic registration found for this email", null)));
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserResponse>> getProfile(Authentication authentication) {
        try {
            String userId = authentication.getPrincipal().toString();
            UserResponse userResponse;

            try {
                userResponse = authService.getProfile(Long.parseLong(userId));
            } catch (NumberFormatException ex) {
                userResponse = authService.getProfileByUuid(userId);
            }

            return ResponseEntity.ok(ApiResponse.<UserResponse>builder()
                    .success(true)
                    .data(userResponse)
                    .build());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.<UserResponse>builder()
                            .success(false)
                            .message(e.getMessage())
                            .build());
        }
    }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, String>>> health() {
        Map<String, String> data = new HashMap<>();
        data.put("status", "Server is running");
        data.put("database", "Connected");
        data.put("timestamp", java.time.LocalDateTime.now().toString());

        return ResponseEntity.ok(ApiResponse.<Map<String, String>>builder()
                .success(true)
                .message("Server is running")
                .data(data)
                .build());
    }

}
