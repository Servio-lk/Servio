package com.servio.repository;

import com.servio.entity.RepairHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface RepairHistoryRepository extends JpaRepository<RepairHistory, Long> {
    @Query("SELECT r FROM RepairHistory r WHERE r.vehicle.id = :vehicleId ORDER BY r.repairDate DESC")
    List<RepairHistory> findByVehicleIdOrderByRepairDateDesc(@Param("vehicleId") Long vehicleId);
    
    @Query("SELECT r FROM RepairHistory r WHERE r.vehicle.id = :vehicleId AND r.repairDate BETWEEN :startDate AND :endDate ORDER BY r.repairDate DESC")
    List<RepairHistory> findByVehicleIdAndDateRange(
        @Param("vehicleId") Long vehicleId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );
    
    @Query("SELECT r FROM RepairHistory r WHERE r.repairJob.id = :repairJobId")
    RepairHistory findByRepairJobId(@Param("repairJobId") Long repairJobId);
}
