package com.servio.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceOptionResponse {
    private Long id;
    private String name;
    private String description;
    private BigDecimal priceAdjustment;
    private Boolean isDefault;
}