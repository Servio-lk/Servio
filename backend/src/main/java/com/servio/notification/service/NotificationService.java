package com.servio.notification.service;

import com.servio.payment.entity.Payment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.booking.entity.Appointment;

import com.servio.notification.dto.NotificationDto;
import com.servio.notification.dto.NotificationRequest;
import com.servio.notification.entity.Notification;
import com.servio.auth.entity.User;
import com.servio.notification.repository.NotificationRepository;
import com.servio.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Lazy;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import com.servio.common.event.AppointmentCreatedEvent;
import com.servio.common.event.PaymentCompletedEvent;
import com.servio.common.event.RepairStatusChangedEvent;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
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
        try {
            eventPublisher.publishNotification(request.getUserId(), dto);
        } catch (Exception e) {
            log.error("Failed to broadcast WebSocket notification to user {}: {}", request.getUserId(), e.getMessage());
        }

        return dto;
    }
    
    @Transactional
    public void createAppointmentNotification(UUID userId, String appointmentDetails) {
        NotificationRequest request = NotificationRequest.builder()
            .userId(userId)
            .title("Appointment Confirmation")
            .message("Your appointment has been confirmed: " + appointmentDetails)
            .type("APPOINTMENT")
            .build();
        createNotification(request);
    }
    
    @Transactional
    public void createPaymentNotification(UUID userId, String paymentDetails) {
        NotificationRequest request = NotificationRequest.builder()
            .userId(userId)
            .title("Payment Received")
            .message("Payment received: " + paymentDetails)
            .type("PAYMENT")
            .build();
        createNotification(request);
    }
    
    @Transactional
    public void createReminderNotification(UUID userId, String reminderDetails) {
        NotificationRequest request = NotificationRequest.builder()
            .userId(userId)
            .title("Service Reminder")
            .message(reminderDetails)
            .type("REMINDER")
            .build();
        createNotification(request);
    }
    
    @Async("taskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onAppointmentCreated(AppointmentCreatedEvent event) {
        try {
            log.info("Handling AppointmentCreatedEvent asynchronously: appointmentId={}, userId={}", 
                    event.getAppointmentId(), event.getUserId());
            if (event.getUserId() != null) {
                String details = event.getServiceType() + " on " + event.getAppointmentDate();
                createAppointmentNotification(event.getUserId(), details);
            }
        } catch (Exception e) {
            log.error("Failed to process AppointmentCreatedEvent for appointmentId={}: {}", 
                    event.getAppointmentId(), e.getMessage(), e);
        }
    }

    @Async("taskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onPaymentCompleted(PaymentCompletedEvent event) {
        try {
            log.info("Handling PaymentCompletedEvent asynchronously: appointmentId={}, userId={}, amount={}, method={}", 
                    event.getAppointmentId(), event.getUserId(), event.getAmount(), event.getPaymentMethod());
            if (event.getUserId() != null) {
                String amountStr = (event.getAmount() != null) ? String.format("%.2f", event.getAmount()) : "0.00";
                String details = "LKR " + amountStr + " via " + event.getPaymentMethod();
                createPaymentNotification(event.getUserId(), details);
            }
        } catch (Exception e) {
            log.error("Failed to process PaymentCompletedEvent for appointmentId={}: {}", 
                    event.getAppointmentId(), e.getMessage(), e);
        }
    }

    @Async("taskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onRepairStatusChanged(RepairStatusChangedEvent event) {
        try {
            log.info("Handling RepairStatusChangedEvent asynchronously: appointmentId={}, userId={}, status={}", 
                    event.getAppointmentId(), event.getUserId(), event.getNewStatus());
            if (event.getUserId() != null) {
                NotificationRequest request = NotificationRequest.builder()
                    .userId(event.getUserId())
                    .title("Repair Status Update")
                    .message(event.getMessage())
                    .type("REPAIR_UPDATE")
                    .build();
                createNotification(request);
            }
        } catch (Exception e) {
            log.error("Failed to process RepairStatusChangedEvent for appointmentId={}: {}", 
                    event.getAppointmentId(), e.getMessage(), e);
        }
    }
    
    public List<NotificationDto> getUserNotifications(UUID userId) {
        return notificationRepository.findUserNotificationsOrderByDate(userId).stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<NotificationDto> getUnreadNotifications(UUID userId) {
        return notificationRepository.findUnreadNotifications(userId).stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public Long getUnreadCount(UUID userId) {
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
    public void markAllAsRead(UUID userId) {
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
    public void deleteOldNotifications(UUID userId, int daysOld) {
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
