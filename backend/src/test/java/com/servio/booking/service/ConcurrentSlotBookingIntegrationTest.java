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
class ConcurrentSlotBookingIntegrationTest {

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

    @InjectMocks
    private AppointmentService appointmentService;

    private LocalDateTime targetSlot;
    private User testUser;

    @BeforeEach
    void setUp() {
        targetSlot = LocalDateTime.of(2026, 10, 1, 9, 0);
        testUser = User.builder()
                .id(UUID.randomUUID())
                .fullName("Concurrent Customer")
                .email("concurrent@servio.lk")
                .role(Role.USER)
                .build();
    }

    @Test
    @DisplayName("High-concurrency stress test: 20 simultaneous threads for same slot produces exactly 1 booking and 19 ConflictExceptions")
    void testTwentyConcurrentBookingRequests() throws InterruptedException {
        int threadCount = 20;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startGate = new CountDownLatch(1);
        CountDownLatch endGate = new CountDownLatch(threadCount);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger conflictCount = new AtomicInteger(0);
        AtomicBoolean slotOccupied = new AtomicBoolean(false);

        when(userRepository.findById(any(UUID.class))).thenReturn(Optional.of(testUser));

        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), anyList()))
                .thenAnswer(invocation -> {
                    if (slotOccupied.get()) {
                        return List.of(Appointment.builder()
                                .id(1L)
                                .appointmentDate(targetSlot)
                                .status("PENDING")
                                .build());
                    }
                    return Collections.emptyList();
                });

        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenAnswer(invocation -> {
                    if (slotOccupied.compareAndSet(false, true)) {
                        Appointment a = invocation.getArgument(0);
                        a.setId(999L);
                        return a;
                    } else {
                        throw new DataIntegrityViolationException("Unique constraint uq_appointment_active_slot violated");
                    }
                });

        for (int i = 0; i < threadCount; i++) {
            final UUID callerId = UUID.randomUUID();
            executor.submit(() -> {
                try {
                    startGate.await();
                    AppointmentRequest request = AppointmentRequest.builder()
                            .userId(callerId)
                            .appointmentDate(targetSlot)
                            .serviceType("Full Service")
                            .build();

                    AppointmentDto dto = appointmentService.createAppointment(request, null);
                    if (dto != null && dto.getId() != null) {
                        successCount.incrementAndGet();
                    }
                } catch (ConflictException ce) {
                    assertEquals("This time slot is already booked. Please choose another time.", ce.getMessage());
                    conflictCount.incrementAndGet();
                } catch (Exception e) {
                    fail("Unexpected exception: " + e.getMessage());
                } finally {
                    endGate.countDown();
                }
            });
        }

        startGate.countDown();
        boolean finished = endGate.await(10, TimeUnit.SECONDS);
        executor.shutdown();

        assertTrue(finished, "All 20 concurrent threads should finish within timeout");
        assertEquals(1, successCount.get(), "Exactly 1 concurrent request must win the slot");
        assertEquals(19, conflictCount.get(), "All 19 losing requests must receive ConflictException");
    }

    @Test
    @DisplayName("Slot release lifecycle: cancelled appointment allows subsequent booking to acquire the slot")
    void testSlotReleaseAfterCancellation() {
        // Step 1: Slot is free, first booking succeeds
        AppointmentRequest req1 = AppointmentRequest.builder()
                .userId(testUser.getId())
                .appointmentDate(targetSlot)
                .serviceType("Brake Service")
                .build();

        Appointment appt1 = Appointment.builder()
                .id(501L)
                .user(testUser)
                .appointmentDate(targetSlot)
                .status("PENDING")
                .build();

        when(userRepository.findById(testUser.getId())).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), anyList()))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.saveAndFlush(any(Appointment.class))).thenReturn(appt1);

        AppointmentDto dto1 = appointmentService.createAppointment(req1, null);
        assertNotNull(dto1);
        assertEquals(501L, dto1.getId());

        // Step 2: Slot is now occupied, second booking fails
        AppointmentRequest req2 = AppointmentRequest.builder()
                .userId(testUser.getId())
                .appointmentDate(targetSlot)
                .serviceType("Oil Change")
                .build();

        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), anyList()))
                .thenReturn(List.of(appt1));

        ConflictException conflictEx = assertThrows(ConflictException.class, () ->
                appointmentService.createAppointment(req2, null));
        assertEquals("This time slot is already booked. Please choose another time.", conflictEx.getMessage());

        // Step 3: Appointment 1 is cancelled
        appt1.setStatus("CANCELLED");

        // Step 4: After cancellation, findForUpdate returns empty list (because CANCELLED is excluded), so new booking succeeds
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(targetSlot), anyList()))
                .thenReturn(Collections.emptyList());

        Appointment appt2 = Appointment.builder()
                .id(502L)
                .user(testUser)
                .appointmentDate(targetSlot)
                .status("PENDING")
                .build();
        when(appointmentRepository.saveAndFlush(any(Appointment.class))).thenReturn(appt2);

        AppointmentDto dto2 = appointmentService.createAppointment(req2, null);
        assertNotNull(dto2);
        assertEquals(502L, dto2.getId());
    }
}
