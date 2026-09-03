package com.servio.admin.dto;

import com.servio.booking.dto.CustomerVehicleHistoryDto;

import com.servio.auth.entity.Profile;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminCustomerDetailsDto {
    private Profile profile;
    private AdminCustomerUserDto user;
    private List<CustomerVehicleHistoryDto> vehicles;
}
