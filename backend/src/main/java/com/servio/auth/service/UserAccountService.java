package com.servio.auth.service;

import com.servio.auth.dto.ChangeEmailRequest;
import com.servio.auth.dto.ChangePasswordRequest;
import com.servio.auth.dto.NotificationPreferenceResponse;
import com.servio.auth.dto.UpdatePreferencesRequest;
import com.servio.auth.dto.UpdateProfileRequest;
import com.servio.auth.entity.User;
import com.servio.auth.entity.UserNotificationPreference;
import com.servio.auth.repository.UserNotificationPreferenceRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.common.dto.UserResponse;
import com.servio.common.event.AccountUpdatedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class UserAccountService {
    private static final Pattern STRONG_PASSWORD =
            Pattern.compile("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$");
    private static final String PASSWORD_MISMATCH =
            "Current password is incorrect. If you signed in with Google or an email link, use Forgot password to set one.";

    private final UserRepository userRepository;
    private final UserNotificationPreferenceRepository preferenceRepository;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public UserResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = loadUser(userId);
        user.setFullName(request.getFullName().trim());
        user.setPhone(blankToNull(request.getPhone()));
        user.setBio(blankToNull(request.getBio()));
        user.setAvatarUrl(blankToNull(request.getAvatarUrl()));
        userRepository.save(user);
        eventPublisher.publishEvent(new AccountUpdatedEvent(this, userId, "Your profile details were updated"));
        return toResponse(user);
    }

    @Transactional
    public void changePassword(UUID userId, ChangePasswordRequest request) {
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("New password and confirmation do not match");
        }
        if (!STRONG_PASSWORD.matcher(request.getNewPassword()).matches()) {
            throw new IllegalArgumentException(
                    "Password must be at least 8 characters and include uppercase, lowercase, and a number");
        }
        User user = loadUser(userId);
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException(PASSWORD_MISMATCH);
        }
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        eventPublisher.publishEvent(new AccountUpdatedEvent(this, userId, "Your password was changed"));
    }

    @Transactional
    public UserResponse changeEmail(UUID userId, ChangeEmailRequest request) {
        User user = loadUser(userId);
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException(PASSWORD_MISMATCH);
        }
        String email = request.getEmail().trim().toLowerCase();
        if (!email.equalsIgnoreCase(user.getEmail()) && userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email is already in use");
        }
        user.setEmail(email);
        userRepository.save(user);
        eventPublisher.publishEvent(new AccountUpdatedEvent(this, userId, "Your email was changed to " + email));
        return toResponse(user);
    }

    @Transactional
    public NotificationPreferenceResponse getPreferences(UUID userId) {
        loadUser(userId);
        return toPreferenceResponse(loadOrCreatePreferences(userId));
    }

    @Transactional
    public NotificationPreferenceResponse updatePreferences(UUID userId, UpdatePreferencesRequest request) {
        loadUser(userId);
        UserNotificationPreference prefs = loadOrCreatePreferences(userId);
        if (request.getPromotionalOffers() != null) {
            prefs.setPromotionalOffers(request.getPromotionalOffers());
        }
        if (request.getPushNotifications() != null) {
            prefs.setPushNotifications(request.getPushNotifications());
        }
        if (request.getSecurityAlerts() != null) {
            prefs.setSecurityAlerts(request.getSecurityAlerts());
        }
        preferenceRepository.save(prefs);
        eventPublisher.publishEvent(new AccountUpdatedEvent(this, userId, "Your notification preferences were updated"));
        return toPreferenceResponse(prefs);
    }

    private User loadUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    private UserNotificationPreference loadOrCreatePreferences(UUID userId) {
        return preferenceRepository.findById(userId).orElseGet(() ->
                preferenceRepository.save(UserNotificationPreference.builder().userId(userId).build()));
    }

    private NotificationPreferenceResponse toPreferenceResponse(UserNotificationPreference prefs) {
        return NotificationPreferenceResponse.builder()
                .promotionalOffers(!Boolean.FALSE.equals(prefs.getPromotionalOffers()))
                .pushNotifications(!Boolean.FALSE.equals(prefs.getPushNotifications()))
                .securityAlerts(!Boolean.FALSE.equals(prefs.getSecurityAlerts()))
                .build();
    }

    private UserResponse toResponse(User user) {
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

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
