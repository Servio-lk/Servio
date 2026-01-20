package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VehicleDto {
    private Long id;
    private Long userId;
    private String userName;
    private String make;
    private String model;
    private Integer year;
    private String licensePlate;
    private String vin;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
