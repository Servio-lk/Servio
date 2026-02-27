package com.servio.controller;

import com.servio.dto.*;
import com.servio.entity.RepairProgressUpdate;
import com.servio.service.RepairProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/repairs/progress")
@RequiredArgsConstructor
public class RepairProgressController {
    
    private final RepairProgressService repairProgressService;
    
    @PostMapping
    public ResponseEntity<ApiResponse<RepairProgressUpdateDto>> createProgressUpdate(
            @RequestParam Long repairJobId,
            @RequestParam String status,
            @RequestParam(required = false) Integer progressPercentage,
            @RequestParam(required = false) String description
    ) {
        RepairProgressUpdate update = repairProgressService.createProgressUpdate(
                repairJobId, status, progressPercentage, description
        );
        
        RepairProgressUpdateDto dto = convertToDto(update);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<RepairProgressUpdateDto>builder()
                        .success(true)
                        .message("Progress update created successfully")
                        .data(dto)
                        .build());
    }
    
    @GetMapping("/job/{repairJobId}")
    public ResponseEntity<ApiResponse<List<RepairProgressUpdateDto>>> getProgressUpdates(
            @PathVariable Long repairJobId
    ) {
        List<RepairProgressUpdate> updates = repairProgressService.getProgressUpdates(repairJobId);
        List<RepairProgressUpdateDto> dtos = updates.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(ApiResponse.<List<RepairProgressUpdateDto>>builder()
                .success(true)
                .message("Progress updates retrieved successfully")
                .data(dtos)
                .build());
    }
    
    @GetMapping("/job/{repairJobId}/latest")
    public ResponseEntity<ApiResponse<RepairProgressUpdateDto>> getLatestProgressUpdate(
            @PathVariable Long repairJobId
    ) {
        RepairProgressUpdate update = repairProgressService.getLatestProgressUpdate(repairJobId);
        if (update == null) {
            return ResponseEntity.notFound().build();
        }
        
        RepairProgressUpdateDto dto = convertToDto(update);
        return ResponseEntity.ok(ApiResponse.<RepairProgressUpdateDto>builder()
                .success(true)
                .message("Latest progress update retrieved successfully")
                .data(dto)
                .build());
    }
    
    private RepairProgressUpdateDto convertToDto(RepairProgressUpdate update) {
        return RepairProgressUpdateDto.builder()
                .id(update.getId())
                .repairJobId(update.getRepairJob().getId())
                .status(update.getStatus())
                .progressPercentage(update.getProgressPercentage())
                .description(update.getDescription())
                .technicianNotes(update.getTechnicianNotes())
                .estimatedCompletionTime(update.getEstimatedCompletionTime())
                .actualCompletionTime(update.getActualCompletionTime())
                .createdAt(update.getCreatedAt())
                .build();
    }
}
