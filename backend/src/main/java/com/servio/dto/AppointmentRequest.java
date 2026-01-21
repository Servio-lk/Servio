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
public class AppointmentRequest {
    private Long userId;
    private Long vehicleId;
    private String serviceType;
    private LocalDateTime appointmentDate;
    private String location;
    private String notes;
    private BigDecimal estimatedCost;
}
