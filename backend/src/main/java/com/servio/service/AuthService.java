package com.servio.service;

import com.servio.dto.SignupRequest;
import com.servio.dto.LoginRequest;
import com.servio.dto.UserResponse;
import com.servio.dto.AuthResponse;
import com.servio.entity.Role;
import com.servio.entity.User;
import com.servio.repository.UserRepository;
import com.servio.util.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

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
                .role(Role.ROLE_USER)
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