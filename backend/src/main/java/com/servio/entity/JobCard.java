package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.math.BigDecimal;

@Entity
@Table(name = "job_cards")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobCard {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mechanic_id")
    private Mechanic assignedMechanic;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_bay_id")
    private ServiceBay assignedBay;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "walk_in_customer_id")
    private WalkInCustomer walkInCustomer;

    @Column(nullable = false)
    private String jobNumber; // Unique job card number

    @Column(nullable = false)
    private String serviceType;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private JobCardStatus status = JobCardStatus.NEW; // NEW, IN_PROGRESS, COMPLETED, CANCELLED

    @Column(name = "priority")
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private JobPriority priority = JobPriority.NORMAL;

    @Column(name = "estimated_hours")
    private Double estimatedHours;

    @Column(name = "actual_hours")
    private Double actualHours;

    @Column(name = "estimated_cost")
    private BigDecimal estimatedCost;

    @Column(name = "actual_cost")
    private BigDecimal actualCost;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (jobNumber == null) {
            jobNumber = "JC-" + System.currentTimeMillis();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
