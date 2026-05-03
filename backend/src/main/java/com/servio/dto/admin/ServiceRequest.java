package com.servio.dto.admin;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@NoArgsConstructor
@AllArgsConstructor
public class ServiceRequest {

    private Long categoryId;

    @NotBlank(message = "Service name is required")
    @Size(max = 200, message = "Service name must not exceed 200 characters")
    private String name;

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    @DecimalMin(value = "0.0", message = "Base price must be zero or positive")
    private BigDecimal basePrice;

    @Size(max = 50, message = "Price range must not exceed 50 characters")
    private String priceRange;

    @Min(value = 1, message = "Duration must be at least 1 minute")
    private Integer durationMinutes;

    @Size(max = 500, message = "Image URL must not exceed 500 characters")
    private String imageUrl;

    @Size(max = 500, message = "Icon URL must not exceed 500 characters")
    private String iconUrl;

    private String status = "PUBLISHED";

    private Boolean warrantyIncluded = true;

    private Boolean isFeatured = false;

    private Boolean isActive = true;

    private List<String> includedItems;

    private List<ServiceOptionRequest> options;

    private List<ServicePhotoDto> photos;

    public Long getCategoryId() { return categoryId; }
    public void setCategoryId(Long categoryId) { this.categoryId = categoryId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getBasePrice() { return basePrice; }
    public void setBasePrice(BigDecimal basePrice) { this.basePrice = basePrice; }

    public String getPriceRange() { return priceRange; }
    public void setPriceRange(String priceRange) { this.priceRange = priceRange; }

    public Integer getDurationMinutes() { return durationMinutes; }
    public void setDurationMinutes(Integer durationMinutes) { this.durationMinutes = durationMinutes; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getIconUrl() { return iconUrl; }
    public void setIconUrl(String iconUrl) { this.iconUrl = iconUrl; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Boolean getWarrantyIncluded() { return warrantyIncluded; }
    public void setWarrantyIncluded(Boolean warrantyIncluded) { this.warrantyIncluded = warrantyIncluded; }

    public Boolean getIsFeatured() { return isFeatured; }
    public void setIsFeatured(Boolean isFeatured) { this.isFeatured = isFeatured; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public List<String> getIncludedItems() { return includedItems; }
    public void setIncludedItems(List<String> includedItems) { this.includedItems = includedItems; }

    public List<ServiceOptionRequest> getOptions() { return options; }
    public void setOptions(List<ServiceOptionRequest> options) { this.options = options; }

    public List<ServicePhotoDto> getPhotos() { return photos; }
    public void setPhotos(List<ServicePhotoDto> photos) { this.photos = photos; }
}
