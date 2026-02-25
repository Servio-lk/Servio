package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobTaskDto {
    private Long id;
    private Long jobCardId;
    private String jobNumber;
    private Long mechanicId;
    private String mechanicName;
    private String taskNumber;
    private String description;
    private String instructions;
    private String status;
    private Integer sequenceOrder;
    private Double estimatedHours;
    private Double actualHours;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
