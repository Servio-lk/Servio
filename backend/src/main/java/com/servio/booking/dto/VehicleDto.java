package com.servio.booking.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VehicleDto {
    private Long id;
    private UUID userId;
    private String profileId;
    private String ownerName;
    private String make;
    private String model;
    private Integer year;
    private String licensePlate;
    private String vin;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
