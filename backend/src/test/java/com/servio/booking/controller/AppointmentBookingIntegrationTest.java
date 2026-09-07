package com.servio.booking.controller;

import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.dto.AppointmentRequest;
import com.servio.booking.service.AppointmentService;
import com.servio.common.dto.ApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AppointmentBookingIntegrationTest {

    @Mock
    private AppointmentService appointmentService;
    @Mock
    private Authentication authentication;

    @InjectMocks
    private AppointmentController appointmentController;

    private UUID userId;
    private LocalDateTime appointmentDate;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        appointmentDate = LocalDateTime.of(2026, 9, 20, 10, 0);
    }

    @Test
    @DisplayName("POST /api/appointments creates appointment and returns 201 Created")
    void testCreateAppointment() {
        AppointmentRequest request = AppointmentRequest.builder()
                .serviceType("Full Inspection")
                .appointmentDate(appointmentDate)
                .build();

        AppointmentDto dto = AppointmentDto.builder()
                .id(101L)
                .userId(userId)
                .serviceType("Full Inspection")
                .appointmentDate(appointmentDate)
                .status("PENDING")
                .build();

        when(appointmentService.createAppointment(eq(request), eq(authentication))).thenReturn(dto);

        ResponseEntity<ApiResponse<AppointmentDto>> response =
                appointmentController.createAppointment(request, authentication);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(101L, response.getBody().getData().getId());
        assertEquals("PENDING", response.getBody().getData().getStatus());
    }

    @Test
    @DisplayName("GET /api/appointments/my returns list of appointments for authenticated user")
    void testGetMyAppointments() {
        AppointmentDto dto = AppointmentDto.builder()
                .id(101L)
                .userId(userId)
                .serviceType("Oil Change")
                .status("CONFIRMED")
                .build();

        when(appointmentService.getMyAppointments(authentication)).thenReturn(List.of(dto));

        ResponseEntity<ApiResponse<List<AppointmentDto>>> response =
                appointmentController.getMyAppointments(authentication);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(1, response.getBody().getData().size());
        assertEquals(101L, response.getBody().getData().get(0).getId());
    }

    @Test
    @DisplayName("GET /api/appointments/booked-slots returns list of booked slot strings without auth")
    void testGetBookedSlots() {
        LocalDate date = LocalDate.of(2026, 9, 20);
        when(appointmentService.getBookedSlotsForDate(date)).thenReturn(List.of("10:00", "14:00"));

        ResponseEntity<ApiResponse<List<String>>> response = appointmentController.getBookedSlots(date);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(2, response.getBody().getData().size());
        assertTrue(response.getBody().getData().contains("10:00"));
        assertTrue(response.getBody().getData().contains("14:00"));
    }

    @Test
    @DisplayName("POST /api/appointments/{id}/cancel allows cancelling owned appointment")
    void testCancelOwnAppointment() {
        AppointmentDto dto = AppointmentDto.builder()
                .id(105L)
                .userId(userId)
                .status("CANCELLED")
                .build();

        when(appointmentService.cancelOwnAppointment(105L, authentication)).thenReturn(dto);

        ResponseEntity<ApiResponse<AppointmentDto>> response =
                appointmentController.cancelOwnAppointment(105L, authentication);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("CANCELLED", response.getBody().getData().getStatus());
    }

    @Test
    @DisplayName("PATCH /api/appointments/{id}/status updates appointment status")
    void testUpdateAppointmentStatus() {
        AppointmentDto dto = AppointmentDto.builder()
                .id(106L)
                .status("IN_PROGRESS")
                .build();

        when(appointmentService.updateAppointmentStatus(106L, "IN_PROGRESS")).thenReturn(dto);

        ResponseEntity<ApiResponse<AppointmentDto>> response =
                appointmentController.updateAppointmentStatus(106L, "IN_PROGRESS");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("IN_PROGRESS", response.getBody().getData().getStatus());
    }
}
