package com.servio.notification.service;

import com.servio.payment.entity.Payment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.booking.entity.Appointment;

import com.servio.notification.dto.NotificationDto;
import com.servio.notification.dto.NotificationRequest;
import com.servio.notification.entity.Notification;
import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.notification.repository.NotificationRepository;
import com.servio.auth.entity.UserNotificationPreference;
import com.servio.auth.repository.UserNotificationPreferenceRepository;
import com.servio.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import com.servio.common.event.AccountUpdatedEvent;
import com.servio.common.event.AppointmentCreatedEvent;
import com.servio.common.event.OfferPublishedEvent;
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
    private final UserNotificationPreferenceRepository preferenceRepository;

    @Autowired(required = false)
    private List<NotificationChannel> extraChannels = List.of();

    @Transactional
    public NotificationDto createNotification(NotificationRequest request) {
        if (!allowsDelivery(request.getUserId(), request.getType())) {
            log.info("Skipped {} notification for user {} because of preferences", request.getType(), request.getUserId());
            return null;
        }

        User user = userRepository.findById(request.getUserId())
            .orElseThrow(() -> new RuntimeException("User not found with id: " + request.getUserId()));

        Notification notification = Notification.builder()
            .user(user)
            .title(request.getTitle())
            .message(request.getMessage())
            .type(request.getType())
            .actionUrl(request.getActionUrl())
            .isRead(false)
            .build();

        notification = notificationRepository.save(notification);
        NotificationDto dto = convertToDto(notification);

        if (pushEnabled(request.getUserId())) {
            try {
                eventPublisher.publishNotification(request.getUserId(), dto);
            } catch (Exception e) {
                log.error("Failed to broadcast WebSocket notification to user {}: {}", request.getUserId(), e.getMessage());
            }
        }

        if (extraChannels != null) {
            for (NotificationChannel channel : extraChannels) {
                try {
                    channel.deliver(dto);
                } catch (Exception e) {
                    log.warn("Notification channel {} failed for user {}: {}",
                            channel.getClass().getSimpleName(), request.getUserId(), e.getMessage());
                }
            }
        }

        return dto;
    }
    
    @Transactional
    public void createAppointmentNotification(UUID userId, String appointmentDetails) {
        NotificationRequest request = NotificationRequest.builder()
            .userId(userId)
            .title("Appointment Request Received")
            .message("Your request has been submitted and is awaiting confirmation: " + appointmentDetails)
            .type("APPOINTMENT")
            .build();
        createNotification(request);
    }

    private void notifyAdminsOfPendingRequest(Long appointmentId, String details) {
        for (User admin : userRepository.findByRole(Role.ADMIN)) {
            createNotification(NotificationRequest.builder()
                .userId(admin.getId())
                .title("Appointment awaiting review")
                .message("Request #" + appointmentId + " needs confirmation: " + details)
                .type("APPOINTMENT")
                .actionUrl("/admin/appointments")
                .build());
        }
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
                notifyAdminsOfPendingRequest(event.getAppointmentId(), details);
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
    
    @Async("taskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onOfferPublished(OfferPublishedEvent event) {
        try {
            log.info("Handling OfferPublishedEvent: offerId={}", event.getOfferId());
            String message = event.getPromoCode() == null
                    ? "A new offer is available."
                    : "Use code " + event.getPromoCode();
            for (User user : userRepository.findAll()) {
                createNotification(NotificationRequest.builder()
                        .userId(user.getId())
                        .title("New offer: " + event.getTitle())
                        .message(message)
                        .type("PROMO")
                        .actionUrl("/offers")
                        .build());
            }
        } catch (Exception e) {
            log.error("Failed to process OfferPublishedEvent for offerId={}: {}", event.getOfferId(), e.getMessage(), e);
        }
    }

    @Async("taskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onAccountUpdated(AccountUpdatedEvent event) {
        try {
            if (event.getUserId() == null) {
                return;
            }
            createNotification(NotificationRequest.builder()
                    .userId(event.getUserId())
                    .title("Account updated")
                    .message(event.getMessage())
                    .type("ACCOUNT")
                    .actionUrl("/account/settings")
                    .build());
        } catch (Exception e) {
            log.error("Failed to process AccountUpdatedEvent for userId={}: {}", event.getUserId(), e.getMessage(), e);
        }
    }

    @Transactional
    public void clearAll(UUID userId) {
        notificationRepository.deleteByUserId(userId);
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
            .actionUrl(notification.getActionUrl())
            .build();
    }

    private boolean allowsDelivery(UUID userId, String type) {
        if (preferenceRepository == null || type == null) {
            return true;
        }
        UserNotificationPreference prefs = preferenceRepository.findById(userId).orElse(null);
        if (prefs == null) {
            return true;
        }
        String normalized = type.toUpperCase();
        if (("PROMO".equals(normalized) || "PROMOTIONAL".equals(normalized))
                && Boolean.FALSE.equals(prefs.getPromotionalOffers())) {
            return false;
        }
        return !"ACCOUNT".equals(normalized) || !Boolean.FALSE.equals(prefs.getSecurityAlerts());
    }

    private boolean pushEnabled(UUID userId) {
        if (preferenceRepository == null) {
            return true;
        }
        return preferenceRepository.findById(userId)
                .map(prefs -> !Boolean.FALSE.equals(prefs.getPushNotifications()))
                .orElse(true);
    }
}
