package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class NotificationController {
    
    private final NotificationService notificationService;
    
    @PostMapping
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
    public ResponseEntity<ApiResponse<List<NotificationDto>>> getUserNotifications(
        @PathVariable Long userId
    ) {
        List<NotificationDto> notifications = notificationService.getUserNotifications(userId);
        return ResponseEntity.ok(ApiResponse.<List<NotificationDto>>builder()
            .success(true)
            .message("Notifications retrieved successfully")
            .data(notifications)
            .build());
    }
    
    @GetMapping("/user/{userId}/unread")
    public ResponseEntity<ApiResponse<List<NotificationDto>>> getUnreadNotifications(
        @PathVariable Long userId
    ) {
        List<NotificationDto> notifications = notificationService.getUnreadNotifications(userId);
        return ResponseEntity.ok(ApiResponse.<List<NotificationDto>>builder()
            .success(true)
            .message("Unread notifications retrieved successfully")
            .data(notifications)
            .build());
    }
    
    @GetMapping("/user/{userId}/unread/count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount(@PathVariable Long userId) {
        Long count = notificationService.getUnreadCount(userId);
        return ResponseEntity.ok(ApiResponse.<Long>builder()
            .success(true)
            .message("Unread count retrieved successfully")
            .data(count)
            .build());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<NotificationDto>> getNotificationById(@PathVariable Long id) {
        NotificationDto notification = notificationService.getNotificationById(id);
        return ResponseEntity.ok(ApiResponse.<NotificationDto>builder()
            .success(true)
            .message("Notification retrieved successfully")
            .data(notification)
            .build());
    }
    
    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<NotificationDto>> markAsRead(@PathVariable Long id) {
        NotificationDto notification = notificationService.markAsRead(id);
        return ResponseEntity.ok(ApiResponse.<NotificationDto>builder()
            .success(true)
            .message("Notification marked as read")
            .data(notification)
            .build());
    }
    
    @PatchMapping("/user/{userId}/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(@PathVariable Long userId) {
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("All notifications marked as read")
            .build());
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteNotification(@PathVariable Long id) {
        notificationService.deleteNotification(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Notification deleted successfully")
            .build());
    }
    
    @DeleteMapping("/user/{userId}/old")
    public ResponseEntity<ApiResponse<Void>> deleteOldNotifications(
        @PathVariable Long userId,
        @RequestParam(defaultValue = "30") int daysOld
    ) {
        notificationService.deleteOldNotifications(userId, daysOld);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Old notifications deleted successfully")
            .build());
    }
}
