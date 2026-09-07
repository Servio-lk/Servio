package com.servio.repair.service;

import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.entity.Appointment;
import com.servio.common.config.WebSocketConfig;
import com.servio.notification.dto.AppointmentWebSocketEvent;
import com.servio.notification.dto.NotificationDto;
import com.servio.notification.dto.NotificationRequest;
import com.servio.notification.entity.Notification;
import com.servio.notification.repository.NotificationRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.notification.service.AppointmentEventPublisher;
import com.servio.notification.service.NotificationService;
import com.servio.repair.dto.RepairMessageDto;
import com.servio.repair.dto.RepairMessageRequest;
import com.servio.repair.entity.RepairConversation;
import com.servio.repair.entity.RepairJob;
import com.servio.repair.entity.RepairMessage;
import com.servio.repair.repository.RepairConversationMemberRepository;
import com.servio.repair.repository.RepairConversationRepository;
import com.servio.repair.repository.RepairJobRepository;
import com.servio.repair.repository.RepairMessageRepository;
import com.servio.admin.repository.MechanicRepository;
import com.servio.auth.repository.ProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.StompWebSocketEndpointRegistration;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class WebSocketStompAdversarialTest {

    @Mock
    private RepairConversationRepository conversationRepository;
    @Mock
    private RepairConversationMemberRepository memberRepository;
    @Mock
    private RepairMessageRepository messageRepository;
    @Mock
    private RepairJobRepository repairJobRepository;
    @Mock
    private MechanicRepository mechanicRepository;
    @Mock
    private ProfileRepository profileRepository;
    @Mock
    private RepairJobService repairJobService;
    @Mock
    private SimpMessagingTemplate messagingTemplate;
    @Mock
    private Authentication authentication;
    @Mock
    private UserRepository userRepository;
    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private RepairChatService repairChatService;

    private Long repairId;
    private Long appointmentId;
    private RepairJob repairJob;
    private RepairConversation conversation;
    private UUID testUserId;
    private User testUser;

    @BeforeEach
    void setUp() {
        repairId = 101L;
        appointmentId = 202L;
        testUserId = UUID.randomUUID();

        testUser = User.builder()
                .id(testUserId)
                .email("ws_tester@servio.lk")
                .fullName("WS Tester")
                .role(Role.USER)
                .build();

        Appointment appointment = Appointment.builder()
                .id(appointmentId)
                .user(testUser)
                .serviceType("Major Overhaul")
                .status("IN_PROGRESS")
                .build();

        repairJob = RepairJob.builder()
                .id(repairId)
                .appointment(appointment)
                .user(testUser)
                .status("IN_PROGRESS")
                .build();

        conversation = RepairConversation.builder()
                .id(303L)
                .repairJob(repairJob)
                .isReadOnly(false)
                .build();
    }

    @Test
    @DisplayName("Adversarial: WebSocketConfig registers /topic simple broker and /app destination prefix")
    void testWebSocketConfigBrokerRegistry() {
        WebSocketConfig config = new WebSocketConfig();
        MessageBrokerRegistry registry = mock(MessageBrokerRegistry.class);

        config.configureMessageBroker(registry);

        verify(registry, times(1)).enableSimpleBroker("/topic");
        verify(registry, times(1)).setApplicationDestinationPrefixes("/app");
    }

    @Test
    @DisplayName("Adversarial: WebSocketConfig registers /api/ws and /api/ws-sockjs endpoints with allowed origin patterns")
    void testWebSocketConfigEndpoints() {
        WebSocketConfig config = new WebSocketConfig();
        StompEndpointRegistry registry = mock(StompEndpointRegistry.class);
        StompWebSocketEndpointRegistration registrationWs = mock(StompWebSocketEndpointRegistration.class);
        StompWebSocketEndpointRegistration registrationSockJs = mock(StompWebSocketEndpointRegistration.class);

        when(registry.addEndpoint("/api/ws")).thenReturn(registrationWs);
        when(registrationWs.setAllowedOriginPatterns("*")).thenReturn(registrationWs);

        when(registry.addEndpoint("/api/ws-sockjs")).thenReturn(registrationSockJs);
        when(registrationSockJs.setAllowedOriginPatterns("*")).thenReturn(registrationSockJs);
        when(registrationSockJs.withSockJS()).thenReturn(null);

        assertDoesNotThrow(() -> config.registerStompEndpoints(registry));
        verify(registry, times(1)).addEndpoint("/api/ws");
        verify(registry, times(1)).addEndpoint("/api/ws-sockjs");
    }

    @Test
    @DisplayName("Adversarial: Chat message is broadcast to both /topic/repairs/{id}/messages and /topic/appointments/{id}/messages with payload integrity")
    void testChatMessageBroadcastTopicsAndPayload() {
        RepairMessageRequest request = new RepairMessageRequest();
        request.setBody("Transmission fluid has been replaced.");

        when(conversationRepository.findByRepairJobId(repairId)).thenReturn(Optional.of(conversation));
        when(authentication.getName()).thenReturn(testUserId.toString());
        doReturn(List.of(new SimpleGrantedAuthority("USER"))).when(authentication).getAuthorities();

        when(messageRepository.save(any(RepairMessage.class))).thenAnswer(inv -> {
            RepairMessage m = inv.getArgument(0);
            m.setId(404L);
            return m;
        });

        RepairMessageDto result = repairChatService.sendMessage(repairId, request, authentication);

        assertNotNull(result);
        assertEquals(404L, result.getId());
        assertEquals("Transmission fluid has been replaced.", result.getBody());
        assertEquals("CLIENT", result.getSenderRole());

        // Verify broadcast to repair topic
        ArgumentCaptor<RepairMessageDto> repairCaptor = ArgumentCaptor.forClass(RepairMessageDto.class);
        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/repairs/" + repairId + "/messages"), repairCaptor.capture());
        assertEquals(404L, repairCaptor.getValue().getId());
        assertEquals(repairId, repairCaptor.getValue().getRepairId());

        // Verify broadcast to appointment topic
        ArgumentCaptor<RepairMessageDto> appointmentCaptor = ArgumentCaptor.forClass(RepairMessageDto.class);
        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/appointments/" + appointmentId + "/messages"), appointmentCaptor.capture());
        assertEquals(404L, appointmentCaptor.getValue().getId());
        assertEquals(repairId, appointmentCaptor.getValue().getRepairId());
    }

    @Test
    @DisplayName("Adversarial: Chat message sending survives total WebSocket broker crash without aborting database transaction")
    void testChatMessageSurvivesBrokerDownException() {
        RepairMessageRequest request = new RepairMessageRequest();
        request.setBody("Important update from mechanic");

        when(conversationRepository.findByRepairJobId(repairId)).thenReturn(Optional.of(conversation));
        when(authentication.getName()).thenReturn("admin");
        doReturn(List.of(new SimpleGrantedAuthority("ADMIN"))).when(authentication).getAuthorities();

        when(messageRepository.save(any(RepairMessage.class))).thenAnswer(inv -> {
            RepairMessage m = inv.getArgument(0);
            m.setId(405L);
            return m;
        });

        // Simulate broker transport failure
        doThrow(new MessagingException("STOMP connection reset by peer"))
                .when(messagingTemplate).convertAndSend(anyString(), any(Object.class));

        RepairMessageDto dto = assertDoesNotThrow(() -> repairChatService.sendMessage(repairId, request, authentication));
        assertNotNull(dto);
        assertEquals(405L, dto.getId());
        verify(messageRepository, times(1)).save(any(RepairMessage.class));
    }

    @Test
    @DisplayName("Adversarial: AppointmentEventPublisher sends to /topic/appointments and /topic/appointments/user/{id}")
    void testAppointmentEventPublisherDestinations() {
        AppointmentEventPublisher publisher = new AppointmentEventPublisher(messagingTemplate);

        AppointmentDto dto = AppointmentDto.builder()
                .id(606L)
                .userId(testUserId)
                .serviceType("Brake Replacement")
                .status("CONFIRMED")
                .appointmentDate(LocalDateTime.of(2026, 11, 15, 10, 30))
                .build();

        publisher.publish("UPDATED", dto);

        ArgumentCaptor<AppointmentWebSocketEvent> eventCaptor = ArgumentCaptor.forClass(AppointmentWebSocketEvent.class);
        verify(messagingTemplate, times(1)).convertAndSend(eq("/topic/appointments"), eventCaptor.capture());
        verify(messagingTemplate, times(1)).convertAndSend(eq("/topic/appointments/user/" + testUserId), eventCaptor.capture());

        AppointmentWebSocketEvent event = eventCaptor.getValue();
        assertEquals("UPDATED", event.getType());
        assertEquals(606L, event.getAppointmentId());
        assertEquals(testUserId, event.getUserId());
        assertEquals("Brake Replacement", event.getServiceType());
        assertEquals("CONFIRMED", event.getStatus());
        assertEquals("2026-11-15T10:30", event.getAppointmentDate());
    }

    @Test
    @DisplayName("Adversarial: NotificationService createNotification persists entity and pushes to /topic/notifications/user/{id} even if WebSocket fails")
    void testNotificationCreationWithWebSocketResilience() {
        AppointmentEventPublisher publisher = mock(AppointmentEventPublisher.class);
        NotificationService service = new NotificationService(notificationRepository, userRepository, publisher);

        NotificationRequest request = NotificationRequest.builder()
                .userId(testUserId)
                .title("Ready for Pickup")
                .message("Your car is ready.")
                .type("READY")
                .build();

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(inv -> {
            Notification n = inv.getArgument(0);
            n.setId(707L);
            return n;
        });

        // Simulate WebSocket publisher throwing exception
        doThrow(new RuntimeException("WebSocket buffer overflow"))
                .when(publisher).publishNotification(eq(testUserId), any(NotificationDto.class));

        NotificationDto result = assertDoesNotThrow(() -> service.createNotification(request));

        assertNotNull(result);
        assertEquals(707L, result.getId());
        assertEquals("Ready for Pickup", result.getTitle());
        verify(notificationRepository, times(1)).save(any(Notification.class));
    }
}
