package com.servio.controller;

import com.servio.dto.ApiResponse;
import com.servio.dto.AppointmentDto;
import com.servio.dto.admin.AppointmentUpdateRequest;
import com.servio.entity.Appointment;
import com.servio.service.AdminAppointmentService;
import com.servio.service.AppointmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/appointments")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminAppointmentController {

    private final AdminAppointmentService adminAppointmentService;
    private final AppointmentService appointmentService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AppointmentDto>>> getAllAppointments(
            @RequestParam(required = false) String status) {
        List<Appointment> appointments = status != null
                ? adminAppointmentService.getAppointmentsByStatus(status)
                : adminAppointmentService.getAllAppointments();

        // Convert to DTOs to avoid lazy loading issues
        List<AppointmentDto> appointmentDtos = appointments.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success("Appointments retrieved successfully", appointmentDtos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AppointmentDto>> getAppointmentById(@PathVariable Long id) {
        Appointment appointment = adminAppointmentService.getAppointmentById(id);
        AppointmentDto appointmentDto = convertToDto(appointment);
        return ResponseEntity.ok(ApiResponse.success("Appointment retrieved successfully", appointmentDto));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<AppointmentDto>> updateAppointment(
            @PathVariable Long id,
            @Valid @RequestBody AppointmentUpdateRequest request) {
        Appointment appointment = adminAppointmentService.updateAppointment(id, request);
        AppointmentDto appointmentDto = convertToDto(appointment);
        return ResponseEntity.ok(ApiResponse.success("Appointment updated successfully", appointmentDto));
    }

    private AppointmentDto convertToDto(Appointment appointment) {
        return AppointmentDto.builder()
                .id(appointment.getId())
                .userId(appointment.getUser().getId())
                .userName(appointment.getUser().getFullName())
                .userEmail(appointment.getUser().getEmail())
                .vehicleId(appointment.getVehicle() != null ? appointment.getVehicle().getId() : null)
                .vehicleMake(appointment.getVehicle() != null ? appointment.getVehicle().getMake() : null)
                .vehicleModel(appointment.getVehicle() != null ? appointment.getVehicle().getModel() : null)
                .serviceType(appointment.getServiceType())
                .appointmentDate(appointment.getAppointmentDate())
                .status(appointment.getStatus())
                .location(appointment.getLocation())
                .notes(appointment.getNotes())
                .estimatedCost(appointment.getEstimatedCost())
                .actualCost(appointment.getActualCost())
                .createdAt(appointment.getCreatedAt())
                .updatedAt(appointment.getUpdatedAt())
                .build();
    }
}
