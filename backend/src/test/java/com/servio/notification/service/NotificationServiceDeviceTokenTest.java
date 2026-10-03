package com.servio.notification.service;

import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.notification.dto.DeviceTokenRequest;
import com.servio.notification.dto.NotificationDto;
import com.servio.notification.entity.DeviceToken;
import com.servio.notification.repository.DeviceTokenRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceDeviceTokenTest {

    @Mock
    private DeviceTokenRepository deviceTokenRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private NotificationService notificationService;

    private User testUser;
    private UUID userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        testUser = User.builder()
                .id(userId)
                .email("customer@example.com")
                .fullName("Test Customer")
                .passwordHash("secret")
                .role(Role.USER)
                .build();
    }

    @Test
    @DisplayName("registerDeviceToken saves new DeviceToken when token is not present")
    void testRegisterNewDeviceToken() {
        DeviceTokenRequest request = DeviceTokenRequest.builder()
                .token("fcm-test-token-123")
                .deviceType("ANDROID")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(deviceTokenRepository.findByToken("fcm-test-token-123")).thenReturn(Optional.empty());

        notificationService.registerDeviceToken(userId, request);

        ArgumentCaptor<DeviceToken> captor = ArgumentCaptor.forClass(DeviceToken.class);
        verify(deviceTokenRepository).save(captor.capture());
        DeviceToken saved = captor.getValue();
        assertThat(saved.getToken()).isEqualTo("fcm-test-token-123");
        assertThat(saved.getDeviceType()).isEqualTo("ANDROID");
        assertThat(saved.getUser()).isEqualTo(testUser);
    }

    @Test
    @DisplayName("registerDeviceToken updates existing DeviceToken if already registered")
    void testUpdateExistingDeviceToken() {
        DeviceToken existing = DeviceToken.builder()
                .id(100L)
                .token("fcm-test-token-123")
                .deviceType("IOS")
                .user(testUser)
                .build();

        DeviceTokenRequest request = DeviceTokenRequest.builder()
                .token("fcm-test-token-123")
                .deviceType("ANDROID")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(deviceTokenRepository.findByToken("fcm-test-token-123")).thenReturn(Optional.of(existing));

        notificationService.registerDeviceToken(userId, request);

        verify(deviceTokenRepository).save(existing);
        assertThat(existing.getDeviceType()).isEqualTo("ANDROID");
    }

    @Test
    @DisplayName("unregisterDeviceToken deletes token from database")
    void testUnregisterDeviceToken() {
        notificationService.unregisterDeviceToken("fcm-test-token-123");

        verify(deviceTokenRepository).deleteByToken("fcm-test-token-123");
    }

    @Test
    @DisplayName("FcmNotificationChannel handles deliver safely when uninitialized")
    void testFcmChannelHandlesUninitializedGracefully() {
        FcmNotificationChannel fcmChannel = new FcmNotificationChannel(deviceTokenRepository);
        // Do not call init() so initialized is false

        NotificationDto dto = NotificationDto.builder()
                .id(1L)
                .userId(userId)
                .title("Test Title")
                .message("Test Message")
                .build();

        // Should return cleanly without throwing any exception
        fcmChannel.deliver(dto);
        verifyNoInteractions(deviceTokenRepository);
    }
}
