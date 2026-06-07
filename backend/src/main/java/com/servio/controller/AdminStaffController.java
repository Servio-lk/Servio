package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.MechanicScheduleService;
import com.servio.service.MechanicService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/staff")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminStaffController {
    private final MechanicService mechanicService;
    private final MechanicScheduleService scheduleService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<MechanicDto>>> getStaff() {
        return ResponseEntity.ok(ApiResponse.success("Staff retrieved successfully", mechanicService.getAllMechanics()));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MechanicDto>> createStaff(@RequestBody MechanicDto dto) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Staff created successfully", mechanicService.createMechanic(dto)));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to create staff", e.getMessage()));
        }
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<MechanicDto>> updateStaff(@PathVariable Long id, @RequestBody MechanicDto dto) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Staff updated successfully", mechanicService.updateMechanic(id, dto)));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update staff", e.getMessage()));
        }
    }

    @GetMapping("/{id}/schedule")
    public ResponseEntity<ApiResponse<MechanicScheduleResponse>> getSchedule(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Schedule retrieved successfully", scheduleService.getSchedule(id)));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve schedule", e.getMessage()));
        }
    }

    @PutMapping("/{id}/schedule")
    public ResponseEntity<ApiResponse<MechanicScheduleResponse>> updateSchedule(
            @PathVariable Long id,
            @RequestBody MechanicScheduleRequest request
    ) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Schedule updated successfully", scheduleService.updateSchedule(id, request)));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to update schedule", e.getMessage()));
        }
    }
}
