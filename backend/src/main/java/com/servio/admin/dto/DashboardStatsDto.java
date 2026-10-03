package com.servio.admin.dto;

import com.servio.booking.dto.AppointmentDto;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class DashboardStatsDto {
    private long totalCustomers;
    private long totalAppointments;
    private long pendingAppointments;
    private long bookingsToday;
    private long totalServices;
    private long activeServices;
    /** Estimated cost of bookings that have not been paid yet. */
    private BigDecimal unpaidBookings;
    private BigDecimal totalRevenue;
    /** Revenue from card-based payments (PayHere / credit / debit). */
    private BigDecimal cardRevenue;
    /** Revenue from cash payments already collected. */
    private BigDecimal cashRevenue;
    /** Estimated value of appointments still awaiting cash collection. */
    private BigDecimal pendingCashRevenue;
    private List<AppointmentDto> upcomingAppointments;
    private List<AppointmentDto> recentAppointments;
    /** Confirmed / in-progress appointments with no completed payment — need cash collection. */
    private List<AppointmentDto> pendingCashAppointments;
}
