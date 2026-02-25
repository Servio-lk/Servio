package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobCardDto {
    private Long id;
    private Long appointmentId;
    private Long mechanicId;
    private String mechanicName;
    private Long serviceBayId;
    private String bayNumber;
    private Long walkInCustomerId;
    private String customerName;
    private String jobNumber;
    private String serviceType;
    private String description;
    private String status;
    private String priority;
    private Double estimatedHours;
    private Double actualHours;
    private BigDecimal estimatedCost;
    private BigDecimal actualCost;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
