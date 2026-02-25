package com.servio.repository;

import com.servio.entity.RepairPart;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RepairPartRepository extends JpaRepository<RepairPart, Long> {
    @Query("SELECT r FROM RepairPart r WHERE r.repairJob.id = :repairJobId ORDER BY r.createdAt DESC")
    List<RepairPart> findByRepairJobIdOrderByCreatedDateDesc(@Param("repairJobId") Long repairJobId);
    
    @Query("SELECT r FROM RepairPart r WHERE r.repairJob.id = :repairJobId AND r.status = :status")
    List<RepairPart> findByRepairJobIdAndStatus(@Param("repairJobId") Long repairJobId, @Param("status") String status);
}
