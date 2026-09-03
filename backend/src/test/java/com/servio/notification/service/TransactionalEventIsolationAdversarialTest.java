package com.servio.notification.service;

import com.servio.admin.dto.PaymentCollectionRequest;
import com.servio.admin.service.AdminAppointmentService;
import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.dto.AppointmentRequest;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.booking.repository.VehicleRepository;
import com.servio.booking.service.AppointmentService;
import com.servio.common.config.AsyncConfig;
import com.servio.common.event.AppointmentCreatedEvent;
import com.servio.common.event.PaymentCompletedEvent;
import com.servio.common.event.RepairStatusChangedEvent;
import com.servio.notification.repository.NotificationRepository;
import com.servio.payment.entity.Payment;
import com.servio.payment.repository.PaymentRepository;
import com.servio.payment.service.PayHereService;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Executor;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class TransactionalEventIsolationAdversarialTest {

    @Mock
    private AppointmentRepository appointmentRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private VehicleRepository vehicleRepository;
    @Mock
    private PaymentRepository paymentRepository;
    @Mock
    private NotificationRepository notificationRepository;
    @Mock
    private AppointmentEventPublisher eventPublisher;
    @Mock
    private ApplicationEventPublisher applicationEventPublisher;
    @Mock
    private JdbcTemplate jdbcTemplate;
    @Mock
    private EntityManager entityManager;

    private NotificationService notificationService;
    private AppointmentService appointmentService;
    private AdminAppointmentService adminAppointmentService;
    private PayHereService payHereService;

    private UUID userId;
    private User testUser;
    private LocalDateTime targetDate;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        testUser = User.builder()
                .id(userId)
                .email("adversarial_event@servio.lk")
                .fullName("Event Tester")
                .role(Role.USER)
                .build();
        targetDate = LocalDateTime.of(2026, 11, 10, 14, 0);

        notificationService = new NotificationService(notificationRepository, userRepository, eventPublisher);

        appointmentService = new AppointmentService(
                appointmentRepository,
                userRepository,
                vehicleRepository,
                jdbcTemplate,
                entityManager,
                eventPublisher,
                applicationEventPublisher
        );

        adminAppointmentService = new AdminAppointmentService(
                appointmentRepository,
                paymentRepository,
                applicationEventPublisher
        );

        payHereService = new PayHereService(
                appointmentRepository,
                paymentRepository,
                applicationEventPublisher
        );
        ReflectionTestUtils.setField(payHereService, "merchantId", "123456");
        ReflectionTestUtils.setField(payHereService, "merchantSecret", "secret_xyz");
    }

    @Test
    @DisplayName("Adversarial: Listener exceptions in onAppointmentCreated do not throw or crash")
    void testOnAppointmentCreatedCatchesSevereExceptions() {
        AppointmentCreatedEvent event = new AppointmentCreatedEvent(
                this, 501L, userId, "Oil Change", "2026-11-10 14:00"
        );

        // Simulate database exception when looking up user in async thread
        when(userRepository.findById(userId)).thenThrow(new DataAccessException("Simulated DB connection failure") {});

        assertDoesNotThrow(() -> notificationService.onAppointmentCreated(event),
                "Listener must catch all exceptions and not propagate to thread executor");
        verify(notificationRepository, never()).save(any());
    }

    @Test
    @DisplayName("Adversarial: Listener exceptions in onPaymentCompleted do not throw or crash")
    void testOnPaymentCompletedCatchesSevereExceptions() {
        PaymentCompletedEvent event = new PaymentCompletedEvent(
                this, 501L, userId, 9500.0, "CASH"
        );

        // Simulate repository error during notification persistence
        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(notificationRepository.save(any())).thenThrow(new RuntimeException("Simulated disk full error"));

        assertDoesNotThrow(() -> notificationService.onPaymentCompleted(event),
                "Listener must catch all exceptions and not propagate");
    }

    @Test
    @DisplayName("Adversarial: Listener exceptions in onRepairStatusChanged do not throw or crash")
    void testOnRepairStatusChangedCatchesSevereExceptions() {
        RepairStatusChangedEvent event = new RepairStatusChangedEvent(
                this, 501L, userId, "COMPLETED", "Service finished"
        );

        when(userRepository.findById(userId)).thenThrow(new NullPointerException("Simulated NPE in listener"));

        assertDoesNotThrow(() -> notificationService.onRepairStatusChanged(event),
                "Listener must catch NullPointerException safely");
    }

    @Test
    @DisplayName("Adversarial: Verify NotificationService listeners are annotated with @Async('taskExecutor') and @TransactionalEventListener(AFTER_COMMIT, fallbackExecution = true)")
    void testEventListenerAnnotations() throws NoSuchMethodException {
        Class<?> serviceClass = NotificationService.class;

        Method[] listenerMethods = new Method[]{
                serviceClass.getMethod("onAppointmentCreated", AppointmentCreatedEvent.class),
                serviceClass.getMethod("onPaymentCompleted", PaymentCompletedEvent.class),
                serviceClass.getMethod("onRepairStatusChanged", RepairStatusChangedEvent.class)
        };

        for (Method method : listenerMethods) {
            Async async = method.getAnnotation(Async.class);
            assertNotNull(async, method.getName() + " must have @Async");
            assertEquals("taskExecutor", async.value(), method.getName() + " must target taskExecutor");

            TransactionalEventListener txListener = method.getAnnotation(TransactionalEventListener.class);
            assertNotNull(txListener, method.getName() + " must have @TransactionalEventListener");
            assertEquals(TransactionPhase.AFTER_COMMIT, txListener.phase(), method.getName() + " must execute AFTER_COMMIT");
            assertTrue(txListener.fallbackExecution(), method.getName() + " must have fallbackExecution = true");
        }
    }

    @Test
    @DisplayName("Adversarial: Primary appointment creation succeeds and publishes event even if listener would fail")
    void testPrimaryAppointmentCreationSucceedsWithEventPublishing() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(userId)
                .appointmentDate(targetDate)
                .serviceType("Engine Diagnostics")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetDate), anyList()))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.saveAndFlush(any(Appointment.class))).thenAnswer(inv -> {
            Appointment a = inv.getArgument(0);
            a.setId(777L);
            return a;
        });

        AppointmentDto dto = appointmentService.createAppointment(request, null);

        assertNotNull(dto);
        assertEquals(777L, dto.getId());

        // Verify that domain event was published to Spring ApplicationEventPublisher
        ArgumentCaptor<AppointmentCreatedEvent> eventCaptor = ArgumentCaptor.forClass(AppointmentCreatedEvent.class);
        verify(applicationEventPublisher, times(1)).publishEvent(eventCaptor.capture());
        AppointmentCreatedEvent event = eventCaptor.getValue();
        assertEquals(777L, event.getAppointmentId());
        assertEquals(userId, event.getUserId());
    }

    @Test
    @DisplayName("Adversarial: Admin payment recording commits and publishes event with correct details")
    void testAdminPaymentCollectionPublishesEventSafely() {
        Appointment appointment = Appointment.builder()
                .id(888L)
                .user(testUser)
                .status("IN_PROGRESS")
                .build();

        PaymentCollectionRequest request = new PaymentCollectionRequest();
        request.setAmount(BigDecimal.valueOf(15000.00));
        request.setPaymentMethod("CARD");

        when(appointmentRepository.findById(888L)).thenReturn(Optional.of(appointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));

        adminAppointmentService.recordPayment(888L, request);

        // Verify payment is saved with COMPLETED status
        ArgumentCaptor<Payment> paymentCaptor = ArgumentCaptor.forClass(Payment.class);
        verify(paymentRepository, times(1)).save(paymentCaptor.capture());
        Payment savedPayment = paymentCaptor.getValue();
        assertEquals("COMPLETED", savedPayment.getPaymentStatus());
        assertEquals(BigDecimal.valueOf(15000.00), savedPayment.getAmount());
        assertEquals("CARD", savedPayment.getPaymentMethod());

        // Verify actualCost updated on appointment
        assertEquals(BigDecimal.valueOf(15000.00), appointment.getActualCost());

        // Verify event published
        ArgumentCaptor<PaymentCompletedEvent> captor = ArgumentCaptor.forClass(PaymentCompletedEvent.class);
        verify(applicationEventPublisher, times(1)).publishEvent(captor.capture());
        assertEquals(888L, captor.getValue().getAppointmentId());
        assertEquals(userId, captor.getValue().getUserId());
        assertEquals(15000.00, captor.getValue().getAmount());
        assertEquals("CARD", captor.getValue().getPaymentMethod());
    }

    @Test
    @DisplayName("Adversarial: PayHere webhook payment commits and publishes event with correct details")
    void testPayHereWebhookPublishesEventSafely() throws Exception {
        Appointment appointment = Appointment.builder()
                .id(999L)
                .user(testUser)
                .status("PENDING_PAYMENT")
                .build();

        String orderId = "ORD-999";
        String amount = "5000.00";
        String currency = "LKR";
        String statusCode = "2";
        String secret = "secret_xyz";

        MessageDigest md = MessageDigest.getInstance("MD5");
        String secretHash = bytesToHex(md.digest(secret.getBytes(StandardCharsets.UTF_8))).toUpperCase();
        String plain = "123456" + orderId + amount + currency + statusCode + secretHash;
        String md5sig = bytesToHex(md.digest(plain.getBytes(StandardCharsets.UTF_8))).toUpperCase();

        when(appointmentRepository.findById(999L)).thenReturn(Optional.of(appointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> inv.getArgument(0));

        payHereService.handleNotification("123456", orderId, amount, currency, statusCode, md5sig, "TX-999", "MASTERCARD");

        assertEquals("CONFIRMED", appointment.getStatus());
        ArgumentCaptor<PaymentCompletedEvent> captor = ArgumentCaptor.forClass(PaymentCompletedEvent.class);
        verify(applicationEventPublisher, times(1)).publishEvent(captor.capture());
        assertEquals(999L, captor.getValue().getAppointmentId());
        assertEquals(userId, captor.getValue().getUserId());
        assertEquals(5000.00, captor.getValue().getAmount());
    }

    @Test
    @DisplayName("Adversarial: AsyncConfig custom AsyncUncaughtExceptionHandler handles unexpected errors without crash")
    void testAsyncUncaughtExceptionHandler() throws NoSuchMethodException {
        AsyncConfig asyncConfig = new AsyncConfig();
        Method testMethod = NotificationService.class.getMethod("onAppointmentCreated", AppointmentCreatedEvent.class);

        assertDoesNotThrow(() -> asyncConfig.getAsyncUncaughtExceptionHandler()
                .handleUncaughtException(new RuntimeException("Simulated unhandled async failure"), testMethod, "param1", 123));
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
