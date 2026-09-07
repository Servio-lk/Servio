package com.servio.notification.service;

import com.servio.booking.dto.AppointmentDto;
import com.servio.notification.dto.AppointmentWebSocketEvent;
import com.servio.notification.dto.NotificationDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AppointmentEventPublisherTest {

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private AppointmentEventPublisher eventPublisher;

    private UUID userId;
    private AppointmentDto dto;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        dto = AppointmentDto.builder()
                .id(88L)
                .userId(userId)
                .serviceType("Battery Replacement")
                .status("CONFIRMED")
                .appointmentDate(LocalDateTime.of(2026, 9, 20, 14, 30))
                .build();
    }

    @Test
    @DisplayName("publish broadcasts to global /topic/appointments and user-specific /topic/appointments/user/{userId}")
    void testPublishBroadcastsToBothTopics() {
        eventPublisher.publish("CONFIRMED", dto);

        ArgumentCaptor<AppointmentWebSocketEvent> eventCaptor = ArgumentCaptor.forClass(AppointmentWebSocketEvent.class);
        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/appointments"), eventCaptor.capture());
        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/appointments/user/" + userId), eventCaptor.capture());

        AppointmentWebSocketEvent event = eventCaptor.getValue();
        assertEquals("CONFIRMED", event.getType());
        assertEquals(88L, event.getAppointmentId());
        assertEquals(userId, event.getUserId());
        assertEquals("Battery Replacement", event.getServiceType());
        assertEquals("CONFIRMED", event.getStatus());
    }

    @Test
    @DisplayName("publishNotification pushes to user-specific /topic/notifications/user/{userId}")
    void testPublishNotification() {
        NotificationDto notificationDto = NotificationDto.builder()
                .id(201L)
                .userId(userId)
                .title("Service Ready")
                .message("Your car is ready for pickup.")
                .type("SERVICE_READY")
                .build();

        eventPublisher.publishNotification(userId, notificationDto);

        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/notifications/user/" + userId), eq(notificationDto));
    }
}
