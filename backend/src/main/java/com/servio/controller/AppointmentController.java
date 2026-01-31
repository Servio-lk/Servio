package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.AppointmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/appointments")
@RequiredArgsConstructor
public class AppointmentController {
    
    private final AppointmentService appointmentService;
    
    @PostMapping
    public ResponseEntity<ApiResponse<AppointmentDto>> createAppointment(
        @RequestBody AppointmentRequest request
    ) {
        try {
            AppointmentDto appointment = appointmentService.createAppointment(request);
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
    
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<AppointmentDto>>> getAppointmentsByStatus(
        @PathVariable String status
    ) {
        List<AppointmentDto> appointments = appointmentService.getAppointmentsByStatus(status);
        return ResponseEntity.ok(ApiResponse.<List<AppointmentDto>>builder()
            .success(true)
            .message("Appointments retrieved successfully")
            .data(appointments)
            .build());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AppointmentDto>> getAppointmentById(
        @PathVariable Long id
    ) {
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
        @RequestParam String status
    ) {
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
