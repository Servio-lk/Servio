package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "repair_estimates")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairEstimate {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "repair_job_id", nullable = false)
    private RepairJob repairJob;

    @Column(name = "estimate_number", unique = true, nullable = false)
    private String estimateNumber;

    @Column(name = "estimated_parts_cost")
    private BigDecimal estimatedPartsCost;

    @Column(name = "estimated_labor_cost")
    private BigDecimal estimatedLaborCost;

    @Column(name = "estimated_total_cost", nullable = false)
    private BigDecimal estimatedTotalCost;

    @Column(name = "estimated_duration_days")
    private Integer estimatedDurationDays;

    @Column(name = "estimate_date", nullable = false)
    private LocalDateTime estimateDate;

    @Column(name = "validity_days")
    @Builder.Default
    private Integer validityDays = 7;

    @Column
    @Builder.Default
    private String status = "PENDING"; // PENDING, APPROVED, REJECTED, EXPIRED

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_user_id")
    private User createdByUser;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by_user_id")
    private User approvedByUser;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = "PENDING";
        }
        if (validityDays == null) {
            validityDays = 7;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
