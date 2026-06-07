package com.servio.repository;

import com.servio.entity.ConversationMemberRole;
import com.servio.entity.RepairConversationMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RepairConversationMemberRepository extends JpaRepository<RepairConversationMember, Long> {
    List<RepairConversationMember> findByConversationId(Long conversationId);

    Optional<RepairConversationMember> findByConversationIdAndRoleAndMemberRef(
            Long conversationId,
            ConversationMemberRole role,
            String memberRef
    );

    void deleteByConversationIdAndRoleAndMechanicId(Long conversationId, ConversationMemberRole role, Long mechanicId);

    boolean existsByConversationIdAndMemberUserIdAndCanWriteTrue(Long conversationId, String memberUserId);
}
