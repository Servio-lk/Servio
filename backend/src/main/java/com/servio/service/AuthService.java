package com.servio.service;

import com.servio.dto.SignupRequest;
import com.servio.dto.LoginRequest;
import com.servio.dto.UserResponse;
import com.servio.dto.AuthResponse;
import com.servio.entity.Profile;
import com.servio.entity.Role;
import com.servio.entity.User;
import com.servio.repository.ProfileRepository;
import com.servio.repository.UserRepository;
import com.servio.dto.SupabaseLoginRequest;
import com.servio.util.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final RestTemplate restTemplate;

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.anon.key}")
    private String supabaseAnonKey;

    @Transactional
    public AuthResponse signup(SignupRequest request) {
        // Check if user already exists
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("User with this email already exists");
        }

        // Hash password
        String passwordHash = passwordEncoder.encode(request.getPassword());

        // Create new user
        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .passwordHash(passwordHash)
                .role(Role.USER)
                .build();

        User savedUser = userRepository.save(user);

        // Generate token
        String token = jwtTokenProvider.generateToken(savedUser.getId(), savedUser.getRole());

        UserResponse userResponse = mapToUserResponse(savedUser);

        return AuthResponse.builder()
                .success(true)
                .message("User registered successfully")
                .data(AuthResponse.AuthData.builder()
                        .user(userResponse)
                        .token(token)
                        .build())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        // Find user by email
        Optional<User> userOptional = userRepository.findByEmail(request.getEmail());

        if (userOptional.isEmpty()) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        User user = userOptional.get();

        // Compare password
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        // Generate token
        String token = jwtTokenProvider.generateToken(user.getId(), user.getRole());

        UserResponse userResponse = mapToUserResponse(user);

        return AuthResponse.builder()
                .success(true)
                .message("Login successful")
                .data(AuthResponse.AuthData.builder()
                        .user(userResponse)
                        .token(token)
                        .build())
                .build();
    }

    public AuthResponse loginWithSupabase(SupabaseLoginRequest request) {
        // Validate the Supabase access token via Supabase Auth API.
        // The frontend always refreshes the session before calling this endpoint,
        // so the token will always be fresh and session_not_found cannot occur.
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + request.getAccessToken());
        headers.set("apikey", supabaseAnonKey);

        HttpEntity<String> entity = new HttpEntity<>("parameters", headers);

        String supabaseUserId;
        String tokenEmail;

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    supabaseUrl + "/auth/v1/user",
                    HttpMethod.GET,
                    entity,
                    Map.class);

            Map<String, Object> body = response.getBody();
            if (body == null || !body.containsKey("id")) {
                throw new IllegalArgumentException("Invalid Supabase token: no user id in response");
            }

            supabaseUserId = (String) body.get("id");
            tokenEmail = (String) body.get("email");

            if (tokenEmail == null || !tokenEmail.equalsIgnoreCase(request.getEmail())) {
                throw new IllegalArgumentException(
                        "Token email mismatch: expected " + request.getEmail() + " but got " + tokenEmail);
            }
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("Unauthorized: Supabase token validation failed - " + e.getMessage());
        }

        // Determine role from the request (default to USER)
        Role requestedRole = "ADMIN".equalsIgnoreCase(request.getRole()) ? Role.ADMIN : Role.USER;

        // Look up profile for display name (optional - use request data as fallback)
        String displayName = request.getFullName();
        try {
            UUID profileId = UUID.fromString(supabaseUserId);
            Profile profile = profileRepository.findById(profileId).orElse(null);
            if (profile != null && profile.getFullName() != null) {
                displayName = profile.getFullName();
            }
        } catch (IllegalArgumentException ignored) {
            // supabaseUserId was not a valid UUID
        }

        final String finalDisplayName = displayName;

        // Ensure a corresponding backend user exists (appointments require users.id)
        User backendUser = userRepository.findByEmail(tokenEmail)
                .orElseGet(() -> userRepository.save(User.builder()
                .fullName(finalDisplayName)
                        .email(tokenEmail)
                        .phone(request.getPhone())
                        .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString()))
                        .role(requestedRole)
                        .build()));

        // Generate backend JWT using backend numeric user ID for consistency
        String backendToken = jwtTokenProvider.generateToken(backendUser.getId(), backendUser.getRole());

        UserResponse userResponse = UserResponse.builder()
                .id(backendUser.getId())
                .supabaseId(supabaseUserId) // Set the Supabase UUID
                .fullName(displayName)
                .email(tokenEmail)
                .phone(request.getPhone())
                .role(requestedRole.name())
                .createdAt(backendUser.getCreatedAt())
                .build();

        return AuthResponse.builder()
                .success(true)
                .message("Supabase login successful")
                .data(AuthResponse.AuthData.builder()
                        .user(userResponse)
                        .token(backendToken)
                        .build())
                .build();
    }

    public UserResponse getProfileByUuid(String userId) {
        try {
            UUID uuid = UUID.fromString(userId);
            Profile profile = profileRepository.findById(uuid).orElse(null);
            if (profile == null) {
                throw new IllegalArgumentException("User not found");
            }
            return UserResponse.builder()
                    .fullName(profile.getFullName())
                    .email(profile.getEmail())
                    .role(profile.getRole() != null ? profile.getRole() : "USER")
                    .build();
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("User not found: " + userId);
        }
    }

    public UserResponse getProfile(Long userId) {
        Optional<User> userOptional = userRepository.findById(userId);

        if (userOptional.isEmpty()) {
            throw new IllegalArgumentException("User not found");
        }

        return mapToUserResponse(userOptional.get());
    }

    private UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .createdAt(user.getCreatedAt())
                .build();
    }
}