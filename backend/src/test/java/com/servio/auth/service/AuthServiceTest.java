package com.servio.auth.service;

import com.servio.auth.dto.AuthResponse;
import com.servio.auth.dto.LoginRequest;
import com.servio.auth.dto.SignupRequest;
import com.servio.auth.dto.SupabaseLoginRequest;
import com.servio.auth.entity.Profile;
import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.ProfileRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.common.dto.UserResponse;
import com.servio.common.util.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private ProfileRepository profileRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtTokenProvider jwtTokenProvider;
    @Mock
    private RestTemplate restTemplate;
    @Mock
    private AppointmentRepository appointmentRepository;
    @Mock
    private SupabaseAdminService supabaseAdminService;

    @InjectMocks
    private AuthService authService;

    private UUID userId;
    private User testUser;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        testUser = User.builder()
                .id(userId)
                .email("john@example.com")
                .fullName("John Doe")
                .phone("+94771234567")
                .passwordHash("hashed_password_123")
                .role(Role.USER)
                .createdAt(LocalDateTime.now())
                .build();

        ReflectionTestUtils.setField(authService, "supabaseUrl", "https://mock.supabase.co");
        ReflectionTestUtils.setField(authService, "supabaseAnonKey", "mock-anon-key");
    }

    @Test
    @DisplayName("signup successfully registers user with hashed password and generates JWT")
    void testSignup_success() {
        SignupRequest request = new SignupRequest();
        request.setEmail("john@example.com");
        request.setFullName("John Doe");
        request.setPassword("plain_password");
        request.setPhone("+94771234567");

        when(userRepository.existsByEmail("john@example.com")).thenReturn(false);
        when(passwordEncoder.encode("plain_password")).thenReturn("hashed_password_123");
        when(userRepository.save(any(User.class))).thenReturn(testUser);
        when(jwtTokenProvider.generateToken(userId, Role.USER)).thenReturn("jwt.token.mock");

        AuthResponse response = authService.signup(request);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertEquals("User registered successfully", response.getMessage());
        assertNotNull(response.getData());
        assertEquals("jwt.token.mock", response.getData().getToken());
        assertEquals(userId, response.getData().getUser().getId());
        assertEquals("john@example.com", response.getData().getUser().getEmail());
        assertEquals("USER", response.getData().getUser().getRole());
        verify(userRepository, times(1)).save(any(User.class));
    }

    @Test
    @DisplayName("signup throws IllegalArgumentException when email already exists")
    void testSignup_duplicateEmail_throwsException() {
        SignupRequest request = new SignupRequest();
        request.setEmail("john@example.com");

        when(userRepository.existsByEmail("john@example.com")).thenReturn(true);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> authService.signup(request));
        assertEquals("User with this email already exists", ex.getMessage());
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("login returns token and user info on valid credentials")
    void testLogin_success() {
        LoginRequest request = new LoginRequest();
        request.setEmail("john@example.com");
        request.setPassword("plain_password");

        when(userRepository.findByEmail("john@example.com")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches("plain_password", "hashed_password_123")).thenReturn(true);
        when(jwtTokenProvider.generateToken(userId, Role.USER)).thenReturn("jwt.token.mock");

        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertEquals("Login successful", response.getMessage());
        assertEquals("jwt.token.mock", response.getData().getToken());
        assertEquals("john@example.com", response.getData().getUser().getEmail());
    }

    @Test
    @DisplayName("login throws exception on unknown email")
    void testLogin_userNotFound_throwsException() {
        LoginRequest request = new LoginRequest();
        request.setEmail("unknown@example.com");
        request.setPassword("password");

        when(userRepository.findByEmail("unknown@example.com")).thenReturn(Optional.empty());

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> authService.login(request));
        assertEquals("Invalid email or password", ex.getMessage());
    }

    @Test
    @DisplayName("login throws exception on password mismatch")
    void testLogin_wrongPassword_throwsException() {
        LoginRequest request = new LoginRequest();
        request.setEmail("john@example.com");
        request.setPassword("wrong_password");

        when(userRepository.findByEmail("john@example.com")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches("wrong_password", "hashed_password_123")).thenReturn(false);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> authService.login(request));
        assertEquals("Invalid email or password", ex.getMessage());
    }

    @Test
    @DisplayName("loginWithSupabase authenticates with valid Supabase token and maps ADMIN role")
    void testLoginWithSupabase_adminRole() {
        UUID supabaseId = UUID.randomUUID();
        SupabaseLoginRequest request = new SupabaseLoginRequest();
        request.setAccessToken("valid.supabase.token");
        request.setEmail("admin@servio.lk");
        request.setFullName("Admin User");
        request.setPhone("+94770000000");

        Map<String, Object> supabaseBody = Map.of(
                "id", supabaseId.toString(),
                "email", "admin@servio.lk"
        );

        when(restTemplate.exchange(
                eq("https://mock.supabase.co/auth/v1/user"),
                eq(HttpMethod.GET),
                any(HttpEntity.class),
                eq(Map.class)
        )).thenReturn(new ResponseEntity<>(supabaseBody, HttpStatus.OK));

        Profile adminProfile = Profile.builder()
                .id(supabaseId)
                .fullName("Admin User")
                .isAdmin(true)
                .role("ADMIN")
                .build();
        when(profileRepository.findById(supabaseId)).thenReturn(Optional.of(adminProfile));

        User adminUser = User.builder()
                .id(UUID.randomUUID())
                .email("admin@servio.lk")
                .fullName("Admin User")
                .role(Role.ADMIN)
                .createdAt(LocalDateTime.now())
                .build();
        when(userRepository.findByEmail("admin@servio.lk")).thenReturn(Optional.of(adminUser));
        when(jwtTokenProvider.generateToken(adminUser.getId(), Role.ADMIN)).thenReturn("backend.admin.jwt");

        AuthResponse response = authService.loginWithSupabase(request);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertEquals("backend.admin.jwt", response.getData().getToken());
        assertEquals("ADMIN", response.getData().getUser().getRole());
        assertEquals(supabaseId.toString(), response.getData().getUser().getSupabaseId());
    }

    @Test
    @DisplayName("loginWithSupabase throws IllegalArgumentException on token email mismatch")
    void testLoginWithSupabase_emailMismatch_throwsException() {
        SupabaseLoginRequest request = new SupabaseLoginRequest();
        request.setAccessToken("token123");
        request.setEmail("expected@servio.lk");

        Map<String, Object> supabaseBody = Map.of(
                "id", UUID.randomUUID().toString(),
                "email", "different@servio.lk"
        );

        when(restTemplate.exchange(
                anyString(),
                eq(HttpMethod.GET),
                any(HttpEntity.class),
                eq(Map.class)
        )).thenReturn(new ResponseEntity<>(supabaseBody, HttpStatus.OK));

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> authService.loginWithSupabase(request));
        assertTrue(ex.getMessage().contains("Token email mismatch"));
    }

    @Test
    @DisplayName("getProfileByUuid returns mapped UserResponse for existing user")
    void testGetProfileByUuid_success() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));

        UserResponse response = authService.getProfileByUuid(userId.toString());

        assertNotNull(response);
        assertEquals(userId, response.getId());
        assertEquals("john@example.com", response.getEmail());
        assertEquals("John Doe", response.getFullName());
        assertEquals("USER", response.getRole());
    }

    @Test
    @DisplayName("getProfileByUuid throws exception on invalid UUID string")
    void testGetProfileByUuid_invalidUuid_throwsException() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> authService.getProfileByUuid("not-a-uuid"));
        assertTrue(ex.getMessage().contains("User not found: not-a-uuid"));
    }

    @Test
    @DisplayName("deleteCustomer throws IllegalStateException when user has active appointments")
    void testDeleteCustomer_withActiveAppointments_throwsException() {
        Appointment activeAppt = Appointment.builder()
                .id(10L)
                .user(testUser)
                .appointmentDate(LocalDateTime.now().plusDays(3))
                .status("CONFIRMED")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findByUserId(userId)).thenReturn(List.of(activeAppt));

        IllegalStateException ex = assertThrows(IllegalStateException.class, () -> authService.deleteCustomer(userId));
        assertTrue(ex.getMessage().contains("Cannot delete user with active appointments"));
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("deleteCustomer anonymizes user and cancels past/pending appointments")
    void testDeleteCustomer_success() {
        Appointment pendingAppt = Appointment.builder()
                .id(11L)
                .user(testUser)
                .appointmentDate(LocalDateTime.now().plusDays(1))
                .status("PENDING")
                .build();

        Profile profile = Profile.builder()
                .id(UUID.randomUUID())
                .email("john@example.com")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(profileRepository.findByEmail("john@example.com")).thenReturn(Optional.of(profile));
        when(appointmentRepository.findByUserId(userId)).thenReturn(List.of(pendingAppt));
        when(passwordEncoder.encode(anyString())).thenReturn("anonymized_password_hash");

        String returnedSupabaseId = authService.deleteCustomer(userId);

        assertEquals(profile.getId().toString(), returnedSupabaseId);
        assertEquals("CANCELLED", pendingAppt.getStatus());
        verify(appointmentRepository, times(1)).save(pendingAppt);
        verify(profileRepository, times(1)).delete(profile);
        verify(userRepository, times(1)).save(argThat(u -> u.getEmail().startsWith("deleted_user_" + userId)));
    }
}
