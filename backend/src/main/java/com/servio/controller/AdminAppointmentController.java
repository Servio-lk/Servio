package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.admin.AppointmentUpdateRequest;
import com.servio.entity.Appointment;
import com.servio.service.AdminAppointmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/appointments")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminAppointmentController {

    private final AdminAppointmentService adminAppointmentService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Appointment>>> getAllAppointments(
            @RequestParam(required = false) String status) {
        List<Appointment> appointments = status != null
                ? adminAppointmentService.getAppointmentsByStatus(status)
                : adminAppointmentService.getAllAppointments();
        return ResponseEntity.ok(ApiResponse.success("Appointments retrieved successfully", appointments));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Appointment>> getAppointmentById(@PathVariable Long id) {
        Appointment appointment = adminAppointmentService.getAppointmentById(id);
        return ResponseEntity.ok(ApiResponse.success("Appointment retrieved successfully", appointment));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<Appointment>> updateAppointment(
            @PathVariable Long id,
            @Valid @RequestBody AppointmentUpdateRequest request) {
        Appointment appointment = adminAppointmentService.updateAppointment(id, request);
        return ResponseEntity.ok(ApiResponse.success("Appointment updated successfully", appointment));
    }
}
