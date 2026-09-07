package com.servio.booking.service;

import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.dto.AppointmentRequest;
import com.servio.booking.entity.Appointment;
import com.servio.booking.entity.Vehicle;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.booking.repository.VehicleRepository;
import com.servio.common.event.AppointmentCreatedEvent;
import com.servio.common.event.RepairStatusChangedEvent;
import com.servio.common.exception.ConflictException;
import com.servio.common.exception.ResourceNotFoundException;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AppointmentServiceTest {

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
    private LocalDateTime testDate;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
        testUser = User.builder()
                .id(testUserId)
                .email("test@example.com")
                .fullName("Test Customer")
                .role(Role.USER)
                .build();
        testDate = LocalDateTime.now().plusDays(2);
    }

    @Test
    @DisplayName("createAppointment throws ConflictException when slot is already occupied")
    void testCreateAppointment_slotAlreadyBooked_throwsConflictException() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(testUserId)
                .appointmentDate(testDate)
                .serviceType("Full Service")
                .build();

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(testDate), anyList()))
                .thenReturn(List.of(Appointment.builder().id(1L).appointmentDate(testDate).status("CONFIRMED").build()));

        assertThrows(ConflictException.class, () -> appointmentService.createAppointment(request, null));
        verify(appointmentRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("createAppointment saves appointment and emits domain event on success")
    void testCreateAppointment_success() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(testUserId)
                .appointmentDate(testDate)
                .serviceType("Oil Change")
                .estimatedCost(BigDecimal.valueOf(5000))
                .build();

        Appointment savedAppointment = Appointment.builder()
                .id(100L)
                .user(testUser)
                .appointmentDate(testDate)
                .serviceType("Oil Change")
                .estimatedCost(BigDecimal.valueOf(5000))
                .status("PENDING")
                .build();

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(testDate), anyList()))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.saveAndFlush(any(Appointment.class))).thenReturn(savedAppointment);

        AppointmentDto result = appointmentService.createAppointment(request, null);

        assertNotNull(result);
        assertEquals(100L, result.getId());
        assertEquals(testUserId, result.getUserId());
        assertEquals("PENDING", result.getStatus());
        assertEquals("Oil Change", result.getServiceType());
        verify(appointmentRepository, times(1)).saveAndFlush(any(Appointment.class));
        verify(applicationEventPublisher, times(1)).publishEvent(any(AppointmentCreatedEvent.class));
    }

    @Test
    @DisplayName("createAppointment maps DataIntegrityViolationException to ConflictException")
    void testCreateAppointment_dataIntegrityViolation_throwsConflictException() {
        AppointmentRequest request = AppointmentRequest.builder()
                .userId(testUserId)
                .appointmentDate(testDate)
                .serviceType("Oil Change")
                .build();

        when(userRepository.findById(testUserId)).thenReturn(Optional.of(testUser));
        when(appointmentRepository.findForUpdateByAppointmentDateAndStatusNotIn(eq(testDate), anyList()))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.saveAndFlush(any(Appointment.class)))
                .thenThrow(new org.springframework.dao.DataIntegrityViolationException("Unique index violation on uq_appointment_active_slot"));

        ConflictException ex = assertThrows(ConflictException.class, () -> appointmentService.createAppointment(request, null));
        assertEquals("This time slot is already booked. Please choose another time.", ex.getMessage());
    }

    @Test
    @DisplayName("getAppointmentById throws ResourceNotFoundException when not found")
    void testGetAppointmentById_notFound_throwsResourceNotFoundException() {
        when(appointmentRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> appointmentService.getAppointmentById(999L));
    }

    @Test
    @DisplayName("getMyAppointments returns user-scoped appointments for authenticated user")
    void testGetMyAppointments_success() {
        when(authentication.isAuthenticated()).thenReturn(true);
        when(authentication.getPrincipal()).thenReturn(testUserId.toString());

        Appointment appointment = Appointment.builder()
                .id(200L)
                .user(testUser)
                .appointmentDate(testDate)
                .serviceType("Periodic Maintenance")
                .status("CONFIRMED")
                .build();

        when(appointmentRepository.findUserAppointmentsOrderByDate(testUserId))
                .thenReturn(List.of(appointment));

        List<AppointmentDto> result = appointmentService.getMyAppointments(authentication);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(200L, result.get(0).getId());
        assertEquals(testUserId, result.get(0).getUserId());
    }

    @Test
    @DisplayName("getMyAppointments throws SecurityException if not authenticated")
    void testGetMyAppointments_unauthenticated() {
        when(authentication.isAuthenticated()).thenReturn(false);

        assertThrows(SecurityException.class, () -> appointmentService.getMyAppointments(authentication));
    }

    @Test
    @DisplayName("cancelOwnAppointment cancels appointment when caller is owner")
    void testCancelOwnAppointment_success() {
        Appointment appointment = Appointment.builder()
                .id(300L)
                .user(testUser)
                .appointmentDate(testDate)
                .status("PENDING")
                .build();

        when(appointmentRepository.findById(300L)).thenReturn(Optional.of(appointment));
        when(authentication.isAuthenticated()).thenReturn(true);
        when(authentication.getPrincipal()).thenReturn(testUserId.toString());
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(inv -> inv.getArgument(0));

        AppointmentDto result = appointmentService.cancelOwnAppointment(300L, authentication);

        assertNotNull(result);
        assertEquals("CANCELLED", result.getStatus());
        verify(appointmentRepository, times(1)).save(appointment);
    }

    @Test
    @DisplayName("cancelOwnAppointment throws SecurityException when caller is not owner")
    void testCancelOwnAppointment_notOwner_throwsSecurityException() {
        UUID otherUserId = UUID.randomUUID();
        User otherUser = User.builder().id(otherUserId).build();

        Appointment appointment = Appointment.builder()
                .id(301L)
                .user(otherUser)
                .status("PENDING")
                .build();

        when(appointmentRepository.findById(301L)).thenReturn(Optional.of(appointment));
        when(authentication.isAuthenticated()).thenReturn(true);
        when(authentication.getPrincipal()).thenReturn(testUserId.toString());

        assertThrows(SecurityException.class, () -> appointmentService.cancelOwnAppointment(301L, authentication));
        verify(appointmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("updateAppointmentStatus updates status and emits RepairStatusChangedEvent")
    void testUpdateAppointmentStatus_success() {
        Appointment appointment = Appointment.builder()
                .id(400L)
                .user(testUser)
                .serviceType("Tire Replacement")
                .status("CONFIRMED")
                .build();

        when(appointmentRepository.findById(400L)).thenReturn(Optional.of(appointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(inv -> inv.getArgument(0));

        AppointmentDto result = appointmentService.updateAppointmentStatus(400L, "COMPLETED");

        assertNotNull(result);
        assertEquals("COMPLETED", result.getStatus());
        verify(applicationEventPublisher, times(1)).publishEvent(any(RepairStatusChangedEvent.class));
    }

    @Test
    @DisplayName("getBookedSlotsForDate returns formatted HH:mm strings")
    void testGetBookedSlotsForDate() {
        LocalDate date = LocalDate.of(2026, 9, 15);
        LocalDateTime slot1 = LocalDateTime.of(2026, 9, 15, 9, 30);
        LocalDateTime slot2 = LocalDateTime.of(2026, 9, 15, 14, 0);

        when(appointmentRepository.findBookedSlotsForDate(any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(List.of(
                        Appointment.builder().appointmentDate(slot1).build(),
                        Appointment.builder().appointmentDate(slot2).build()
                ));

        List<String> bookedSlots = appointmentService.getBookedSlotsForDate(date);

        assertNotNull(bookedSlots);
        assertEquals(2, bookedSlots.size());
        assertEquals("09:30", bookedSlots.get(0));
        assertEquals("14:00", bookedSlots.get(1));
    }
}
