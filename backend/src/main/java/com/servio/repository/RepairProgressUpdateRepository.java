package com.servio.repository;

import com.servio.entity.RepairProgressUpdate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RepairProgressUpdateRepository extends JpaRepository<RepairProgressUpdate, Long> {
    @Query("SELECT r FROM RepairProgressUpdate r WHERE r.repairJob.id = :repairJobId ORDER BY r.createdAt DESC")
    List<RepairProgressUpdate> findByRepairJobIdOrderByCreatedDateDesc(@Param("repairJobId") Long repairJobId);
    
    @Query("SELECT r FROM RepairProgressUpdate r WHERE r.repairJob.id = :repairJobId ORDER BY r.createdAt DESC LIMIT 1")
    RepairProgressUpdate findLatestProgressUpdateByRepairJobId(@Param("repairJobId") Long repairJobId);
}
