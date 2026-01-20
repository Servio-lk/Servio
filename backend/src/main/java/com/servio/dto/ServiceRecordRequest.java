package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceRecordRequest {
    private Long vehicleId;
    private String serviceType;
    private String description;
    private LocalDate serviceDate;
    private Integer mileage;
    private BigDecimal cost;
}
