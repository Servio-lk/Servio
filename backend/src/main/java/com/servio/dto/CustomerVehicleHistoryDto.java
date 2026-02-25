package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerVehicleHistoryDto {
    private VehicleDto vehicle;
    private List<ServiceRecordDto> serviceRecords;
}
