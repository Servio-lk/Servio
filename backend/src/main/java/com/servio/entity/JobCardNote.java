package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "job_card_notes")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobCardNote {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "job_card_id", nullable = false)
    private JobCard jobCard;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id")
    private User createdBy;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String noteText;

    @Column(name = "note_type")
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private NoteType noteType = NoteType.GENERAL; // GENERAL, DIAGNOSIS, ISSUE_FOUND, CUSTOMER_NOTE

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
