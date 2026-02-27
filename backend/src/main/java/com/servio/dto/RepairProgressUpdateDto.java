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
public class RepairProgressUpdateDto {
    private Long id;
    private Long repairJobId;
    private String status;
    private Integer progressPercentage;
    private String description;
    private String technicianNotes;
    private LocalDateTime estimatedCompletionTime;
    private LocalDateTime actualCompletionTime;
    private LocalDateTime createdAt;
}
