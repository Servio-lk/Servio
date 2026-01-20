package com.servio.service;

import com.servio.dto.DashboardStatsResponse;
import com.servio.dto.RecentActivityDto;
import com.servio.dto.RevenueChartData;
import com.servio.entity.Appointment;
import com.servio.entity.Payment;
import com.servio.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {
    
    private final UserRepository userRepository;
    private final AppointmentRepository appointmentRepository;
    private final PaymentRepository paymentRepository;
    private final ReviewRepository reviewRepository;
    private final VehicleRepository vehicleRepository;
    
    public DashboardStatsResponse getDashboardStats() {
        Long totalUsers = userRepository.count();
        Long totalAppointments = appointmentRepository.count();
        Long pendingAppointments = appointmentRepository.countByStatus("PENDING");
        Long completedAppointments = appointmentRepository.countByStatus("COMPLETED");
        
        BigDecimal totalRevenue = paymentRepository.getTotalRevenue();
        if (totalRevenue == null) totalRevenue = BigDecimal.ZERO;
        
        // Get current month revenue
        LocalDateTime monthStart = YearMonth.now().atDay(1).atStartOfDay();
        LocalDateTime monthEnd = YearMonth.now().atEndOfMonth().atTime(23, 59, 59);
        BigDecimal monthlyRevenue = paymentRepository.getRevenueForPeriod(monthStart, monthEnd);
        if (monthlyRevenue == null) monthlyRevenue = BigDecimal.ZERO;
        
        Double averageRating = reviewRepository.getAverageRating();
        if (averageRating == null) averageRating = 0.0;
        
        Long totalReviews = reviewRepository.count();
        Long activeVehicles = vehicleRepository.count();
        
        return DashboardStatsResponse.builder()
            .totalUsers(totalUsers)
            .totalAppointments(totalAppointments)
            .pendingAppointments(pendingAppointments)
            .completedAppointments(completedAppointments)
            .totalRevenue(totalRevenue)
            .monthlyRevenue(monthlyRevenue)
            .averageRating(Math.round(averageRating * 10.0) / 10.0)
            .totalReviews(totalReviews)
            .activeVehicles(activeVehicles)
            .build();
    }
    
    public RevenueChartData getRevenueChartData(int months) {
        List<String> labels = new ArrayList<>();
        List<BigDecimal> data = new ArrayList<>();
        
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMM yyyy");
        
        for (int i = months - 1; i >= 0; i--) {
            YearMonth yearMonth = YearMonth.now().minusMonths(i);
            LocalDateTime startDate = yearMonth.atDay(1).atStartOfDay();
            LocalDateTime endDate = yearMonth.atEndOfMonth().atTime(23, 59, 59);
            
            labels.add(yearMonth.format(formatter));
            
            BigDecimal revenue = paymentRepository.getRevenueForPeriod(startDate, endDate);
            data.add(revenue != null ? revenue : BigDecimal.ZERO);
        }
        
        return RevenueChartData.builder()
            .labels(labels)
            .data(data)
            .build();
    }
    
    public List<RecentActivityDto> getRecentActivities(int limit) {
        List<RecentActivityDto> activities = new ArrayList<>();
        
        // Get recent appointments
        List<Appointment> recentAppointments = appointmentRepository.findRecentAppointments();
        activities.addAll(recentAppointments.stream()
            .limit(limit / 2)
            .map(a -> RecentActivityDto.builder()
                .activityType("APPOINTMENT")
                .description("New appointment for " + a.getServiceType())
                .userName(a.getUser().getFullName())
                .timestamp(a.getCreatedAt())
                .build())
            .collect(Collectors.toList()));
        
        // Get recent payments
        List<Payment> recentPayments = paymentRepository.findRecentPayments();
        activities.addAll(recentPayments.stream()
            .limit(limit / 2)
            .map(p -> RecentActivityDto.builder()
                .activityType("PAYMENT")
                .description("Payment of $" + p.getAmount() + " received")
                .userName(p.getUser().getFullName())
                .timestamp(p.getCreatedAt())
                .build())
            .collect(Collectors.toList()));
        
        // Sort by timestamp descending and limit
        return activities.stream()
            .sorted((a, b) -> b.getTimestamp().compareTo(a.getTimestamp()))
            .limit(limit)
            .collect(Collectors.toList());
    }
}
