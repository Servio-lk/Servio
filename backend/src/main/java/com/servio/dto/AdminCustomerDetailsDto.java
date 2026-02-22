package com.servio.dto;

import com.servio.entity.Profile;
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
