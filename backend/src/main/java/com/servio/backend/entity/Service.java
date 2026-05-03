package com.servio.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "services")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Service {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    @JsonIgnoreProperties("services")
    private ServiceCategory category;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "base_price", precision = 10, scale = 2)
    private BigDecimal basePrice;

    @Column(name = "price_range", length = 50)
    private String priceRange;

    @Column(name = "duration_minutes")
    private Integer durationMinutes;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "icon_url", length = 500)
    private String iconUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ServiceStatus status = ServiceStatus.PUBLISHED;

    @Column(name = "warranty_included")
    private Boolean warrantyIncluded = true;

    @Column(name = "is_featured")
    private Boolean isFeatured = false;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    @Column(name = "customer_notified_at")
    private LocalDateTime customerNotifiedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @ElementCollection
    @CollectionTable(name = "service_included_items", joinColumns = @JoinColumn(name = "service_id"))
    @Column(name = "item", columnDefinition = "TEXT")
    @OrderColumn(name = "display_order")
    private List<String> includedItems;

    @OneToMany(mappedBy = "service", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JsonIgnoreProperties("service")
    private List<ServiceOption> options;

    @OneToMany(mappedBy = "service", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JsonIgnoreProperties("service")
    private List<ServicePhoto> photos;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = Boolean.FALSE.equals(isActive) ? ServiceStatus.HIDDEN : ServiceStatus.PUBLISHED;
        }
        isActive = status == ServiceStatus.PUBLISHED;
        if (status == ServiceStatus.PUBLISHED && publishedAt == null) {
            publishedAt = createdAt;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = Boolean.FALSE.equals(isActive) ? ServiceStatus.HIDDEN : ServiceStatus.PUBLISHED;
        }
        isActive = status == ServiceStatus.PUBLISHED;
    }
}
