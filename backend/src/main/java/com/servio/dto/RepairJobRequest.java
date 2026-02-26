package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairJobRequest {
    private Long appointmentId;
    private String title;
    private String description;
    private Integer estimatedDurationHours;
    private BigDecimal estimatedCost;
    private String priority;
    private String notes;
}
