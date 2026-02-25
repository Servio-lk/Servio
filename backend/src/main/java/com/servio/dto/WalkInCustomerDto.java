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
public class WalkInCustomerDto {
    private Long id;
    private String fullName;
    private String phone;
    private String email;
    private String vehicleMake;
    private String vehicleModel;
    private Integer vehicleYear;
    private String licensePlate;
    private String notes;
    private Boolean isRegistered;
    private Long registeredUserId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
