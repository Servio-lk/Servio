package com.servio.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OfferResponse {
    private Long id;
    private String title;
    private String subtitle;
    private String description;
    private String discountType;
    private BigDecimal discountValue;
    private String imageUrl;
    private LocalDateTime validUntil;
}