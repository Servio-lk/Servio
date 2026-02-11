package com.servio.repository;

import com.servio.entity.RepairEstimate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RepairEstimateRepository extends JpaRepository<RepairEstimate, Long> {
    @Query("SELECT r FROM RepairEstimate r WHERE r.repairJob.id = :repairJobId ORDER BY r.createdAt DESC")
    List<RepairEstimate> findByRepairJobIdOrderByCreatedDateDesc(@Param("repairJobId") Long repairJobId);
    
    @Query("SELECT r FROM RepairEstimate r WHERE r.repairJob.id = :repairJobId AND r.status = :status")
    List<RepairEstimate> findByRepairJobIdAndStatus(@Param("repairJobId") Long repairJobId, @Param("status") String status);
    
    @Query("SELECT r FROM RepairEstimate r WHERE r.estimateNumber = :estimateNumber")
    Optional<RepairEstimate> findByEstimateNumber(@Param("estimateNumber") String estimateNumber);
}
