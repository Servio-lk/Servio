package com.servio.booking.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppointmentRequest {
    private UUID userId; // Optional - if null, uses authenticated user
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
