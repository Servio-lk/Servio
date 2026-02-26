package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairJobDto {
    private Long id;
    private Long appointmentId;
    private Long vehicleId;
    private Long userId;
    private String title;
    private String description;
    private String status;
    private String priority;
    private Integer estimatedDurationHours;
    private Integer actualDurationHours;
    private BigDecimal estimatedCost;
    private BigDecimal actualCost;
    private BigDecimal partsCost;
    private BigDecimal laborCost;
    private Long assignedTechnicianId;
    private LocalDateTime startDate;
    private LocalDateTime completionDate;
    private String notes;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
