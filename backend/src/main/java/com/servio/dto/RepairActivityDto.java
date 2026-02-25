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
public class RepairActivityDto {
    private Long id;
    private Long repairJobId;
    private String activityType;
    private String description;
    private String performedByUserName;
    private LocalDateTime createdAt;
}
