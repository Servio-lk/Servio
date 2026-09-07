package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MechanicScheduleRequest {
    @Builder.Default
    private List<MechanicScheduleDto> workingHours = new ArrayList<>();

    @Builder.Default
    private List<MechanicUnavailableBlockDto> unavailableBlocks = new ArrayList<>();
}
