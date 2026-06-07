package com.servio.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "repair_conversation_members",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_repair_conversation_member_role_ref",
                        columnNames = {"conversation_id", "role", "member_ref"}
                )
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepairConversationMember {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", nullable = false)
    private RepairConversation conversation;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ConversationMemberRole role;

    @Column(name = "member_ref", nullable = false)
    private String memberRef;

    @Column(name = "member_user_id")
    private String memberUserId;

    @Column(name = "mechanic_id")
    private Long mechanicId;

    @Column(name = "can_write", nullable = false)
    @Builder.Default
    private Boolean canWrite = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
