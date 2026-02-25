package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "service_bays")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceBay {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "bay_number", unique = true, nullable = false)
    private String bayNumber; // e.g., "Bay 1", "Bay 2", etc.

    @Column(nullable = false)
    private String description; // e.g., "General Service Bay"

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    @Builder.Default
    private ServiceBayType type = ServiceBayType.GENERAL; // GENERAL, PAINT_BOOTH, WASH_STATION

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private ServiceBayStatus status = ServiceBayStatus.AVAILABLE; // AVAILABLE, IN_USE, MAINTENANCE

    @Column(name = "capacity")
    private Integer capacity; // Max number of vehicles at once

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

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
