package com.servio.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockUpdateRequest {
    @NotBlank(message = "Type is required (RECEIVE, CONSUME, ADJUST)")
    private String type;

    @NotNull(message = "Quantity is required")
    private BigDecimal quantity;

    private String notes;
}
