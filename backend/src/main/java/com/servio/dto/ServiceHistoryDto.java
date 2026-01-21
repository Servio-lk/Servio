package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceHistoryDto {
    private Long vehicleId;
    private String vehicleInfo;
    private Long totalServices;
    private BigDecimal totalCost;
    private LocalDate lastServiceDate;
    private Integer lastMileage;
    private List<ServiceRecordDto> serviceRecords;
}
