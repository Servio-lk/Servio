package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.ServiceRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ServiceRecordController {
    
    private final ServiceRecordService serviceRecordService;
    
    @PostMapping("/servicerecords")
    public ResponseEntity<ApiResponse<ServiceRecordDto>> createServiceRecord(
        @RequestBody ServiceRecordRequest request
    ) {
        ServiceRecordDto record = serviceRecordService.createServiceRecord(request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.<ServiceRecordDto>builder()
                .success(true)
                .message("Service record created successfully")
                .data(record)
                .build());
    }
    
    // Note: Kept as admin-likely endpoint or general list, adjusted path for consistency
    @GetMapping("/servicerecords")
    public ResponseEntity<ApiResponse<List<ServiceRecordDto>>> getAllServiceRecords() {
        List<ServiceRecordDto> records = serviceRecordService.getAllServiceRecords();
        return ResponseEntity.ok(ApiResponse.<List<ServiceRecordDto>>builder()
            .success(true)
            .message("Service records retrieved successfully")
            .data(records)
            .build());
    }
    
    @GetMapping("/vehicles/{vehicleId}/servicerecords")
    public ResponseEntity<ApiResponse<List<ServiceRecordDto>>> getServiceRecordsByVehicleId(
        @PathVariable Long vehicleId
    ) {
        List<ServiceRecordDto> records = serviceRecordService.getServiceRecordsByVehicleId(vehicleId);
        return ResponseEntity.ok(ApiResponse.<List<ServiceRecordDto>>builder()
            .success(true)
            .message("Vehicle service records retrieved successfully")
            .data(records)
            .build());
    }
    
    @GetMapping("/servicerecords/recent")
    public ResponseEntity<ApiResponse<List<ServiceRecordDto>>> getRecentServiceRecords(
        @RequestParam(defaultValue = "10") int limit
    ) {
        List<ServiceRecordDto> records = serviceRecordService.getRecentServiceRecords(limit);
        return ResponseEntity.ok(ApiResponse.<List<ServiceRecordDto>>builder()
            .success(true)
            .message("Recent service records retrieved successfully")
            .data(records)
            .build());
    }
    
    @GetMapping("/servicerecords/{id}")
    public ResponseEntity<ApiResponse<ServiceRecordDto>> getServiceRecordById(@PathVariable Long id) {
        ServiceRecordDto record = serviceRecordService.getServiceRecordById(id);
        return ResponseEntity.ok(ApiResponse.<ServiceRecordDto>builder()
            .success(true)
            .message("Service record retrieved successfully")
            .data(record)
            .build());
    }
    
    @GetMapping("/vehicles/{vehicleId}/history")
    public ResponseEntity<ApiResponse<ServiceHistoryDto>> getVehicleServiceHistory(
        @PathVariable Long vehicleId
    ) {
        ServiceHistoryDto history = serviceRecordService.getVehicleServiceHistory(vehicleId);
        return ResponseEntity.ok(ApiResponse.<ServiceHistoryDto>builder()
            .success(true)
            .message("Vehicle service history retrieved successfully")
            .data(history)
            .build());
    }
    
    @GetMapping("/vehicles/{vehicleId}/reminders")
    public ResponseEntity<ApiResponse<List<MaintenanceReminderDto>>> getMaintenanceReminders(
        @PathVariable Long vehicleId
    ) {
        List<MaintenanceReminderDto> reminders = serviceRecordService.getMaintenanceReminders(vehicleId);
        return ResponseEntity.ok(ApiResponse.<List<MaintenanceReminderDto>>builder()
            .success(true)
            .message("Maintenance reminders retrieved successfully")
            .data(reminders)
            .build());
    }
    
    @PutMapping("/servicerecords/{id}")
    public ResponseEntity<ApiResponse<ServiceRecordDto>> updateServiceRecord(
        @PathVariable Long id,
        @RequestBody ServiceRecordRequest request
    ) {
        ServiceRecordDto record = serviceRecordService.updateServiceRecord(id, request);
        return ResponseEntity.ok(ApiResponse.<ServiceRecordDto>builder()
            .success(true)
            .message("Service record updated successfully")
            .data(record)
            .build());
    }
    
    @DeleteMapping("/servicerecords/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteServiceRecord(@PathVariable Long id) {
        serviceRecordService.deleteServiceRecord(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
            .success(true)
            .message("Service record deleted successfully")
            .build());
    }
}