package com.servio.auth.controller;

import com.servio.admin.dto.MechanicRegistrationLookupDto;
import com.servio.admin.service.MechanicService;
import com.servio.auth.dto.AuthResponse;
import com.servio.auth.dto.LoginRequest;
import com.servio.auth.dto.SignupRequest;
import com.servio.auth.dto.SupabaseLoginRequest;
import com.servio.auth.service.AuthService;
import com.servio.auth.service.SupabaseAdminService;
import com.servio.common.dto.ApiResponse;
import com.servio.common.dto.UserResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock
    private AuthService authService;
    @Mock
    private MechanicService mechanicService;
    @Mock
    private SupabaseAdminService supabaseAdminService;
    @Mock
    private Authentication authentication;

    @InjectMocks
    private AuthController authController;

    private UUID testUserId;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
    }

    @Test
    @DisplayName("signup endpoint returns 201 Created on valid registration")
    void testSignup_success() {
        SignupRequest request = new SignupRequest();
        request.setEmail("newuser@servio.lk");
        request.setPassword("password123");
        request.setFullName("New User");

        AuthResponse authResponse = AuthResponse.builder()
                .success(true)
                .message("User registered successfully")
                .data(AuthResponse.AuthData.builder()
                        .token("jwt.token")
                        .build())
                .build();

        when(authService.signup(any(SignupRequest.class))).thenReturn(authResponse);

        ResponseEntity<AuthResponse> response = authController.signup(request);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("jwt.token", response.getBody().getData().getToken());
    }

    @Test
    @DisplayName("signup endpoint returns 400 Bad Request on service error")
    void testSignup_failure() {
        SignupRequest request = new SignupRequest();
        request.setEmail("existing@servio.lk");

        when(authService.signup(any(SignupRequest.class)))
                .thenThrow(new IllegalArgumentException("User with this email already exists"));

        ResponseEntity<AuthResponse> response = authController.signup(request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertFalse(response.getBody().isSuccess());
        assertEquals("User with this email already exists", response.getBody().getMessage());
    }

    @Test
    @DisplayName("login endpoint returns 200 OK on valid credentials")
    void testLogin_success() {
        LoginRequest request = new LoginRequest();
        request.setEmail("user@servio.lk");
        request.setPassword("correctPassword");

        AuthResponse authResponse = AuthResponse.builder()
                .success(true)
                .message("Login successful")
                .data(AuthResponse.AuthData.builder().token("jwt.token.valid").build())
                .build();

        when(authService.login(any(LoginRequest.class))).thenReturn(authResponse);

        ResponseEntity<AuthResponse> response = authController.login(request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().isSuccess());
    }

    @Test
    @DisplayName("login endpoint returns 401 Unauthorized on invalid credentials")
    void testLogin_unauthorized() {
        LoginRequest request = new LoginRequest();
        request.setEmail("user@servio.lk");
        request.setPassword("wrongPassword");

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new IllegalArgumentException("Invalid email or password"));

        ResponseEntity<AuthResponse> response = authController.login(request);

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
        assertFalse(response.getBody().isSuccess());
    }

    @Test
    @DisplayName("supabaseLogin endpoint returns 200 OK on successful Supabase exchange")
    void testSupabaseLogin_success() {
        SupabaseLoginRequest request = new SupabaseLoginRequest();
        request.setAccessToken("valid.supabase.token");
        request.setEmail("oauth@servio.lk");

        AuthResponse authResponse = AuthResponse.builder()
                .success(true)
                .message("Supabase login successful")
                .data(AuthResponse.AuthData.builder().token("backend.jwt").build())
                .build();

        when(authService.loginWithSupabase(any(SupabaseLoginRequest.class))).thenReturn(authResponse);

        ResponseEntity<AuthResponse> response = authController.supabaseLogin(request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().isSuccess());
    }

    @Test
    @DisplayName("getProfile returns 200 OK with UserResponse for authenticated user")
    void testGetProfile_success() {
        when(authentication.getPrincipal()).thenReturn(testUserId.toString());

        UserResponse userResponse = UserResponse.builder()
                .id(testUserId)
                .email("user@servio.lk")
                .fullName("Alex Customer")
                .role("USER")
                .build();

        when(authService.getProfileByUuid(testUserId.toString())).thenReturn(userResponse);

        ResponseEntity<ApiResponse<UserResponse>> response = authController.getProfile(authentication);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("user@servio.lk", response.getBody().getData().getEmail());
    }

    @Test
    @DisplayName("deleteProfile returns 200 OK and triggers Supabase cleanup")
    void testDeleteProfile_success() {
        when(authentication.getPrincipal()).thenReturn(testUserId.toString());
        when(authService.deleteCustomer(testUserId)).thenReturn("supabase-uuid-123");

        ResponseEntity<ApiResponse<String>> response = authController.deleteProfile(authentication);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().isSuccess());
        verify(supabaseAdminService, times(1)).deleteUser("supabase-uuid-123");
    }

    @Test
    @DisplayName("deleteProfile returns 409 Conflict if active appointments block deletion")
    void testDeleteProfile_conflict() {
        when(authentication.getPrincipal()).thenReturn(testUserId.toString());
        when(authService.deleteCustomer(testUserId))
                .thenThrow(new IllegalStateException("Cannot delete user with active appointments."));

        ResponseEntity<ApiResponse<String>> response = authController.deleteProfile(authentication);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertFalse(response.getBody().isSuccess());
        verify(supabaseAdminService, never()).deleteUser(anyString());
    }

    @Test
    @DisplayName("health endpoint returns 200 OK with server and database status")
    void testHealth_success() {
        ResponseEntity<ApiResponse<Map<String, String>>> response = authController.health();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("Server is running", response.getBody().getData().get("status"));
        assertEquals("Connected", response.getBody().getData().get("database"));
    }

    @Test
    @DisplayName("mechanicRegistration returns 200 OK for active mechanic")
    void testMechanicRegistration_found() {
        MechanicRegistrationLookupDto dto = MechanicRegistrationLookupDto.builder()
                .email("mechanic@servio.lk")
                .isActive(true)
                .build();

        when(mechanicService.findRegistrationByEmail("mechanic@servio.lk")).thenReturn(Optional.of(dto));

        ResponseEntity<ApiResponse<MechanicRegistrationLookupDto>> response =
                authController.mechanicRegistration("mechanic@servio.lk");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().isSuccess());
    }

    @Test
    @DisplayName("mechanicRegistration returns 403 Forbidden for inactive mechanic")
    void testMechanicRegistration_inactive() {
        MechanicRegistrationLookupDto dto = MechanicRegistrationLookupDto.builder()
                .email("inactive@servio.lk")
                .isActive(false)
                .build();

        when(mechanicService.findRegistrationByEmail("inactive@servio.lk")).thenReturn(Optional.of(dto));

        ResponseEntity<ApiResponse<MechanicRegistrationLookupDto>> response =
                authController.mechanicRegistration("inactive@servio.lk");

        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
        assertFalse(response.getBody().isSuccess());
    }
}
