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
public class PaymentRequest {
    private Long userId;
    private Long appointmentId;
    private BigDecimal amount;
    private String paymentMethod; // CREDIT_CARD, DEBIT_CARD, CASH, UPI, WALLET
}
