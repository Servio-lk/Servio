package com.servio.repair.controller;

import com.servio.common.dto.ApiResponse;
import com.servio.repair.dto.RepairJobRequest;
import com.servio.repair.dto.RepairJobDto;
import com.servio.auth.entity.User;
import com.servio.booking.entity.Vehicle;

import com.servio.repair.entity.RepairJob;
import com.servio.repair.service.RepairJobService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/repairs")
@RequiredArgsConstructor
public class RepairJobController {
    
    private final RepairJobService repairJobService;
    
    @PostMapping
    public ResponseEntity<ApiResponse<RepairJobDto>> createRepairJob(@RequestBody RepairJobRequest request) {
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
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RepairJobDto>> getRepairJob(@PathVariable Long id) {
        RepairJob repairJob = repairJobService.getRepairJobById(id);
        RepairJobDto dto = convertToDto(repairJob);
        return ResponseEntity.ok(ApiResponse.<RepairJobDto>builder()
                .success(true)
                .message("Repair job retrieved successfully")
                .data(dto)
                .build());
    }
    
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<RepairJobDto>>> getUserRepairJobs(@PathVariable UUID userId) {
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
        RepairJob repairJob = repairJobService.updateRepairJobStatus(id, status);
        RepairJobDto dto = convertToDto(repairJob);
        return ResponseEntity.ok(ApiResponse.<RepairJobDto>builder()
                .success(true)
                .message("Repair job status updated successfully")
                .data(dto)
                .build());
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRepairJob(@PathVariable Long id) {
        repairJobService.deleteRepairJob(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Repair job deleted successfully")
                .build());
    }
    
    private RepairJobDto convertToDto(RepairJob repairJob) {
        return RepairJobDto.builder()
                .id(repairJob.getId())
                .appointmentId(repairJob.getAppointment().getId())
                .vehicleId(repairJob.getVehicle() != null ? repairJob.getVehicle().getId() : null)
                .userId(repairJob.getUser() != null ? repairJob.getUser().getId() : null)
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
