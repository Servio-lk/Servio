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
public class VehicleStatsDto {
    private Long vehicleId;
    private String vehicleInfo;
    private Long totalServices;
    private BigDecimal totalCost;
    private Integer lastMileage;
}
