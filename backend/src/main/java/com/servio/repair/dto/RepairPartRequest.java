package com.servio.repair.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairPartRequest {
    private String partName;
    private String partNumber;
    private String supplier;
    private BigDecimal unitCost;
    private Integer quantity;
    private BigDecimal totalCost;
    private String status;
    private String notes;
}
