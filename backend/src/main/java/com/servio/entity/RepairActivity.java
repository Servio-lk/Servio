package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "repair_activities")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairActivity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "repair_job_id", nullable = false)
    private RepairJob repairJob;

    @Column(name = "activity_type", nullable = false)
    private String activityType; // STATUS_CHANGE, NOTE, PARTS_UPDATE, ESTIMATE, ASSIGNMENT, SYSTEM

    @Column(columnDefinition = "TEXT", nullable = false)
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "performed_by_user_id")
    private User performedByUser;

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
