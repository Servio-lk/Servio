package com.servio.agent.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "agent_conversations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgentConversation {

    @Id
    @Column(name = "id", length = 128, nullable = false)
    private String id;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "history_json", columnDefinition = "TEXT")
    private String historyJson;

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
