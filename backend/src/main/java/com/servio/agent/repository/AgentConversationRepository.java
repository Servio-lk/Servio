package com.servio.agent.repository;

import com.servio.agent.entity.AgentConversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AgentConversationRepository extends JpaRepository<AgentConversation, String> {
    List<AgentConversation> findByUserIdOrderByUpdatedAtDesc(UUID userId);
}
