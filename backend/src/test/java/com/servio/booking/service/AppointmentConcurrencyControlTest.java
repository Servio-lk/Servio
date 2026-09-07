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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;

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
class AppointmentConcurrencyControlTest {

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

    private UUID userId;
    private User testUser;
    private LocalDateTime targetSlot;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        testUser = User.builder()
                .id(userId)
                .email("customer@servio.lk")
                .fullName("Jane Doe")
                .role(Role.USER)
                .build();
        targetSlot = LocalDateTime.of(2026, 9, 15, 10, 0);
    }

    @Test
    @DisplayName("Pessimistic lock query findForUpdateByAppointmentDateAndStatusNotIn is invoked during booking")
    void testPessimisticLockQueryInvoked() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(userId)
                .appointmentDate(targetSlot)
                .serviceType("Periodic Maintenance")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), eq(List.of("CANCELLED"))))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenAnswer(invocation -> {
                    Appointment appt = invocation.getArgument(0);
                    appt.setId(1L);
                    return appt;
                });

        AppointmentDto dto = appointmentService.createAppointment(request, null);

        assertNotNull(dto);
        assertEquals(1L, dto.getId());
        verify(appointmentRepository, times(1))
                .findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), eq(List.of("CANCELLED")));
        verify(appointmentRepository, times(1)).saveAndFlush(any(Appointment.class));
    }

    @Test
    @DisplayName("Pre-existing active slot throws ConflictException with RFC 7807 message")
    void testExistingSlotThrowsConflictException() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(userId)
                .appointmentDate(targetSlot)
                .serviceType("Periodic Maintenance")
                .build();

        Appointment existingAppointment = Appointment.builder()
                .id(99L)
                .appointmentDate(targetSlot)
                .status("CONFIRMED")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), eq(List.of("CANCELLED"))))
                .thenReturn(List.of(existingAppointment));

        ConflictException ex = assertThrows(ConflictException.class, () -> appointmentService.createAppointment(request, null));
        assertEquals("This time slot is already booked. Please choose another time.", ex.getMessage());
        verify(appointmentRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("Database unique constraint violation on saveAndFlush is mapped cleanly to ConflictException")
    void testDatabaseConstraintViolationThrowsConflict() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(userId)
                .appointmentDate(targetSlot)
                .serviceType("Periodic Maintenance")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), anyList()))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenThrow(new DataIntegrityViolationException("ERROR: duplicate key value violates unique constraint \"uq_appointment_active_slot\""));

        ConflictException ex = assertThrows(ConflictException.class, () -> appointmentService.createAppointment(request, null));
        assertEquals("This time slot is already booked. Please choose another time.", ex.getMessage());
    }

    @Test
    @DisplayName("Simulated 10 concurrent requests for same time slot results in exactly 1 success and 9 conflicts")
    void testConcurrentBookingForSameSlot() throws InterruptedException {
        int threadCount = 10;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch finishLatch = new CountDownLatch(threadCount);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger conflictCount = new AtomicInteger(0);
        AtomicBoolean slotAcquired = new AtomicBoolean(false);

        when(userRepository.findById(any(UUID.class))).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), anyList()))
                .thenAnswer(inv -> {
                    // If slot has been acquired by another thread, return existing appointment
                    if (slotAcquired.get()) {
                        return List.of(Appointment.builder().id(101L).appointmentDate(targetSlot).status("PENDING").build());
                    }
                    return Collections.emptyList();
                });

        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenAnswer(inv -> {
                    // Atomically claim the slot
                    if (slotAcquired.compareAndSet(false, true)) {
                        Appointment appt = inv.getArgument(0);
                        appt.setId(101L);
                        return appt;
                    } else {
                        // Simulated racing insert hitting the unique constraint
                        throw new DataIntegrityViolationException("Unique constraint uq_appointment_active_slot violated");
                    }
                });

        for (int i = 0; i < threadCount; i++) {
            final UUID callerUserId = UUID.randomUUID();
            executor.submit(() -> {
                try {
                    startLatch.await();
                    AppointmentRequest request = AppointmentRequest.builder()
                            .userId(callerUserId)
                            .appointmentDate(targetSlot)
                            .serviceType("Brake Service")
                            .build();

                    AppointmentDto result = appointmentService.createAppointment(request, null);
                    if (result != null && result.getId() != null) {
                        successCount.incrementAndGet();
                    }
                } catch (ConflictException ce) {
                    assertEquals("This time slot is already booked. Please choose another time.", ce.getMessage());
                    conflictCount.incrementAndGet();
                } catch (Exception e) {
                    fail("Unexpected exception: " + e.getMessage());
                } finally {
                    finishLatch.countDown();
                }
            });
        }

        // Fire all threads simultaneously
        startLatch.countDown();
        boolean completed = finishLatch.await(5, TimeUnit.SECONDS);
        executor.shutdown();

        assertTrue(completed, "All concurrent booking requests should complete within timeout");
        assertEquals(1, successCount.get(), "Exactly 1 booking request must succeed");
        assertEquals(9, conflictCount.get(), "Remaining 9 booking requests must be rejected with ConflictException");
    }
}
