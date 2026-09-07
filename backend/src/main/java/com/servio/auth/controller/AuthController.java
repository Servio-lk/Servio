package com.servio.auth.controller;

import com.servio.admin.entity.Mechanic;
import com.servio.auth.entity.User;

import com.servio.auth.dto.SignupRequest;
import com.servio.auth.dto.LoginRequest;
import com.servio.admin.dto.MechanicRegistrationLookupDto;
import com.servio.auth.dto.SupabaseLoginRequest;
import com.servio.common.dto.UserResponse;
import com.servio.auth.dto.AuthResponse;
import com.servio.common.dto.ApiResponse;
import com.servio.auth.service.AuthService;
import com.servio.admin.service.MechanicService;
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
    private final com.servio.auth.service.SupabaseAdminService supabaseAdminService;

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

    @PostMapping("/mechanic-registration/report-error")
    @Operation(summary = "Report incorrect mechanic registration information to admin")
    public ResponseEntity<ApiResponse<String>> reportMechanicRegistrationError(
            @Valid @RequestBody com.servio.auth.dto.ReportErrorRequest request
    ) {
        try {
            mechanicService.reportRegistrationError(request.getEmail());
            return ResponseEntity.ok(ApiResponse.success("Error reported to admin successfully", null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Failed to report error: " + e.getMessage(), null));
        }
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserResponse>> getProfile(Authentication authentication) {
        try {
            String userIdStr = authentication.getPrincipal().toString();
            UserResponse userResponse = authService.getProfileByUuid(userIdStr);

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

    @DeleteMapping("/profile")
    @Operation(summary = "Delete (anonymize) the current user account")
    public ResponseEntity<ApiResponse<String>> deleteProfile(Authentication authentication) {
        try {
            String userIdStr = authentication.getPrincipal().toString();
            java.util.UUID userId = java.util.UUID.fromString(userIdStr);
            String supabaseUserId = authService.deleteCustomer(userId);
            
            // Delete from Supabase Auth after the local DB transaction has successfully committed
            if (supabaseUserId != null) {
                supabaseAdminService.deleteUser(supabaseUserId);
            }
            
            return ResponseEntity.ok(ApiResponse.success("Account deleted successfully", null));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Invalid user ID format", null));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error(e.getMessage(), null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Failed to delete account: " + e.getMessage(), null));
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
