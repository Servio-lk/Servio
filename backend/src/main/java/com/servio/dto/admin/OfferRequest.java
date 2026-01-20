package com.servio.dto.admin;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OfferRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 200, message = "Title must not exceed 200 characters")
    private String title;

    @Size(max = 200, message = "Subtitle must not exceed 200 characters")
    private String subtitle;

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    @NotBlank(message = "Discount type is required")
    @Pattern(regexp = "PERCENTAGE|FIXED_AMOUNT", message = "Discount type must be PERCENTAGE or FIXED_AMOUNT")
    private String discountType;

    @NotNull(message = "Discount value is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Discount value must be positive")
    private BigDecimal discountValue;

    @Size(max = 500, message = "Image URL must not exceed 500 characters")
    private String imageUrl;

    private LocalDateTime validFrom;

    private LocalDateTime validUntil;

    private Boolean isActive = true;
}
