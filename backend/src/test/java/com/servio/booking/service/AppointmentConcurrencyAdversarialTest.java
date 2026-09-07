package com.servio.booking.service;

import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.dto.AppointmentRequest;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.booking.repository.VehicleRepository;
import com.servio.common.exception.ConflictException;
import com.servio.notification.service.AppointmentEventPublisher;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;

import java.lang.reflect.Method;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AppointmentConcurrencyAdversarialTest {

    @Mock
    private AppointmentRepository appointmentRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private VehicleRepository vehicleRepository;
    @Mock
    private JdbcTemplate jdbcTemplate;
    @Mock
    private EntityManager entityManager;
    @Mock
    private AppointmentEventPublisher eventPublisher;
    @Mock
    private ApplicationEventPublisher applicationEventPublisher;
    @Mock
    private Authentication authentication;

    @InjectMocks
    private AppointmentService appointmentService;

    private UUID testUserId;
    private User testUser;
    private LocalDateTime targetSlot;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
        testUser = User.builder()
                .id(testUserId)
                .email("adversary@servio.lk")
                .fullName("Adversarial Tester")
                .role(Role.USER)
                .build();
        targetSlot = LocalDateTime.of(2026, 10, 1, 9, 0);
    }

    @Test
    @DisplayName("Adversarial: 50 concurrent threads racing for the exact same slot -> exactly 1 succeeds, 49 fail with 409 Conflict")
    void testMassive50ThreadConcurrentBookingForSingleSlot() throws InterruptedException {
        int threadCount = 50;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch finishLatch = new CountDownLatch(threadCount);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger conflictCount = new AtomicInteger(0);
        AtomicInteger unexpectedErrorCount = new AtomicInteger(0);
        AtomicBoolean slotClaimed = new AtomicBoolean(false);

        when(userRepository.findById(any(UUID.class))).thenReturn(Optional.of(testUser));

        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), anyList()))
                .thenAnswer(inv -> {
                    if (slotClaimed.get()) {
                        return List.of(Appointment.builder().id(999L).appointmentDate(targetSlot).status("CONFIRMED").build());
                    }
                    return Collections.emptyList();
                });

        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenAnswer(inv -> {
                    if (slotClaimed.compareAndSet(false, true)) {
                        Appointment appt = inv.getArgument(0);
                        appt.setId(999L);
                        return appt;
                    } else {
                        throw new DataIntegrityViolationException("duplicate key violates unique index uq_appointment_active_slot");
                    }
                });

        for (int i = 0; i < threadCount; i++) {
            final UUID callerId = UUID.randomUUID();
            executor.submit(() -> {
                try {
                    startLatch.await();
                    AppointmentRequest request = AppointmentRequest.builder()
                            .userId(callerId)
                            .appointmentDate(targetSlot)
                            .serviceType("Engine Overhaul")
                            .build();

                    AppointmentDto result = appointmentService.createAppointment(request, null);
                    if (result != null && result.getId() != null) {
                        successCount.incrementAndGet();
                    }
                } catch (ConflictException ce) {
                    if ("This time slot is already booked. Please choose another time.".equals(ce.getMessage())) {
                        conflictCount.incrementAndGet();
                    } else {
                        unexpectedErrorCount.incrementAndGet();
                    }
                } catch (Exception e) {
                    unexpectedErrorCount.incrementAndGet();
                } finally {
                    finishLatch.countDown();
                }
            });
        }

        // Trigger simultaneous start
        startLatch.countDown();
        boolean completed = finishLatch.await(10, TimeUnit.SECONDS);
        executor.shutdown();

        assertTrue(completed, "All 50 threads should complete within 10 seconds");
        assertEquals(1, successCount.get(), "Exactly 1 thread must acquire the slot");
        assertEquals(49, conflictCount.get(), "49 threads must be rejected with ConflictException");
        assertEquals(0, unexpectedErrorCount.get(), "Zero unexpected errors should occur");
    }

    @Test
    @DisplayName("Adversarial: Multi-slot concurrency: 50 threads across 5 distinct slots -> exactly 5 succeed (1/slot) and 45 fail")
    void testMultiSlotConcurrentBooking50ThreadsAcross5Slots() throws InterruptedException {
        int threadCount = 50;
        int slotCount = 5;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch finishLatch = new CountDownLatch(threadCount);

        List<LocalDateTime> slots = new ArrayList<>();
        Map<LocalDateTime, AtomicBoolean> slotClaims = new ConcurrentHashMap<>();
        for (int i = 0; i < slotCount; i++) {
            LocalDateTime slot = LocalDateTime.of(2026, 10, 2, 9 + i, 0);
            slots.add(slot);
            slotClaims.put(slot, new AtomicBoolean(false));
        }

        AtomicInteger totalSuccesses = new AtomicInteger(0);
        AtomicInteger totalConflicts = new AtomicInteger(0);

        when(userRepository.findById(any(UUID.class))).thenReturn(Optional.of(testUser));

        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(any(LocalDateTime.class), anyList()))
                .thenAnswer(inv -> {
                    LocalDateTime slot = inv.getArgument(0);
                    AtomicBoolean claim = slotClaims.get(slot);
                    if (claim != null && claim.get()) {
                        return List.of(Appointment.builder().id(123L).appointmentDate(slot).status("PENDING").build());
                    }
                    return Collections.emptyList();
                });

        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenAnswer(inv -> {
                    Appointment appt = inv.getArgument(0);
                    LocalDateTime slot = appt.getAppointmentDate();
                    AtomicBoolean claim = slotClaims.get(slot);
                    if (claim != null && claim.compareAndSet(false, true)) {
                        appt.setId(1000L + slot.getHour());
                        return appt;
                    } else {
                        throw new DataIntegrityViolationException("Unique constraint uq_appointment_active_slot violated");
                    }
                });

        for (int i = 0; i < threadCount; i++) {
            final LocalDateTime chosenSlot = slots.get(i % slotCount);
            final UUID callerId = UUID.randomUUID();
            executor.submit(() -> {
                try {
                    startLatch.await();
                    AppointmentRequest request = AppointmentRequest.builder()
                            .userId(callerId)
                            .appointmentDate(chosenSlot)
                            .serviceType("Service Slot " + chosenSlot.getHour())
                            .build();

                    AppointmentDto result = appointmentService.createAppointment(request, null);
                    if (result != null && result.getId() != null) {
                        totalSuccesses.incrementAndGet();
                    }
                } catch (ConflictException ce) {
                    totalConflicts.incrementAndGet();
                } catch (Exception ignored) {
                } finally {
                    finishLatch.countDown();
                }
            });
        }

        startLatch.countDown();
        boolean completed = finishLatch.await(10, TimeUnit.SECONDS);
        executor.shutdown();

        assertTrue(completed);
        assertEquals(5, totalSuccesses.get(), "Exactly 5 bookings (1 per slot) must succeed");
        assertEquals(45, totalConflicts.get(), "Remaining 45 bookings must fail with 409 Conflict");
    }

    @Test
    @DisplayName("Adversarial: CANCELLED appointment does NOT block slot re-booking")
    void testCancelledAppointmentAllowsRebooking() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(testUserId)
                .appointmentDate(targetSlot)
                .serviceType("Battery Service")
                .build();

        // Repository returns empty list because CANCELLED status is excluded
        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), eq(List.of("CANCELLED"))))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenAnswer(inv -> {
                    Appointment appt = inv.getArgument(0);
                    appt.setId(200L);
                    return appt;
                });

        AppointmentDto dto = appointmentService.createAppointment(request, null);

        assertNotNull(dto);
        assertEquals(200L, dto.getId());
        verify(appointmentRepository, times(1)).saveAndFlush(any(Appointment.class));
    }

    @ParameterizedTest
    @ValueSource(strings = {"PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "PENDING_PAYMENT"})
    @DisplayName("Adversarial: Active appointment statuses all block re-booking of the slot with ConflictException")
    void testActiveStatusesBlockRebooking(String status) {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(testUserId)
                .appointmentDate(targetSlot)
                .serviceType("Tire Replacement")
                .build();

        Appointment existingActive = Appointment.builder()
                .id(300L)
                .appointmentDate(targetSlot)
                .status(status)
                .build();

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), eq(List.of("CANCELLED"))))
                .thenReturn(List.of(existingActive));

        ConflictException ex = assertThrows(ConflictException.class, () ->
                appointmentService.createAppointment(request, null));

        assertEquals("This time slot is already booked. Please choose another time.", ex.getMessage());
        verify(appointmentRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("Adversarial: Verify AppointmentRepository has @Lock(PESSIMISTIC_WRITE) on slot query method")
    void testPessimisticWriteLockAnnotationPresentOnRepository() throws NoSuchMethodException {
        Method method = AppointmentRepository.class.getMethod(
                "findForUpdateByAppointmentDateAndStatusNotIn",
                LocalDateTime.class,
                List.class
        );

        assertNotNull(method);
        Lock lockAnnotation = method.getAnnotation(Lock.class);
        assertNotNull(lockAnnotation, "Method findForUpdateByAppointmentDateAndStatusNotIn must be annotated with @Lock");
        assertEquals(LockModeType.PESSIMISTIC_WRITE, lockAnnotation.value(), "LockModeType must be PESSIMISTIC_WRITE");
    }
}
