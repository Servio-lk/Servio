package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceRecordDto {
    private Long id;
    private Long vehicleId;
    private String vehicleMake;
    private String vehicleModel;
    private String serviceType;
    private String description;
    private LocalDate serviceDate;
    private Integer mileage;
    private BigDecimal cost;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
