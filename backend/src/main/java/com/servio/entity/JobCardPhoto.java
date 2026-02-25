package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "job_card_photos")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobCardPhoto {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "job_card_id", nullable = false)
    private JobCard jobCard;

    @Column(nullable = false)
    private String photoUrl; // Path or URL to the photo

    @Column(columnDefinition = "TEXT")
    private String description; // What the photo shows

    @Column(name = "photo_type")
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private PhotoType photoType = PhotoType.WORK_IN_PROGRESS;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by_id")
    private User uploadedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
