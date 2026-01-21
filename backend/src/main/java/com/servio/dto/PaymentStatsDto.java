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
public class PaymentStatsDto {
    private Long userId;
    private Long totalPayments;
    private BigDecimal totalAmount;
    private Long pendingPayments;
    private Long completedPayments;
}
