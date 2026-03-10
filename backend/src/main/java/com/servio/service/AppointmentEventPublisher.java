package com.servio.service;

import com.servio.dto.AppointmentDto;
import com.servio.dto.AppointmentWebSocketEvent;
import com.servio.dto.NotificationDto;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

/**
 * Broadcasts appointment lifecycle events and notifications over STOMP WebSocket.
 *
 * Topics:
 *   /topic/appointments              – every appointment change (admin)
 *   /topic/appointments/user/{id}   – change for a specific user
 *   /topic/notifications/user/{id}  – notification pushed to a specific user
 */
@Service
@RequiredArgsConstructor
public class AppointmentEventPublisher {

    private final SimpMessagingTemplate messagingTemplate;

    public void publish(String eventType, AppointmentDto dto) {
        AppointmentWebSocketEvent event = AppointmentWebSocketEvent.builder()
                .type(eventType)
                .appointmentId(dto.getId())
                .userId(dto.getUserId())
                .serviceType(dto.getServiceType())
                .status(dto.getStatus())
                .appointmentDate(dto.getAppointmentDate() != null ? dto.getAppointmentDate().toString() : null)
                .build();

        messagingTemplate.convertAndSend("/topic/appointments", event);

        if (dto.getUserId() != null) {
            messagingTemplate.convertAndSend("/topic/appointments/user/" + dto.getUserId(), event);
        }
    }

    /** Push a persisted notification to the user's notification topic in real-time. */
    public void publishNotification(Long userId, NotificationDto notification) {
        if (userId != null) {
            messagingTemplate.convertAndSend("/topic/notifications/user/" + userId, notification);
        }
    }
}
