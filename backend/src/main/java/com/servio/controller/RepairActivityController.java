package com.servio.controller;

import com.servio.dto.*;
import com.servio.entity.RepairActivity;
import com.servio.service.RepairActivityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/repairs/activities")
@RequiredArgsConstructor
public class RepairActivityController {
    
    private final RepairActivityService repairActivityService;
    
    @GetMapping("/job/{repairJobId}")
    public ResponseEntity<ApiResponse<List<RepairActivityDto>>> getRepairActivities(
            @PathVariable Long repairJobId
    ) {
        List<RepairActivity> activities = repairActivityService.getRepairActivities(repairJobId);
        List<RepairActivityDto> dtos = activities.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(ApiResponse.<List<RepairActivityDto>>builder()
                .success(true)
                .message("Repair activities retrieved successfully")
                .data(dtos)
                .build());
    }
    
    @GetMapping("/job/{repairJobId}/type/{activityType}")
    public ResponseEntity<ApiResponse<List<RepairActivityDto>>> getActivitiesByType(
            @PathVariable Long repairJobId,
            @PathVariable String activityType
    ) {
        List<RepairActivity> activities = repairActivityService.getActivitiesByType(repairJobId, activityType);
        List<RepairActivityDto> dtos = activities.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(ApiResponse.<List<RepairActivityDto>>builder()
                .success(true)
                .message("Activities retrieved successfully")
                .data(dtos)
                .build());
    }
    
    private RepairActivityDto convertToDto(RepairActivity activity) {
        return RepairActivityDto.builder()
                .id(activity.getId())
                .repairJobId(activity.getRepairJob().getId())
                .activityType(activity.getActivityType())
                .description(activity.getDescription())
                .performedByUserName(activity.getPerformedByUser() != null ? 
                        activity.getPerformedByUser().getFullName() : "System")
                .createdAt(activity.getCreatedAt())
                .build();
    }
}
