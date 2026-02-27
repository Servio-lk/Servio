package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "repair_jobs")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairJob {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id", nullable = false)
    private Vehicle vehicle;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private String status; // INITIAL_INSPECTION, QUOTE_PROVIDED, QUOTE_APPROVED, IN_PROGRESS, AWAITING_PARTS, COMPLETED, CANCELLED

    @Column(nullable = false)
    @Builder.Default
    private String priority = "NORMAL"; // LOW, NORMAL, HIGH, URGENT

    @Column(name = "estimated_duration_hours")
    private Integer estimatedDurationHours;

    @Column(name = "actual_duration_hours")
    private Integer actualDurationHours;

    @Column(name = "estimated_cost")
    private BigDecimal estimatedCost;

    @Column(name = "actual_cost")
    private BigDecimal actualCost;

    @Column(name = "parts_cost")
    private BigDecimal partsCost;

    @Column(name = "labor_cost")
    private BigDecimal laborCost;

    @Column(name = "assigned_technician_id")
    private Long assignedTechnicianId;

    @Column(name = "start_date")
    private LocalDateTime startDate;

    @Column(name = "completion_date")
    private LocalDateTime completionDate;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @OneToMany(mappedBy = "repairJob", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RepairProgressUpdate> progressUpdates;

    @OneToOne(mappedBy = "repairJob", cascade = CascadeType.ALL, orphanRemoval = true)
    private RepairProgress progress;

    @OneToMany(mappedBy = "repairJob", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RepairActivity> activities;

    @OneToMany(mappedBy = "repairJob", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RepairPart> parts;

    @OneToMany(mappedBy = "repairJob", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RepairImage> images;

    @OneToMany(mappedBy = "repairJob", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RepairEstimate> estimates;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = "INITIAL_INSPECTION";
        }
        if (priority == null) {
            priority = "NORMAL";
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
