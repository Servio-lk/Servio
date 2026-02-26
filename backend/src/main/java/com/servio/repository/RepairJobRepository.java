package com.servio.repository;

import com.servio.entity.RepairJob;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RepairJobRepository extends JpaRepository<RepairJob, Long> {
    List<RepairJob> findByUserId(Long userId);
    
    List<RepairJob> findByVehicleId(Long vehicleId);
    
    List<RepairJob> findByStatus(String status);
    
    @Query("SELECT r FROM RepairJob r WHERE r.user.id = :userId ORDER BY r.createdAt DESC")
    List<RepairJob> findUserRepairJobsOrderByDate(@Param("userId") Long userId);
    
    @Query("SELECT r FROM RepairJob r WHERE r.status = :status ORDER BY r.createdAt DESC")
    List<RepairJob> findByStatusOrderByCreatedDateDesc(@Param("status") String status);
    
    @Query("SELECT r FROM RepairJob r WHERE r.appointment.id = :appointmentId")
    RepairJob findByAppointmentId(@Param("appointmentId") Long appointmentId);
}
