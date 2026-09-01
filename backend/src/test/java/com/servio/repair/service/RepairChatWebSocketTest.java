package com.servio.repair.service;

import com.servio.admin.entity.Mechanic;
import com.servio.admin.repository.MechanicRepository;
import com.servio.auth.repository.ProfileRepository;
import com.servio.booking.entity.Appointment;
import com.servio.repair.dto.RepairMessageDto;
import com.servio.repair.dto.RepairMessageRequest;
import com.servio.repair.entity.ConversationMemberRole;
import com.servio.repair.entity.RepairConversation;
import com.servio.repair.entity.RepairConversationMember;
import com.servio.repair.entity.RepairJob;
import com.servio.repair.entity.RepairMessage;
import com.servio.repair.repository.RepairConversationMemberRepository;
import com.servio.repair.repository.RepairConversationRepository;
import com.servio.repair.repository.RepairJobRepository;
import com.servio.repair.repository.RepairMessageRepository;
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
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RepairChatWebSocketTest {

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

    @InjectMocks
    private RepairChatService repairChatService;

    private Long repairId;
    private Long appointmentId;
    private RepairJob repairJob;
    private RepairConversation conversation;

    @BeforeEach
    void setUp() {
        repairId = 42L;
        appointmentId = 15L;

        Appointment appointment = Appointment.builder()
                .id(appointmentId)
                .serviceType("Engine Diagnostics")
                .build();

        repairJob = RepairJob.builder()
                .id(repairId)
                .appointment(appointment)
                .status("IN_PROGRESS")
                .build();

        conversation = RepairConversation.builder()
                .id(100L)
                .repairJob(repairJob)
                .isReadOnly(false)
                .build();
    }

    @Test
    @DisplayName("sendMessage persists message and broadcasts to STOMP topics")
    void testSendMessageBroadcastsToSTOMP() {
        RepairMessageRequest request = new RepairMessageRequest();
        request.setBody("Please inspect the brake pads as well.");

        when(conversationRepository.findByRepairJobId(repairId)).thenReturn(Optional.of(conversation));
        when(authentication.getName()).thenReturn("admin_user");
        doReturn(List.of(new SimpleGrantedAuthority("ADMIN"))).when(authentication).getAuthorities();

        when(messageRepository.save(any(RepairMessage.class))).thenAnswer(inv -> {
            RepairMessage msg = inv.getArgument(0);
            msg.setId(501L);
            return msg;
        });

        RepairMessageDto dto = repairChatService.sendMessage(repairId, request, authentication);

        assertNotNull(dto);
        assertEquals(501L, dto.getId());
        assertEquals("Please inspect the brake pads as well.", dto.getBody());
        assertEquals("admin_user", dto.getSenderId());
        assertEquals("ADMIN", dto.getSenderRole());

        // Verify broadcast to repair topic
        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/repairs/42/messages"), eq(dto));

        // Verify broadcast to appointment topic
        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/appointments/15/messages"), eq(dto));
    }

    @Test
    @DisplayName("sendMessage WebSocket exception resilience: message saved even if WebSocket broker fails")
    void testSendMessageResilienceOnBrokerFailure() {
        RepairMessageRequest request = new RepairMessageRequest();
        request.setBody("Hello from customer");

        when(conversationRepository.findByRepairJobId(repairId)).thenReturn(Optional.of(conversation));
        when(authentication.getName()).thenReturn("admin_user");
        doReturn(List.of(new SimpleGrantedAuthority("ADMIN"))).when(authentication).getAuthorities();

        when(messageRepository.save(any(RepairMessage.class))).thenAnswer(inv -> {
            RepairMessage msg = inv.getArgument(0);
            msg.setId(502L);
            return msg;
        });

        // Simulate broker failure during broadcast
        doThrow(new MessagingException("Broker transport disconnected"))
                .when(messagingTemplate).convertAndSend(eq("/topic/repairs/42/messages"), any(RepairMessageDto.class));

        assertDoesNotThrow(() -> {
            RepairMessageDto dto = repairChatService.sendMessage(repairId, request, authentication);
            assertNotNull(dto);
            assertEquals(502L, dto.getId());
        });

        verify(messageRepository, times(1)).save(any(RepairMessage.class));
    }

    @Test
    @DisplayName("sendMessage rejects empty or whitespace body")
    void testSendMessageRejectsEmptyBody() {
        RepairMessageRequest emptyRequest = new RepairMessageRequest();
        emptyRequest.setBody("   ");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> 
                repairChatService.sendMessage(repairId, emptyRequest, authentication));
        assertEquals("Message body is required", ex.getMessage());
        verify(messageRepository, never()).save(any());
        verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
    }

    @Test
    @DisplayName("sendMessage rejects sending when conversation is read-only")
    void testSendMessageRejectsWhenReadOnly() {
        conversation.setIsReadOnly(true);
        RepairMessageRequest request = new RepairMessageRequest();
        request.setBody("Should fail");

        when(conversationRepository.findByRepairJobId(repairId)).thenReturn(Optional.of(conversation));
        doReturn(List.of(new SimpleGrantedAuthority("ADMIN"))).when(authentication).getAuthorities();

        RuntimeException ex = assertThrows(RuntimeException.class, () ->
                repairChatService.sendMessage(repairId, request, authentication));
        assertEquals("This repair conversation is read-only", ex.getMessage());
        verify(messageRepository, never()).save(any());
        verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
    }
}
