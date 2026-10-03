package com.servio.repair.repository;

import com.servio.repair.entity.RepairMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RepairMessageRepository extends JpaRepository<RepairMessage, Long> {

    List<RepairMessage> findByConversationIdOrderByCreatedAtAsc(Long conversationId);

    /** Latest message in a conversation (for inbox preview). */
    Optional<RepairMessage> findTopByConversationIdOrderByCreatedAtDesc(Long conversationId);

    /** Count unread messages NOT sent by the given role. */
    @Query("""
        SELECT COUNT(m) FROM RepairMessage m
        WHERE m.conversation.id = :conversationId
          AND m.senderRole != :readerRole
          AND m.readAt IS NULL
        """)
    long countUnreadForRole(@Param("conversationId") Long conversationId,
                            @Param("readerRole") String readerRole);

    @Modifying
    @Query("""
        UPDATE RepairMessage m
        SET m.readAt = :now
        WHERE m.conversation.id = :conversationId
          AND m.senderRole != :readerRole
          AND m.readAt IS NULL
        """)
    int markReadForRole(@Param("conversationId") Long conversationId,
                        @Param("readerRole") String readerRole,
                        @Param("now") LocalDateTime now);

    @Query("""
        SELECT COUNT(m) FROM RepairMessage m
        WHERE m.senderRole != 'ADMIN'
          AND m.readAt IS NULL
        """)
    long countGlobalUnreadForAdmin();

    @Query("""
        SELECT COUNT(m) FROM RepairMessage m
        WHERE m.conversation.id IN (
            SELECT mem.conversation.id FROM RepairConversationMember mem
            WHERE mem.memberUserId = :userId AND mem.role = 'CLIENT'
        )
        AND m.senderRole != 'CLIENT'
        AND m.readAt IS NULL
        """)
    long countGlobalUnreadForClient(@Param("userId") String userId);
}
