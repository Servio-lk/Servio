package com.servio.notification.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import com.servio.notification.dto.NotificationDto;
import com.servio.notification.entity.DeviceToken;
import com.servio.notification.repository.DeviceTokenRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class FcmNotificationChannel implements NotificationChannel {

    private final DeviceTokenRepository deviceTokenRepository;

    @Value("${firebase.service-account.path:}")
    private String serviceAccountPath;

    private boolean initialized = false;

    @PostConstruct
    public void init() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                InputStream serviceAccountStream = null;

                // 1. Check FIREBASE_CREDENTIALS_JSON environment variable (direct JSON string)
                String credentialsJson = System.getenv("FIREBASE_CREDENTIALS_JSON");
                if (credentialsJson != null && !credentialsJson.trim().isEmpty()) {
                    log.info("Initializing Firebase Admin using FIREBASE_CREDENTIALS_JSON environment variable");
                    serviceAccountStream = new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8));
                }
                // 2. Check local file path from property or env var
                else {
                    String path = serviceAccountPath;
                    if (path == null || path.trim().isEmpty()) {
                        path = System.getenv("FIREBASE_SERVICE_ACCOUNT_PATH");
                    }
                    if (path != null && !path.trim().isEmpty()) {
                        log.info("Initializing Firebase Admin from file path: {}", path);
                        serviceAccountStream = new FileInputStream(path);
                    }
                }

                // 3. Auto-discover firebase-adminsdk json in resources directory
                if (serviceAccountStream == null) {
                    java.io.File resourceDir = new java.io.File("backend/src/main/resources");
                    if (!resourceDir.exists()) {
                        resourceDir = new java.io.File("src/main/resources");
                    }
                    if (resourceDir.exists() && resourceDir.isDirectory()) {
                        java.io.File[] files = resourceDir.listFiles((dir, name) ->
                                (name.contains("firebase-adminsdk") || name.contains("firebase-service-account")) && name.endsWith(".json")
                        );
                        if (files != null && files.length > 0) {
                            log.info("Auto-discovered Firebase service account credentials: {}", files[0].getName());
                            serviceAccountStream = new FileInputStream(files[0]);
                        }
                    }
                }

                if (serviceAccountStream != null) {
                    try (InputStream in = serviceAccountStream) {
                        FirebaseOptions options = FirebaseOptions.builder()
                                .setCredentials(GoogleCredentials.fromStream(in))
                                .build();
                        FirebaseApp.initializeApp(options);
                        initialized = true;
                        log.info("Firebase Admin successfully initialized for Push Notifications (FCM).");
                    }
                } else {
                    log.info("Firebase credentials not configured (FIREBASE_CREDENTIALS_JSON or FIREBASE_SERVICE_ACCOUNT_PATH). FCM push notifications are disabled.");
                }
            } else {
                initialized = true;
                log.info("Firebase Admin was already initialized.");
            }
        } catch (Exception e) {
            log.warn("Could not initialize Firebase Admin SDK: {}. FCM push notifications will be skipped.", e.getMessage());
            initialized = false;
        }
    }

    @Override
    public void deliver(NotificationDto notification) {
        if (!initialized || notification.getUserId() == null) {
            return;
        }

        try {
            List<DeviceToken> deviceTokens = deviceTokenRepository.findByUserId(notification.getUserId());
            if (deviceTokens.isEmpty()) {
                log.debug("No FCM device tokens found for user: {}", notification.getUserId());
                return;
            }

            List<String> tokens = deviceTokens.stream().map(DeviceToken::getToken).toList();
            List<String> invalidTokens = new ArrayList<>();

            MulticastMessage message = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .setNotification(com.google.firebase.messaging.Notification.builder()
                            .setTitle(notification.getTitle() != null ? notification.getTitle() : "Servio")
                            .setBody(notification.getMessage() != null ? notification.getMessage() : "")
                            .build())
                    .putData("notificationId", notification.getId() != null ? notification.getId().toString() : "")
                    .putData("type", notification.getType() != null ? notification.getType() : "GENERAL")
                    .putData("actionUrl", notification.getActionUrl() != null ? notification.getActionUrl() : "")
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .setNotification(AndroidNotification.builder()
                                    .setChannelId("servio_high_importance")
                                    .setSound("default")
                                    .build())
                            .build())
                    .build();

            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("FCM broadcast sent to {} devices for user {}. Success: {}, Failure: {}",
                    tokens.size(), notification.getUserId(), response.getSuccessCount(), response.getFailureCount());

            if (response.getFailureCount() > 0) {
                List<SendResponse> responses = response.getResponses();
                for (int i = 0; i < responses.size(); i++) {
                    if (!responses.get(i).isSuccessful()) {
                        FirebaseMessagingException exception = responses.get(i).getException();
                        if (exception != null && (
                                exception.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED ||
                                exception.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT)) {
                            invalidTokens.add(tokens.get(i));
                        }
                    }
                }
            }

            // Prune expired or unregistered tokens
            if (!invalidTokens.isEmpty()) {
                log.info("Pruning {} stale FCM tokens for user {}", invalidTokens.size(), notification.getUserId());
                for (String deadToken : invalidTokens) {
                    try {
                        deviceTokenRepository.deleteByToken(deadToken);
                    } catch (Exception ex) {
                        log.warn("Failed to delete stale FCM token: {}", ex.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to dispatch FCM push notification to user {}: {}", notification.getUserId(), e.getMessage());
        }
    }
}
