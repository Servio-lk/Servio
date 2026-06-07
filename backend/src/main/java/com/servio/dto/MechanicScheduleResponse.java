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
public class MechanicScheduleResponse {
    private Long mechanicId;
    private List<MechanicScheduleDto> workingHours;
    private List<MechanicUnavailableBlockDto> unavailableBlocks;
}
