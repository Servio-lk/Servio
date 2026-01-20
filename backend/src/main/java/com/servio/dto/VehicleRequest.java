package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VehicleRequest {
    private Long userId;
    private String make;
    private String model;
    private Integer year;
    private String licensePlate;
    private String vin;
}
