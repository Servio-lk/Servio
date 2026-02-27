package com.servio.repository;

import com.servio.entity.RepairActivity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RepairActivityRepository extends JpaRepository<RepairActivity, Long> {
    @Query("SELECT r FROM RepairActivity r WHERE r.repairJob.id = :repairJobId ORDER BY r.createdAt DESC")
    List<RepairActivity> findByRepairJobIdOrderByCreatedDateDesc(@Param("repairJobId") Long repairJobId);
    
    @Query("SELECT r FROM RepairActivity r WHERE r.repairJob.id = :repairJobId AND r.activityType = :activityType ORDER BY r.createdAt DESC")
    List<RepairActivity> findByRepairJobIdAndActivityType(@Param("repairJobId") Long repairJobId, @Param("activityType") String activityType);
}
