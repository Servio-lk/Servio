package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "repair_history")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id", nullable = false)
    private Vehicle vehicle;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "repair_job_id")
    private RepairJob repairJob;

    @Column(name = "repair_type", nullable = false)
    private String repairType;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column
    private BigDecimal cost;

    @Column(name = "repair_date", nullable = false)
    private LocalDate repairDate;

    @Column(name = "mileage_at_repair")
    private Integer mileageAtRepair;

    @Column(name = "technician_name")
    private String technicianName;

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
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
