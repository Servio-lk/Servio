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
public class AppointmentDto {
    private Long id;
    private Long userId;
    private String userName;
    private String userEmail;
    private Long vehicleId;
    private String vehicleMake;
    private String vehicleModel;
    private String serviceType;
    private LocalDateTime appointmentDate;
    private String status;
    private String location;
    private String notes;
    private BigDecimal estimatedCost;
    private BigDecimal actualCost;
    /** Sum of all completed payments for this appointment (0 if unpaid). */
    private BigDecimal paidAmount;
    /** Payment method of the most recent completed payment (CASH, CREDIT_CARD, etc.), null if unpaid. */
    private String paymentMethod;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
