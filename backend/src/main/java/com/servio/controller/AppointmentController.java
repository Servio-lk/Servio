package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.AppointmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/appointments")
@RequiredArgsConstructor
public class AppointmentController {

        private final AppointmentService appointmentService;

        @PostMapping
        @PreAuthorize("isAuthenticated()")
        public ResponseEntity<ApiResponse<AppointmentDto>> createAppointment(
                        @RequestBody AppointmentRequest request,
                        Authentication authentication) {
                try {
                        AppointmentDto appointment = appointmentService.createAppointment(request, authentication);
                        return ResponseEntity.status(HttpStatus.CREATED)
                                        .body(ApiResponse.<AppointmentDto>builder()
                                                        .success(true)
                                                        .message("Appointment created successfully")
                                                        .data(appointment)
                                                        .build());
                } catch (RuntimeException e) {
                        if (e.getMessage().contains("already booked")) {
                                return ResponseEntity.status(HttpStatus.CONFLICT)
                                                .body(ApiResponse.<AppointmentDto>builder()
                                                                .success(false)
                                                                .message(e.getMessage())
                                                                .build());
                        }
                        throw e;
                }
        }

        @GetMapping
        public ResponseEntity<ApiResponse<List<AppointmentDto>>> getAllAppointments() {
                List<AppointmentDto> appointments = appointmentService.getAllAppointments();
                return ResponseEntity.ok(ApiResponse.<List<AppointmentDto>>builder()
                                .success(true)
                                .message("Appointments retrieved successfully")
                                .data(appointments)
                                .build());
        }

        @GetMapping("/recent")
        public ResponseEntity<ApiResponse<List<AppointmentDto>>> getRecentAppointments() {
                List<AppointmentDto> appointments = appointmentService.getRecentAppointments();
                return ResponseEntity.ok(ApiResponse.<List<AppointmentDto>>builder()
                                .success(true)
                                .message("Recent appointments retrieved successfully")
                                .data(appointments)
                                .build());
        }

        /**
         * Returns a list of already-booked start times (in "HH:mm" format) for the
         * given date.
         * Used by the customer booking UI to gray out unavailable slots.
         * No authentication required — this is public availability info.
         */
        @GetMapping("/booked-slots")
        public ResponseEntity<ApiResponse<List<String>>> getBookedSlots(
                        @RequestParam @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE) LocalDate date) {
                List<String> bookedSlots = appointmentService.getBookedSlotsForDate(date);
                return ResponseEntity.ok(ApiResponse.<List<String>>builder()
                                .success(true)
                                .message("Booked slots retrieved successfully")
                                .data(bookedSlots)
                                .build());
        }

        @GetMapping("/status/{status}")
        public ResponseEntity<ApiResponse<List<AppointmentDto>>> getAppointmentsByStatus(
                        @PathVariable String status) {
                List<AppointmentDto> appointments = appointmentService.getAppointmentsByStatus(status);
                return ResponseEntity.ok(ApiResponse.<List<AppointmentDto>>builder()
                                .success(true)
                                .message("Appointments retrieved successfully")
                                .data(appointments)
                                .build());
        }

        /**
         * Returns appointments for the currently logged-in user.
         * Reads user identity from the JWT — no userId in the URL needed.
         */
        @GetMapping("/my")
        @PreAuthorize("isAuthenticated()")
        public ResponseEntity<ApiResponse<List<AppointmentDto>>> getMyAppointments(
                        Authentication authentication) {
                List<AppointmentDto> appointments = appointmentService.getMyAppointments(authentication);
                return ResponseEntity.ok(ApiResponse.<List<AppointmentDto>>builder()
                                .success(true)
                                .message("My appointments retrieved successfully")
                                .data(appointments)
                                .build());
        }

        @GetMapping("/user/{userId}")
        public ResponseEntity<ApiResponse<List<AppointmentDto>>> getUserAppointments(
                        @PathVariable String userId) {
                List<AppointmentDto> appointments = appointmentService.getUserAppointments(userId);
                return ResponseEntity.ok(ApiResponse.<List<AppointmentDto>>builder()
                                .success(true)
                                .message("User appointments retrieved successfully")
                                .data(appointments)
                                .build());
        }

        @GetMapping("/{id}")
        public ResponseEntity<ApiResponse<AppointmentDto>> getAppointmentById(
                        @PathVariable Long id) {
                AppointmentDto appointment = appointmentService.getAppointmentById(id);
                return ResponseEntity.ok(ApiResponse.<AppointmentDto>builder()
                                .success(true)
                                .message("Appointment retrieved successfully")
                                .data(appointment)
                                .build());
        }

        @PatchMapping("/{id}/status")
        public ResponseEntity<ApiResponse<AppointmentDto>> updateAppointmentStatus(
                        @PathVariable Long id,
                        @RequestParam String status) {
                AppointmentDto appointment = appointmentService.updateAppointmentStatus(id, status);
                return ResponseEntity.ok(ApiResponse.<AppointmentDto>builder()
                                .success(true)
                                .message("Appointment status updated successfully")
                                .data(appointment)
                                .build());
        }

        @DeleteMapping("/{id}")
        public ResponseEntity<ApiResponse<Void>> deleteAppointment(@PathVariable Long id) {
                appointmentService.deleteAppointment(id);
                return ResponseEntity.ok(ApiResponse.<Void>builder()
                                .success(true)
                                .message("Appointment deleted successfully")
                                .build());
        }
}
