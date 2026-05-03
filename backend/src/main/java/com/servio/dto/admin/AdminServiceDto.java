package com.servio.dto.admin;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class AdminServiceDto {
    private Long id;
    private Long categoryId;
    private String categoryName;
    private String name;
    private String description;
    private BigDecimal basePrice;
    private String priceRange;
    private Integer durationMinutes;
    private String imageUrl;
    private String iconUrl;
    private String status;
    private Boolean warrantyIncluded;
    private Boolean isFeatured;
    private Boolean isActive;
    private LocalDateTime publishedAt;
    private LocalDateTime customerNotifiedAt;
    private List<String> includedItems;
    private List<ServiceOptionRequest> options;
    private List<ServicePhotoDto> photos;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
