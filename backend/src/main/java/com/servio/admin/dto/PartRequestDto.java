package com.servio.admin.dto;

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
public class PartRequestDto {
    private Long id;
    private Long mechanicId;
    private String mechanicName;
    private Long appointmentId;
    private String vehicleDisplay;
    private String partName;
    private String partNumber;
    private BigDecimal quantity;
    private String unit;
    private String urgency;
    private String notes;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
