package com.servio.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ServiceResponse {
    private Long id;
    private Long categoryId;
    private String categoryName;
    private String name;
    private String description;
    private BigDecimal basePrice;
    private String priceRange;
    private Integer durationMinutes;
    private String imageUrl;
    private Boolean isFeatured;
    private List<ServiceOptionResponse> options;
}