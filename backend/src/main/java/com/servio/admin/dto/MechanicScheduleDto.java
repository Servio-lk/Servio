package com.servio.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MechanicScheduleDto {
    private Long id;
    private String dayOfWeek;
    private LocalTime shiftStart;
    private LocalTime shiftEnd;
}
