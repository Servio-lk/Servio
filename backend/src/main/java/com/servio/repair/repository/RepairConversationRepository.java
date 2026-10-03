package com.servio.repair.repository;

import com.servio.repair.entity.RepairConversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RepairConversationRepository extends JpaRepository<RepairConversation, Long> {

    Optional<RepairConversation> findByRepairJobId(Long repairJobId);

    /** All conversations ordered by latest update — for admin inbox. */
    @Query("SELECT c FROM RepairConversation c ORDER BY c.updatedAt DESC")
    List<RepairConversation> findAllOrderByUpdatedAtDesc();
}

