package com.servio.auth.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_notification_preferences")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserNotificationPreference {
    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "promotional_offers", nullable = false)
    @Builder.Default
    private Boolean promotionalOffers = true;

    @Column(name = "push_notifications", nullable = false)
    @Builder.Default
    private Boolean pushNotifications = true;

    @Column(name = "security_alerts", nullable = false)
    @Builder.Default
    private Boolean securityAlerts = true;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    void touch() { updatedAt = LocalDateTime.now(); }
}