package com.servio.notification.controller;

import com.servio.notification.entity.Notification;
import com.servio.notification.dto.NotificationRequest;
import com.servio.notification.dto.NotificationDto;
import com.servio.common.dto.ApiResponse;

import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.notification.dto.DeviceTokenRequest;
import com.servio.notification.service.NotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {
    
    private final NotificationService notificationService;
    private final UserRepository userRepository;
    
    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN')")
    public ResponseEntity<ApiResponse<NotificationDto>> createNotification(
        @RequestBody NotificationRequest request
    ) {
        NotificationDto notification = notificationService.createNotification(request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.<NotificationDto>builder()
                .success(true)
                .message("Notification created successfully")
                .data(notification)
                .build());
    }
    
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasAuthority('ADMIN') or authentication.name == #userId.toString()")
    public ResponseEntity<ApiResponse<List<NotificationDto>>> getUserNotifications(
        @PathVariable UUID userId
    ) {
        List<NotificationDto> notifications = notificationService.getUserNotifications(userId);
        return ResponseEntity.ok(ApiResponse.<List<NotificationDto>>builder()
            .success(true)
            .message("Notifications retrieved successfully")
            .data(notifications)
            .build());
    }
    
    @GetMapping("/user/{userId}/unread")
    @PreAuthorize("hasAuthority('ADMIN') or authentication.name == #userId.toString()")
    public ResponseEntity<ApiResponse<List<NotificationDto>>> getUnreadNotifications(
        @PathVariable UUID userId
    ) {
        List<NotificationDto> notifications = notificationService.getUnreadNotifications(userId);
        return ResponseEntity.ok(ApiResponse.<List<NotificationDto>>builder()
            .success(true)
            .message("Unread notifications retrieved successfully")
            .data(notifications)
            .build());
    }
    
    @GetMapping("/user/{userId}/unread/count")
    @PreAuthorize("hasAuthority('ADMIN') or authentication.name == #userId.toString()")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount(@PathVariable UUID userId) {
        Long count = notificationService.getUnreadCount(userId);
        return ResponseEntity.ok(ApiResponse.<Long>builder()
            .success(true)
            .message("Unread count retrieved successfully")
            .data(count)
            .build());
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN') or @ownershipSecurity.isNotificationOwner(authentication, #id)")
    public ResponseEntity<ApiResponse<NotificationDto>> getNotificationById(@PathVariable Long id) {
        NotificationDto notification = notificationService.getNotificationById(id);
        return ResponseEntity.ok(ApiResponse.<NotificationDto>builder()
            .success(true)
            .message("Notification retrieved successfully")
            .data(notification)
            .build());
    }
    
    @PatchMapping("/{id}/read")
    @PreAuthorize("hasAuthority('ADMIN') or @ownershipSecurity.isNotificationOwner(authentication, #id)")
    public ResponseEntity<ApiResponse<NotificationDto>> markAsRead(@PathVariable Long id) {
        NotificationDto notification = notificationService.markAsRead(id);
        return ResponseEntity.ok(ApiResponse.<NotificationDto>builder()
            .success(true)
            .message("Notification marked as read")
            .data(notification)
            .build());
    }
    
    @DeleteMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<Void>> clearAll(@PathVariable UUID userId) {
        notificationService.clearAll(userId);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Notifications cleared")
            .data(null)
            .build());
    }

    @PatchMapping("/user/{userId}/read-all")
    @PreAuthorize("hasAuthority('ADMIN') or authentication.name == #userId.toString()")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(@PathVariable UUID userId) {
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("All notifications marked as read")
            .data(null)
            .build());
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN') or @ownershipSecurity.isNotificationOwner(authentication, #id)")
    public ResponseEntity<ApiResponse<Void>> deleteNotification(@PathVariable Long id) {
        notificationService.deleteNotification(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Notification deleted successfully")
            .data(null)
            .build());
    }
    
    @DeleteMapping("/user/{userId}/old")
    @PreAuthorize("hasAuthority('ADMIN') or authentication.name == #userId.toString()")
    public ResponseEntity<ApiResponse<Void>> deleteOldNotifications(
        @PathVariable UUID userId,
        @RequestParam(defaultValue = "30") int daysOld
    ) {
        notificationService.deleteOldNotifications(userId, daysOld);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Old notifications deleted successfully")
            .data(null)
            .build());
    }

    @PostMapping("/devices")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> registerDevice(
        @Valid @RequestBody DeviceTokenRequest request,
        Authentication authentication
    ) {
        User user = resolveUser(authentication);
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.<Void>builder()
                    .success(false)
                    .message("User not authenticated")
                    .build());
        }
        notificationService.registerDeviceToken(user.getId(), request);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Device token registered successfully")
            .build());
    }

    @DeleteMapping("/devices")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> unregisterDevice(
        @RequestParam String token
    ) {
        notificationService.unregisterDeviceToken(token);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Device token unregistered successfully")
            .build());
    }

    private User resolveUser(Authentication auth) {
        if (auth == null || auth.getName() == null) return null;
        String name = auth.getName();
        try {
            return userRepository.findById(UUID.fromString(name)).orElse(null);
        } catch (IllegalArgumentException e) {
            return userRepository.findByEmail(name).orElse(null);
        }
    }
}
