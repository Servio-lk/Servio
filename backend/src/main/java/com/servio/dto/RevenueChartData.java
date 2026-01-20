package com.servio.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RevenueChartData {
    private List<String> labels; // e.g., ["Jan", "Feb", "Mar"]
    private List<BigDecimal> data; // Revenue for each period
}
