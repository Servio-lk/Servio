package com.servio.admin.controller;
import com.servio.common.dto.ApiResponse;
import com.servio.admin.dto.MechanicDto;
import com.servio.admin.dto.MechanicScheduleResponse;
import com.servio.admin.dto.MechanicScheduleRequest;
import com.servio.admin.dto.StaffFileUploadResponse;

import com.servio.admin.service.MechanicScheduleService;
import com.servio.admin.service.MechanicService;
import com.servio.admin.service.StaffCloudinaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/admin/staff")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ADMIN')")
public class AdminStaffController {
    private final MechanicService mechanicService;
    private final MechanicScheduleService scheduleService;
    private final StaffCloudinaryService staffCloudinaryService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<MechanicDto>>> getStaff() {
        return ResponseEntity.ok(ApiResponse.success("Staff retrieved successfully", mechanicService.getAllMechanics()));
    }

    @GetMapping("/next-employee-code")
    public ResponseEntity<ApiResponse<String>> getNextEmployeeCode() {
        return ResponseEntity.ok(ApiResponse.success("Employee code generated successfully", mechanicService.generateNextEmployeeCode()));
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

    @PostMapping(value = "/uploads", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<StaffFileUploadResponse>> uploadStaffFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam String documentType,
            @RequestParam(required = false) Long staffId
    ) {
        try {
            StaffFileUploadResponse uploaded = staffCloudinaryService.uploadStaffFile(file, documentType, staffId);
            return ResponseEntity.ok(ApiResponse.success("File uploaded successfully", uploaded));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to upload file", e.getMessage()));
        }
    }
}
