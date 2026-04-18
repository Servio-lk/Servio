package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "inventory_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InventoryItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String category; // e.g. Lubricants, Filters, Parts

    @Column(nullable = false)
    private String unit; // e.g. Litre, Piece, Pack

    @Column(name = "current_stock", nullable = false)
    private BigDecimal currentStock;

    @Column(name = "minimum_stock", nullable = false)
    private BigDecimal minimumStock;

    @Column(name = "cost_per_unit")
    private BigDecimal costPerUnit;

    @Column(name = "selling_price_per_unit")
    private BigDecimal sellingPricePerUnit;

    @Column(name = "service_type")
    private String serviceType; // Optional link to an appointment serviceType

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "inventoryItem", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<StockTransaction> transactions;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (currentStock == null) currentStock = BigDecimal.ZERO;
        if (minimumStock == null) minimumStock = BigDecimal.ZERO;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
