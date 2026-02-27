package com.servio.dto.admin;

import com.servio.dto.AppointmentDto;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class DashboardStatsDto {
    private long totalCustomers;
    private long totalAppointments;
    private BigDecimal totalRevenue;
    private List<AppointmentDto> upcomingAppointments;
}
