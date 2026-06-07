package com.servio.repository;

import com.servio.entity.RepairMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RepairMessageRepository extends JpaRepository<RepairMessage, Long> {
    List<RepairMessage> findByConversationIdOrderByCreatedAtAsc(Long conversationId);
}
