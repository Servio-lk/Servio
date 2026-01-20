package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardStatsResponse {
    private Long totalUsers;
    private Long totalAppointments;
    private Long pendingAppointments;
    private Long completedAppointments;
    private BigDecimal totalRevenue;
    private BigDecimal monthlyRevenue;
    private Double averageRating;
    private Long totalReviews;
    private Long activeVehicles;
}
