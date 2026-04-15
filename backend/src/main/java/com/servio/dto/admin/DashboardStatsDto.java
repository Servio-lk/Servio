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
    /** Revenue from card-based payments (PayHere / credit / debit). */
    private BigDecimal cardRevenue;
    /** Revenue from cash payments already collected. */
    private BigDecimal cashRevenue;
    /** Estimated value of appointments still awaiting cash collection. */
    private BigDecimal pendingCashRevenue;
    private List<AppointmentDto> upcomingAppointments;
    /** Confirmed / in-progress appointments with no completed payment — need cash collection. */
    private List<AppointmentDto> pendingCashAppointments;
}
