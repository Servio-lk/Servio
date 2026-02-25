package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "repair_images")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairImage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "repair_job_id", nullable = false)
    private RepairJob repairJob;

    @Column(name = "image_url", nullable = false)
    private String imageUrl;

    @Column(name = "image_type", nullable = false)
    @Builder.Default
    private String imageType = "DAMAGE"; // DAMAGE, DURING_REPAIR, COMPLETED, INVOICE, OTHER

    @Column
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by_user_id")
    private User uploadedByUser;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (imageType == null) {
            imageType = "DAMAGE";
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
