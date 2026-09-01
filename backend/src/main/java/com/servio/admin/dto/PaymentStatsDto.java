package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentStatsDto {
    private UUID userId;
    private Long totalPayments;
    private BigDecimal totalAmount;
    private Long pendingPayments;
    private Long completedPayments;
}
