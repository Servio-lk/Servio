package com.servio.admin.dto;

import com.servio.payment.entity.Payment;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaymentCollectionRequest {
    @NotNull(message = "Amount is required")
    @jakarta.validation.constraints.DecimalMin("0.01")
    private BigDecimal amount;

    @NotNull(message = "Payment method is required")
    @jakarta.validation.constraints.Pattern(regexp="CASH|CARD|BANK_TRANSFER")
    private String paymentMethod; // e.g., "CASH"

    @jakarta.validation.constraints.NotBlank
    @jakarta.validation.constraints.Size(max=100)
    private String requestKey;
}
