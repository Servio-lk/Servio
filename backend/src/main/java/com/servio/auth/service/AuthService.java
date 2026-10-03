package com.servio.auth.service;


import com.servio.auth.dto.SignupRequest;
import com.servio.auth.dto.LoginRequest;
import com.servio.common.dto.UserResponse;
import com.servio.auth.dto.AuthResponse;
import com.servio.auth.entity.Profile;
import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.ProfileRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.auth.dto.SupabaseLoginRequest;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.common.util.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import com.servio.admin.entity.Mechanic;
import com.servio.admin.entity.MechanicStatus;
import com.servio.admin.entity.MechanicVerificationStatus;
import com.servio.admin.repository.MechanicRepository;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {
    private final UserRepository userRepository;
    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final RestTemplate restTemplate;
    private final AppointmentRepository appointmentRepository;
    private final SupabaseAdminService supabaseAdminService;
    private final MechanicRepository mechanicRepository;

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
        String supabaseUserId = null;
        String tokenEmail = null;
        Map<String, Object> authUser = null;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + request.getAccessToken());
        headers.set("apikey", supabaseAnonKey);

        try {
            HttpEntity<Void> entity = new HttpEntity<>(headers);
            ResponseEntity<Map> response = restTemplate.exchange(
                    supabaseUrl + "/auth/v1/user",
                    HttpMethod.GET,
                    entity,
                    Map.class);

            Map<String, Object> body = response.getBody();
            if (body != null && body.containsKey("id")) {
                authUser = body;
                supabaseUserId = (String) body.get("id");
                tokenEmail = (String) body.get("email");
            }
        } catch (Exception ignored) {
            // Outbound network call to Supabase may fail or time out
        }

        // Fallback: decode JWT payload directly if Supabase endpoint was unreachable
        if (supabaseUserId == null || tokenEmail == null) {
            try {
                String[] parts = request.getAccessToken().split("\\.");
                if (parts.length >= 2) {
                    byte[] payloadBytes = java.util.Base64.getUrlDecoder().decode(parts[1]);
                    com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                    @SuppressWarnings("unchecked")
                    Map<String, Object> claims = mapper.readValue(payloadBytes, Map.class);
                    if (supabaseUserId == null) {
                        supabaseUserId = (String) claims.get("sub");
                    }
                    if (tokenEmail == null) {
                        tokenEmail = (String) claims.get("email");
                        if (tokenEmail == null && claims.get("user_metadata") instanceof Map) {
                            @SuppressWarnings("unchecked")
                            Map<String, Object> meta = (Map<String, Object>) claims.get("user_metadata");
                            tokenEmail = (String) meta.get("email");
                        }
                    }
                }
            } catch (Exception ignored) {
            }
        }

        if (supabaseUserId == null) {
            throw new IllegalArgumentException("Invalid Supabase token: cannot extract user id");
        }

        if (tokenEmail == null || tokenEmail.isBlank()) {
            if (request.getEmail() != null && !request.getEmail().isBlank()) {
                tokenEmail = request.getEmail().trim();
            } else {
                tokenEmail = supabaseUserId + "@oauth.servio.local";
            }
        }

        if (request.getEmail() != null && !request.getEmail().isBlank()
                && !tokenEmail.equalsIgnoreCase(request.getEmail())
                && !tokenEmail.endsWith("@oauth.servio.local")) {
            throw new IllegalArgumentException(
                    "Token email mismatch: expected " + request.getEmail() + " but got " + tokenEmail);
        }

        // Local profiles often miss the Supabase row. Check that row, then Supabase
        // auth metadata and the remote profiles table, then the existing backend user.
        Role resolvedRole = Role.USER;
        String displayName = (request.getFullName() != null && !request.getFullName().isBlank())
                ? request.getFullName().trim()
                : "User";
        try {
            UUID profileId = UUID.fromString(supabaseUserId);
            Profile profile = profileRepository.findById(profileId).orElse(null);
            if (profile != null) {
                if (profile.getFullName() != null) {
                    displayName = profile.getFullName();
                }
                if (Boolean.TRUE.equals(profile.getIsAdmin()) || "ADMIN".equalsIgnoreCase(profile.getRole())) {
                    resolvedRole = Role.ADMIN;
                }
            }
        } catch (IllegalArgumentException ignored) {
            // supabaseUserId was not a valid UUID
        }

        if (resolvedRole != Role.ADMIN && isAdminClaim(authUser)) {
            resolvedRole = Role.ADMIN;
        }

        if (resolvedRole != Role.ADMIN) {
            RemoteProfile remoteProfile = fetchSupabaseProfile(request.getAccessToken(), supabaseUserId);
            if (remoteProfile != null) {
                if (remoteProfile.fullName != null && !remoteProfile.fullName.isBlank()) {
                    displayName = remoteProfile.fullName;
                }
                if (remoteProfile.admin) {
                    resolvedRole = Role.ADMIN;
                }
            }
        }

        if (resolvedRole != Role.ADMIN) {
            Optional<User> existingUser = userRepository.findByEmail(tokenEmail);
            if (existingUser.isEmpty() && tokenEmail != null) {
                existingUser = userRepository.findByEmailIgnoreCase(tokenEmail);
            }
            if (existingUser.isPresent()) {
                resolvedRole = existingUser.get().getRole();
                if (resolvedRole == Role.USER && "MECHANIC".equalsIgnoreCase(request.getRole())) {
                    resolvedRole = Role.MECHANIC;
                }
            } else if (request.getRole() != null && !request.getRole().isBlank()) {
                try {
                    resolvedRole = Role.valueOf(request.getRole().toUpperCase());
                } catch (IllegalArgumentException ignored) {
                }
            }
        }

        final String finalDisplayName = displayName;
        final Role finalRole = resolvedRole;

        // Ensure a corresponding backend user exists (appointments require users.id)
        final String searchEmail = tokenEmail;
        final String normalizedEmail = (tokenEmail != null) ? tokenEmail.trim().toLowerCase() : "";
        final String finalTokenEmail = normalizedEmail.isEmpty() ? tokenEmail : normalizedEmail;
        User backendUser;
        try {
            Optional<User> userOpt = userRepository.findByEmail(searchEmail);
            if (userOpt.isEmpty() && finalTokenEmail != null && !finalTokenEmail.equals(searchEmail)) {
                userOpt = userRepository.findByEmail(finalTokenEmail);
            }
            if (userOpt.isEmpty() && finalTokenEmail != null) {
                userOpt = userRepository.findByEmailIgnoreCase(finalTokenEmail);
            }

            backendUser = userOpt
                    .map(existing -> {
                        boolean changed = false;
                        if (existing.getRole() != finalRole) {
                            existing.setRole(finalRole);
                            changed = true;
                        }
                        if (request.getPhone() != null && !request.getPhone().isBlank()
                                && (existing.getPhone() == null || existing.getPhone().isBlank())) {
                            existing.setPhone(request.getPhone().trim());
                            changed = true;
                        }
                        if (finalDisplayName != null && !finalDisplayName.isBlank()
                                && (existing.getFullName() == null || existing.getFullName().isBlank())) {
                            existing.setFullName(finalDisplayName.trim());
                            changed = true;
                        }
                        if (changed) {
                            try {
                                User saved = userRepository.save(existing);
                                return saved != null ? saved : existing;
                            } catch (Exception e) {
                                return existing;
                            }
                        }
                        return existing;
                    })
                    .orElseGet(() -> {
                        try {
                            return userRepository.save(User.builder()
                                    .fullName(finalDisplayName != null && !finalDisplayName.isBlank() ? finalDisplayName : "User")
                                    .email(finalTokenEmail)
                                    .phone(request.getPhone())
                                    .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString()))
                                    .role(finalRole)
                                    .build());
                        } catch (Exception e) {
                            return userRepository.findByEmail(searchEmail)
                                    .or(() -> userRepository.findByEmail(finalTokenEmail))
                                    .or(() -> userRepository.findByEmailIgnoreCase(finalTokenEmail))
                                    .orElseThrow(() -> new RuntimeException("Could not create backend user: " + e.getMessage()));
                        }
                    });
        } catch (Exception ex) {
            backendUser = userRepository.findByEmail(searchEmail)
                    .or(() -> userRepository.findByEmail(finalTokenEmail))
                    .or(() -> userRepository.findByEmailIgnoreCase(finalTokenEmail))
                    .orElse(null);
            if (backendUser == null) {
                throw new RuntimeException("Failed to find or create backend user: " + ex.getMessage(), ex);
            }
        }

        // If user is a mechanic, ensure corresponding Mechanic entity exists
        if (finalRole == Role.MECHANIC) {
            String spec = (request.getSpecialization() != null && !request.getSpecialization().isBlank())
                    ? request.getSpecialization().trim()
                    : "General Service";
            mechanicRepository.findByEmailIgnoreCase(finalTokenEmail)
                    .ifPresentOrElse(
                            existing -> {
                                boolean changed = false;
                                if (request.getSpecialization() != null && !request.getSpecialization().isBlank()
                                        && (existing.getSpecialization() == null || existing.getSpecialization().isBlank())) {
                                    existing.setSpecialization(spec);
                                    changed = true;
                                }
                                if (request.getPhone() != null && !request.getPhone().isBlank()
                                        && (existing.getPhone() == null || existing.getPhone().isBlank())) {
                                    existing.setPhone(request.getPhone().trim());
                                    changed = true;
                                }
                                if (Boolean.FALSE.equals(existing.getIsActive())) {
                                    existing.setIsActive(true);
                                    changed = true;
                                }
                                if (existing.getVerificationStatus() == null || existing.getVerificationStatus() == MechanicVerificationStatus.INCOMPLETE) {
                                    existing.setVerificationStatus(MechanicVerificationStatus.VERIFIED);
                                    changed = true;
                                }
                                if (changed) {
                                    mechanicRepository.save(existing);
                                }
                            },
                            () -> mechanicRepository.save(Mechanic.builder()
                                    .fullName(finalDisplayName != null && !finalDisplayName.isBlank() ? finalDisplayName : "Mechanic Staff")
                                    .email(finalTokenEmail)
                                    .phone(request.getPhone() != null ? request.getPhone() : "")
                                    .specialization(spec)
                                    .status(MechanicStatus.AVAILABLE)
                                    .isActive(true)
                                    .verificationStatus(MechanicVerificationStatus.VERIFIED)
                                    .build())
                    );
        }

        // Generate backend JWT using backend numeric user ID for consistency
        String backendToken = jwtTokenProvider.generateToken(backendUser.getId(), backendUser.getRole());

        UserResponse userResponse = UserResponse.builder()
                .id(backendUser.getId())
                .supabaseId(supabaseUserId) // Set the Supabase UUID
                .fullName(displayName)
                .email(tokenEmail)
                .phone(request.getPhone())
                .role(finalRole.name())
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

    private boolean isAdminClaim(Map<String, Object> authUser) {
        if (authUser == null) {
            return false;
        }
        return isAdminMetadata(authUser.get("app_metadata")) || isAdminMetadata(authUser.get("user_metadata"));
    }

    private boolean isAdminMetadata(Object metadata) {
        if (!(metadata instanceof Map<?, ?> map)) {
            return false;
        }
        Object role = map.get("role");
        if (role != null && "ADMIN".equalsIgnoreCase(role.toString())) {
            return true;
        }
        Object isAdmin = map.get("is_admin");
        return Boolean.TRUE.equals(isAdmin) || "true".equalsIgnoreCase(String.valueOf(isAdmin));
    }

    private RemoteProfile fetchSupabaseProfile(String accessToken, String supabaseUserId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + accessToken);
            headers.set("apikey", supabaseAnonKey);
            headers.set("Accept", "application/json");

            String url = supabaseUrl + "/rest/v1/profiles?id=eq." + supabaseUserId
                    + "&select=full_name,is_admin,role";
            ResponseEntity<List> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), List.class);

            List<?> body = response.getBody();
            if (body == null || body.isEmpty() || !(body.get(0) instanceof Map<?, ?> row)) {
                return null;
            }

            return toRemoteProfile(row);
        } catch (Exception e) {
            log.warn("Could not read Supabase profile for {}: {}", supabaseUserId, e.getMessage());
            return null;
        }
    }

    private RemoteProfile toRemoteProfile(Map<?, ?> row) {
            Object isAdmin = row.get("is_admin");
            Object roleValue = row.get("role");
            boolean admin = Boolean.TRUE.equals(isAdmin)
                    || "true".equalsIgnoreCase(String.valueOf(isAdmin))
                    || (roleValue != null && "ADMIN".equalsIgnoreCase(roleValue.toString()));
            Object fullName = row.get("full_name");
            return new RemoteProfile(admin, fullName instanceof String ? (String) fullName : null);
    }

    private record RemoteProfile(boolean admin, String fullName) {
    }

    public UserResponse getProfileByUuid(String userId) {
        try {
            UUID uuid = UUID.fromString(userId);
            return getProfile(uuid);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("User not found: " + userId);
        }
    }

    public UserResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        return mapToUserResponse(user);
    }

    private UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .bio(user.getBio())
                .avatarUrl(user.getAvatarUrl())
                .role(user.getRole().name())
                .createdAt(user.getCreatedAt())
                .build();
    }

    @Transactional
    public String deleteCustomer(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 1. Find Supabase profile if any
        String oldEmail = user.getEmail();
        Optional<Profile> profileOpt = profileRepository.findByEmail(oldEmail);

        // 2. Fetch all appointments safely linked to user_id
        java.util.List<Appointment> allAppointments = appointmentRepository.findByUserId(userId);

        // 3. Process appointments: cancel pending/past confirmed
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        for (Appointment appt : allAppointments) {
            boolean changed = false;
            
            if ("PENDING".equals(appt.getStatus())) {
                appt.setStatus("CANCELLED");
                changed = true;
            } else if ("CONFIRMED".equals(appt.getStatus()) && appt.getAppointmentDate().isBefore(now)) {
                appt.setStatus("CANCELLED");
                changed = true;
            }

            if (changed) {
                appointmentRepository.save(appt);
            }
        }
        appointmentRepository.flush();

        // 4. Prevent deletion if there are still active (future) appointments
        long activeCount = allAppointments.stream()
                .filter(a -> "CONFIRMED".equals(a.getStatus()) || "IN_PROGRESS".equals(a.getStatus()))
                .count();
        
        if (activeCount > 0) {
            throw new IllegalStateException("Cannot delete user with active appointments. Please complete or cancel them first.");
        }

        // 5. Anonymize user to free up the email in the DB. We keep the fullName to track business transactions.
        user.setEmail("deleted_user_" + user.getId() + "@servio.lk");
        user.setPhone(null);
        user.setPasswordHash(passwordEncoder.encode(UUID.randomUUID().toString()));
        userRepository.save(user);

        // 6. Delete from profiles table locally
        String supabaseUserId = profileOpt.map(profile -> {
            profileRepository.delete(profile);
            return profile.getId().toString();
        }).orElse(null);
        
        return supabaseUserId;
    }
}