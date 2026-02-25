package com.servio.repository;

import com.servio.entity.RepairImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RepairImageRepository extends JpaRepository<RepairImage, Long> {
    @Query("SELECT r FROM RepairImage r WHERE r.repairJob.id = :repairJobId ORDER BY r.createdAt DESC")
    List<RepairImage> findByRepairJobIdOrderByCreatedDateDesc(@Param("repairJobId") Long repairJobId);
    
    @Query("SELECT r FROM RepairImage r WHERE r.repairJob.id = :repairJobId AND r.imageType = :imageType ORDER BY r.createdAt DESC")
    List<RepairImage> findByRepairJobIdAndImageType(@Param("repairJobId") Long repairJobId, @Param("imageType") String imageType);
}
