package com.servio.notification.service;

import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.common.config.AsyncConfig;
import com.servio.common.event.AppointmentCreatedEvent;
import com.servio.common.event.PaymentCompletedEvent;
import com.servio.common.event.RepairStatusChangedEvent;
import com.servio.notification.dto.NotificationDto;
import com.servio.notification.entity.Notification;
import com.servio.notification.repository.NotificationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Executor;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationEventListenerTest {

    @Mock
    private NotificationRepository notificationRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private AppointmentEventPublisher eventPublisher;

    @InjectMocks
    private NotificationService notificationService;

    private UUID testUserId;
    private User testUser;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
        testUser = User.builder()
                .id(testUserId)
                .email("user@servio.lk")
                .fullName("Alex Smith")
                .role(Role.USER)
                .build();
    }

    @Test
    @DisplayName("AsyncConfig sets up ThreadPoolTaskExecutor correctly")
    void testAsyncConfigExecutor() {
        AsyncConfig asyncConfig = new AsyncConfig();
        Executor executor = asyncConfig.getAsyncExecutor();
        assertNotNull(executor);
        assertInstanceOf(ThreadPoolTaskExecutor.class, executor);
        ThreadPoolTaskExecutor threadPool = (ThreadPoolTaskExecutor) executor;
        assertEquals("servio-async-", threadPool.getThreadNamePrefix());
        assertEquals(5, threadPool.getCorePoolSize());
        assertEquals(25, threadPool.getMaxPoolSize());
    }

    @Test
    @DisplayName("onAppointmentCreated creates notification and broadcasts via STOMP")
    void testOnAppointmentCreated() {
        AppointmentCreatedEvent event = new AppointmentCreatedEvent(
                this, 10L, testUserId, "Full Service", "Sep 15, 2026 at 10:00 AM"
        );

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(inv -> {
            Notification n = inv.getArgument(0);
            n.setId(100L);
            return n;
        });

        notificationService.onAppointmentCreated(event);

        ArgumentCaptor<Notification> notificationCaptor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository, times(1)).save(notificationCaptor.capture());
        Notification saved = notificationCaptor.getValue();
        assertEquals("Appointment Confirmation", saved.getTitle());
        assertTrue(saved.getMessage().contains("Full Service on Sep 15, 2026 at 10:00 AM"));
        assertEquals("APPOINTMENT", saved.getType());
        assertEquals(testUser, saved.getUser());

        verify(eventPublisher, times(1)).publishNotification(eq(testUserId), any(NotificationDto.class));
    }

    @Test
    @DisplayName("onPaymentCompleted creates payment notification with formatted LKR amount and pushes WebSocket")
    void testOnPaymentCompleted() {
        PaymentCompletedEvent event = new PaymentCompletedEvent(
                this, 10L, testUserId, 7500.50, "PAYHERE"
        );

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(inv -> {
            Notification n = inv.getArgument(0);
            n.setId(101L);
            return n;
        });

        notificationService.onPaymentCompleted(event);

        ArgumentCaptor<Notification> notificationCaptor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository, times(1)).save(notificationCaptor.capture());
        Notification saved = notificationCaptor.getValue();
        assertEquals("Payment Received", saved.getTitle());
        assertEquals("Payment received: LKR 7500.50 via PAYHERE", saved.getMessage());
        assertEquals("PAYMENT", saved.getType());

        verify(eventPublisher, times(1)).publishNotification(eq(testUserId), any(NotificationDto.class));
    }

    @Test
    @DisplayName("onRepairStatusChanged creates status update notification and pushes WebSocket")
    void testOnRepairStatusChanged() {
        RepairStatusChangedEvent event = new RepairStatusChangedEvent(
                this, 10L, testUserId, "IN_PROGRESS", "Your vehicle inspection has started."
        );

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(inv -> {
            Notification n = inv.getArgument(0);
            n.setId(102L);
            return n;
        });

        notificationService.onRepairStatusChanged(event);

        ArgumentCaptor<Notification> notificationCaptor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository, times(1)).save(notificationCaptor.capture());
        Notification saved = notificationCaptor.getValue();
        assertEquals("Repair Status Update", saved.getTitle());
        assertEquals("Your vehicle inspection has started.", saved.getMessage());
        assertEquals("REPAIR_UPDATE", saved.getType());

        verify(eventPublisher, times(1)).publishNotification(eq(testUserId), any(NotificationDto.class));
    }

    @Test
    @DisplayName("Event listeners do not crash or throw exceptions when userId is null")
    void testEventListenersWithNullUserId() {
        AppointmentCreatedEvent event1 = new AppointmentCreatedEvent(this, 10L, null, "Full Service", "Date");
        PaymentCompletedEvent event2 = new PaymentCompletedEvent(this, 10L, null, 100.0, "CASH");
        RepairStatusChangedEvent event3 = new RepairStatusChangedEvent(this, 10L, null, "STATUS", "Msg");

        assertDoesNotThrow(() -> notificationService.onAppointmentCreated(event1));
        assertDoesNotThrow(() -> notificationService.onPaymentCompleted(event2));
        assertDoesNotThrow(() -> notificationService.onRepairStatusChanged(event3));

        verify(notificationRepository, never()).save(any());
        verify(eventPublisher, never()).publishNotification(any(), any());
    }

    @Test
    @DisplayName("Event listener resilience: downstream database or WebSocket error is safely trapped without throwing")
    void testEventListenerResilienceUnderFailure() {
        PaymentCompletedEvent event = new PaymentCompletedEvent(
                this, 10L, testUserId, 5000.0, "CASH"
        );

        // Simulate database lookup failure in async thread
        when(userRepository.findById(testUserId)).thenThrow(new RuntimeException("Database connectivity lost in async worker"));

        assertDoesNotThrow(() -> notificationService.onPaymentCompleted(event));
    }
}
