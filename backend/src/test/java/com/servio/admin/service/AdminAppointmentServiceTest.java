package com.servio.admin.service;

import com.servio.admin.dto.PaymentCollectionRequest;
import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.common.event.PaymentCompletedEvent;
import com.servio.payment.entity.Payment;
import com.servio.payment.repository.PaymentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminAppointmentServiceTest {

    @Mock
    private AppointmentRepository appointmentRepository;
    @Mock
    private PaymentRepository paymentRepository;
    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private AdminAppointmentService adminAppointmentService;

    private Long appointmentId;
    private UUID userId;
    private User testUser;
    private Appointment appointment;

    @BeforeEach
    void setUp() {
        appointmentId = 77L;
        userId = UUID.randomUUID();
        testUser = User.builder()
                .id(userId)
                .email("customer@servio.lk")
                .fullName("John Customer")
                .role(Role.USER)
                .build();

        appointment = Appointment.builder()
                .id(appointmentId)
                .user(testUser)
                .serviceType("Transmission Check")
                .status("IN_PROGRESS")
                .build();
    }

    @Test
    @DisplayName("recordPayment persists payment and publishes PaymentCompletedEvent")
    void testRecordPaymentPublishesEvent() {
        PaymentCollectionRequest request = new PaymentCollectionRequest();
        request.setAmount(BigDecimal.valueOf(12500.00));
        request.setPaymentMethod("CASH");

        when(appointmentRepository.findById(appointmentId)).thenReturn(Optional.of(appointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));

        adminAppointmentService.recordPayment(appointmentId, request);

        ArgumentCaptor<Payment> paymentCaptor = ArgumentCaptor.forClass(Payment.class);
        verify(paymentRepository, times(1)).save(paymentCaptor.capture());
        Payment savedPayment = paymentCaptor.getValue();
        assertEquals(BigDecimal.valueOf(12500.00), savedPayment.getAmount());
        assertEquals("CASH", savedPayment.getPaymentMethod());
        assertEquals("COMPLETED", savedPayment.getPaymentStatus());
        assertEquals(appointment, savedPayment.getAppointment());
        assertEquals(testUser, savedPayment.getUser());

        ArgumentCaptor<PaymentCompletedEvent> eventCaptor = ArgumentCaptor.forClass(PaymentCompletedEvent.class);
        verify(applicationEventPublisher, times(1)).publishEvent(eventCaptor.capture());
        PaymentCompletedEvent publishedEvent = eventCaptor.getValue();
        assertEquals(appointmentId, publishedEvent.getAppointmentId());
        assertEquals(userId, publishedEvent.getUserId());
        assertEquals(12500.00, publishedEvent.getAmount());
        assertEquals("CASH", publishedEvent.getPaymentMethod());
    }
}
