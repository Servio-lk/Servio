package com.servio.payment.service;

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
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PayHereServicePaymentEventTest {

    @Mock
    private AppointmentRepository appointmentRepository;
    @Mock
    private PaymentRepository paymentRepository;
    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private PayHereService payHereService;

    private String merchantId;
    private String merchantSecret;
    private Long appointmentId;
    private UUID userId;
    private User testUser;
    private Appointment appointment;

    @BeforeEach
    void setUp() {
        merchantId = "1223456";
        merchantSecret = "mock_merchant_secret_12345";
        appointmentId = 45L;
        userId = UUID.randomUUID();

        ReflectionTestUtils.setField(payHereService, "merchantId", merchantId);
        ReflectionTestUtils.setField(payHereService, "merchantSecret", merchantSecret);

        testUser = User.builder()
                .id(userId)
                .email("paytest@servio.lk")
                .fullName("Paying Customer")
                .role(Role.USER)
                .build();

        appointment = Appointment.builder()
                .id(appointmentId)
                .user(testUser)
                .serviceType("Full Vehicle Service")
                .status("PENDING_PAYMENT")
                .estimatedCost(BigDecimal.valueOf(8500.00))
                .build();
    }

    private String computeMd5Sig(String merchantId, String orderId, String amount, String currency, String statusCode, String secret) throws Exception {
        MessageDigest md = MessageDigest.getInstance("MD5");
        String secretHash = bytesToHex(md.digest(secret.getBytes(StandardCharsets.UTF_8))).toUpperCase();
        String plain = merchantId + orderId + amount + currency + statusCode + secretHash;
        return bytesToHex(md.digest(plain.getBytes(StandardCharsets.UTF_8))).toUpperCase();
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    @Test
    @DisplayName("Valid PayHere notification confirms appointment, persists payment, and publishes PaymentCompletedEvent")
    void testHandleNotificationPublishesEvent() throws Exception {
        String orderId = "ORD-" + appointmentId;
        String amount = "8500.00";
        String currency = "LKR";
        String statusCode = "2"; // 2 = SUCCESS
        String paymentId = "PAYHERE_TX_98765";
        String md5sig = computeMd5Sig(merchantId, orderId, amount, currency, statusCode, merchantSecret);

        when(appointmentRepository.findById(appointmentId)).thenReturn(Optional.of(appointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));

        payHereService.handleNotification(
                merchantId,
                orderId,
                amount,
                currency,
                statusCode,
                md5sig,
                paymentId,
                "VISA"
        );

        // Verify appointment confirmed
        assertEquals("CONFIRMED", appointment.getStatus());
        verify(appointmentRepository, times(1)).save(appointment);

        // Verify payment record
        ArgumentCaptor<Payment> paymentCaptor = ArgumentCaptor.forClass(Payment.class);
        verify(paymentRepository, times(1)).save(paymentCaptor.capture());
        Payment saved = paymentCaptor.getValue();
        assertEquals(new BigDecimal("8500.00"), saved.getAmount());
        assertEquals("PAYHERE", saved.getPaymentMethod());
        assertEquals("COMPLETED", saved.getPaymentStatus());
        assertEquals(paymentId, saved.getTransactionId());

        // Verify event published
        ArgumentCaptor<PaymentCompletedEvent> eventCaptor = ArgumentCaptor.forClass(PaymentCompletedEvent.class);
        verify(applicationEventPublisher, times(1)).publishEvent(eventCaptor.capture());
        PaymentCompletedEvent event = eventCaptor.getValue();
        assertEquals(appointmentId, event.getAppointmentId());
        assertEquals(userId, event.getUserId());
        assertEquals(8500.00, event.getAmount());
        assertEquals("PAYHERE", event.getPaymentMethod());
    }

    @Test
    @DisplayName("Invalid PayHere signature throws SecurityException and does not publish events")
    void testInvalidSignatureThrowsSecurityException() {
        String orderId = "ORD-" + appointmentId;
        String amount = "8500.00";
        String currency = "LKR";
        String statusCode = "2";
        String invalidSig = "INVALID_MD5_SIGNATURE";

        assertThrows(SecurityException.class, () -> payHereService.handleNotification(
                merchantId,
                orderId,
                amount,
                currency,
                statusCode,
                invalidSig,
                "PAYHERE_TX_FAIL",
                "VISA"
        ));

        verify(appointmentRepository, never()).save(any());
        verify(paymentRepository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any());
    }
}
