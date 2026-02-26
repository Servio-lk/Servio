package com.servio.repository;

import com.servio.entity.RepairProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RepairProgressRepository extends JpaRepository<RepairProgress, Long> {
    @Query("SELECT r FROM RepairProgress r WHERE r.repairJob.id = :repairJobId")
    Optional<RepairProgress> findByRepairJobId(@Param("repairJobId") Long repairJobId);
}
