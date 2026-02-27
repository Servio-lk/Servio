package com.servio.service;

import com.servio.dto.AppointmentDto;
import com.servio.dto.AppointmentWebSocketEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

/**
 * Broadcasts appointment lifecycle events over STOMP WebSocket.
 *
 * Topics:
 *   /topic/appointments           – every change (all users / admin)
 *   /topic/appointments/user/{id} – change for a specific user
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

        // Broadcast to all subscribers (admin dashboard, etc.)
        messagingTemplate.convertAndSend("/topic/appointments", event);

        // Broadcast to the specific user's channel
        if (dto.getUserId() != null) {
            messagingTemplate.convertAndSend("/topic/appointments/user/" + dto.getUserId(), event);
        }
    }
}
