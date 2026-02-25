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
    private Long userId; // Optional - if null, uses default user
    private Long vehicleId;
    private String serviceType;
    private LocalDateTime appointmentDate;
    private String location;
    private String notes;
    private BigDecimal estimatedCost;
    private String customerName;
    private String customerEmail;
    private String customerPhone;
}
