package com.servio.dto.admin;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class ServiceOptionRequest {
    private Long id;

    @Size(max = 200, message = "Option name must not exceed 200 characters")
    private String name;

    private String description;

    @DecimalMin(value = "0.0", message = "Option price must be zero or positive")
    private BigDecimal priceAdjustment = BigDecimal.ZERO;

    private Boolean isDefault = false;

    private Integer displayOrder = 0;
}
