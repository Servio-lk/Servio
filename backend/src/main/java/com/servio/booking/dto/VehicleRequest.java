package com.servio.booking.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VehicleRequest {
    private UUID userId;
    private String make;
    private String model;
    private Integer year;
    private String licensePlate;
    private String vin;
}
