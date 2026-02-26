package com.servio.controller;

import com.servio.dto.*;
import com.servio.entity.RepairJob;
import com.servio.service.RepairJobService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/repairs")
@RequiredArgsConstructor
public class RepairJobController {
    
    private final RepairJobService repairJobService;
    
    @PostMapping
    public ResponseEntity<ApiResponse<RepairJobDto>> createRepairJob(@RequestBody RepairJobRequest request) {
        try {
            RepairJob repairJob = repairJobService.createRepairJob(
                    request.getAppointmentId(),
                    request.getTitle(),
                    request.getDescription(),
                    request.getEstimatedDurationHours(),
                    request.getEstimatedCost()
            );
            
            RepairJobDto dto = convertToDto(repairJob);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.<RepairJobDto>builder()
                            .success(true)
                            .message("Repair job created successfully")
                            .data(dto)
                            .build());
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.<RepairJobDto>builder()
                            .success(false)
                            .message(e.getMessage())
                            .build());
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RepairJobDto>> getRepairJob(@PathVariable Long id) {
        try {
            RepairJob repairJob = repairJobService.getRepairJobById(id);
            RepairJobDto dto = convertToDto(repairJob);
            return ResponseEntity.ok(ApiResponse.<RepairJobDto>builder()
                    .success(true)
                    .message("Repair job retrieved successfully")
                    .data(dto)
                    .build());
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<RepairJobDto>>> getUserRepairJobs(@PathVariable Long userId) {
        List<RepairJob> repairJobs = repairJobService.getUserRepairJobs(userId);
        List<RepairJobDto> dtos = repairJobs.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(ApiResponse.<List<RepairJobDto>>builder()
                .success(true)
                .message("User repair jobs retrieved successfully")
                .data(dtos)
                .build());
    }
    
    @GetMapping("/vehicle/{vehicleId}")
    public ResponseEntity<ApiResponse<List<RepairJobDto>>> getVehicleRepairJobs(@PathVariable Long vehicleId) {
        List<RepairJob> repairJobs = repairJobService.getVehicleRepairJobs(vehicleId);
        List<RepairJobDto> dtos = repairJobs.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(ApiResponse.<List<RepairJobDto>>builder()
                .success(true)
                .message("Vehicle repair jobs retrieved successfully")
                .data(dtos)
                .build());
    }
    
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<RepairJobDto>>> getRepairJobsByStatus(@PathVariable String status) {
        List<RepairJob> repairJobs = repairJobService.getRepairJobsByStatus(status);
        List<RepairJobDto> dtos = repairJobs.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(ApiResponse.<List<RepairJobDto>>builder()
                .success(true)
                .message("Repair jobs retrieved successfully")
                .data(dtos)
                .build());
    }
    
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<RepairJobDto>> updateRepairJobStatus(
            @PathVariable Long id,
            @RequestParam String status
    ) {
        try {
            RepairJob repairJob = repairJobService.updateRepairJobStatus(id, status);
            RepairJobDto dto = convertToDto(repairJob);
            return ResponseEntity.ok(ApiResponse.<RepairJobDto>builder()
                    .success(true)
                    .message("Repair job status updated successfully")
                    .data(dto)
                    .build());
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRepairJob(@PathVariable Long id) {
        try {
            repairJobService.deleteRepairJob(id);
            return ResponseEntity.ok(ApiResponse.<Void>builder()
                    .success(true)
                    .message("Repair job deleted successfully")
                    .build());
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    private RepairJobDto convertToDto(RepairJob repairJob) {
        return RepairJobDto.builder()
                .id(repairJob.getId())
                .appointmentId(repairJob.getAppointment().getId())
                .vehicleId(repairJob.getVehicle().getId())
                .userId(repairJob.getUser().getId())
                .title(repairJob.getTitle())
                .description(repairJob.getDescription())
                .status(repairJob.getStatus())
                .priority(repairJob.getPriority())
                .estimatedDurationHours(repairJob.getEstimatedDurationHours())
                .actualDurationHours(repairJob.getActualDurationHours())
                .estimatedCost(repairJob.getEstimatedCost())
                .actualCost(repairJob.getActualCost())
                .partsCost(repairJob.getPartsCost())
                .laborCost(repairJob.getLaborCost())
                .assignedTechnicianId(repairJob.getAssignedTechnicianId())
                .startDate(repairJob.getStartDate())
                .completionDate(repairJob.getCompletionDate())
                .notes(repairJob.getNotes())
                .createdAt(repairJob.getCreatedAt())
                .updatedAt(repairJob.getUpdatedAt())
                .build();
    }
}
