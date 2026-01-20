package com.servio.controller;

import com.servio.dto.*;
import com.servio.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DashboardController {
    
    private final DashboardService dashboardService;
    
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<DashboardStatsResponse>> getDashboardStats() {
        DashboardStatsResponse stats = dashboardService.getDashboardStats();
        return ResponseEntity.ok(ApiResponse.<DashboardStatsResponse>builder()
            .success(true)
            .message("Dashboard stats retrieved successfully")
            .data(stats)
            .build());
    }
    
    @GetMapping("/revenue-chart")
    public ResponseEntity<ApiResponse<RevenueChartData>> getRevenueChartData(
        @RequestParam(defaultValue = "6") int months
    ) {
        RevenueChartData chartData = dashboardService.getRevenueChartData(months);
        return ResponseEntity.ok(ApiResponse.<RevenueChartData>builder()
            .success(true)
            .message("Revenue chart data retrieved successfully")
            .data(chartData)
            .build());
    }
    
    @GetMapping("/recent-activities")
    public ResponseEntity<ApiResponse<List<RecentActivityDto>>> getRecentActivities(
        @RequestParam(defaultValue = "10") int limit
    ) {
        List<RecentActivityDto> activities = dashboardService.getRecentActivities(limit);
        return ResponseEntity.ok(ApiResponse.<List<RecentActivityDto>>builder()
            .success(true)
            .message("Recent activities retrieved successfully")
            .data(activities)
            .build());
    }
}
