package com.servio.repair.repository;

import com.servio.repair.entity.RepairConversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RepairConversationRepository extends JpaRepository<RepairConversation, Long> {
    Optional<RepairConversation> findByRepairJobId(Long repairJobId);
}
