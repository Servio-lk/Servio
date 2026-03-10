package com.servio.service;

import com.servio.dto.NotificationDto;
import com.servio.dto.NotificationRequest;
import com.servio.entity.Notification;
import com.servio.entity.User;
import com.servio.repository.NotificationRepository;
import com.servio.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    @Lazy
    private final AppointmentEventPublisher eventPublisher;

    @Transactional
    public NotificationDto createNotification(NotificationRequest request) {
        User user = userRepository.findById(request.getUserId())
            .orElseThrow(() -> new RuntimeException("User not found with id: " + request.getUserId()));

        Notification notification = Notification.builder()
            .user(user)
            .title(request.getTitle())
            .message(request.getMessage())
            .type(request.getType())
            .isRead(false)
            .build();

        notification = notificationRepository.save(notification);
        NotificationDto dto = convertToDto(notification);

        // Push real-time notification via WebSocket
        eventPublisher.publishNotification(request.getUserId(), dto);

        return dto;
    }
    
    @Transactional
    public void createAppointmentNotification(Long userId, String appointmentDetails) {
        NotificationRequest request = NotificationRequest.builder()
            .userId(userId)
            .title("Appointment Confirmation")
            .message("Your appointment has been confirmed: " + appointmentDetails)
            .type("APPOINTMENT")
            .build();
        createNotification(request);
    }
    
    @Transactional
    public void createPaymentNotification(Long userId, String paymentDetails) {
        NotificationRequest request = NotificationRequest.builder()
            .userId(userId)
            .title("Payment Received")
            .message("Payment received: " + paymentDetails)
            .type("PAYMENT")
            .build();
        createNotification(request);
    }
    
    @Transactional
    public void createReminderNotification(Long userId, String reminderDetails) {
        NotificationRequest request = NotificationRequest.builder()
            .userId(userId)
            .title("Service Reminder")
            .message(reminderDetails)
            .type("REMINDER")
            .build();
        createNotification(request);
    }
    
    public List<NotificationDto> getUserNotifications(Long userId) {
        return notificationRepository.findUserNotificationsOrderByDate(userId).stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<NotificationDto> getUnreadNotifications(Long userId) {
        return notificationRepository.findUnreadNotifications(userId).stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public Long getUnreadCount(Long userId) {
        return notificationRepository.countUnreadNotifications(userId);
    }
    
    public NotificationDto getNotificationById(Long id) {
        Notification notification = notificationRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Notification not found with id: " + id));
        return convertToDto(notification);
    }
    
    @Transactional
    public NotificationDto markAsRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new RuntimeException("Notification not found with id: " + notificationId));
        
        notification.setIsRead(true);
        notification = notificationRepository.save(notification);
        return convertToDto(notification);
    }
    
    @Transactional
    public void markAllAsRead(Long userId) {
        List<Notification> notifications = notificationRepository.findUnreadNotifications(userId);
        notifications.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(notifications);
    }
    
    @Transactional
    public void deleteNotification(Long id) {
        if (!notificationRepository.existsById(id)) {
            throw new RuntimeException("Notification not found with id: " + id);
        }
        notificationRepository.deleteById(id);
    }
    
    @Transactional
    public void deleteOldNotifications(Long userId, int daysOld) {
        List<Notification> notifications = notificationRepository.findUserNotificationsOrderByDate(userId);
        notifications.stream()
            .filter(n -> n.getCreatedAt().isBefore(
                java.time.LocalDateTime.now().minusDays(daysOld)))
            .forEach(n -> notificationRepository.delete(n));
    }
    
    private NotificationDto convertToDto(Notification notification) {
        return NotificationDto.builder()
            .id(notification.getId())
            .userId(notification.getUser().getId())
            .userName(notification.getUser().getFullName())
            .title(notification.getTitle())
            .message(notification.getMessage())
            .type(notification.getType())
            .isRead(notification.getIsRead())
            .createdAt(notification.getCreatedAt())
            .build();
    }
}
