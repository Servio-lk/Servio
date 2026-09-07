package com.servio.admin.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "mechanic_documents")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MechanicDocument {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mechanic_id", nullable = false)
    private Mechanic mechanic;

    @Column(name = "document_type", nullable = false)
    private String documentType;

    @Column(name = "original_filename")
    private String originalFilename;

    @Column(name = "url", nullable = false, length = 1000)
    private String url;

    @Column(name = "public_id", nullable = false)
    private String publicId;

    @Column(name = "resource_type")
    private String resourceType;

    @Column(name = "content_type")
    private String contentType;

    @Column(name = "file_size_bytes")
    private Long bytes;

    @Column(name = "uploaded_at", nullable = false, updatable = false)
    private LocalDateTime uploadedAt;

    @PrePersist
    protected void onCreate() {
        uploadedAt = LocalDateTime.now();
    }
}
