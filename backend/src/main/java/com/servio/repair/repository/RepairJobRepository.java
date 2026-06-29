package com.servio.repair.repository;

import com.servio.repair.entity.RepairJob;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

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

    Optional<RepairJob> findFirstByAppointmentId(Long appointmentId);

    long countByAssignedTechnicianIdAndStatusNotIn(Long assignedTechnicianId, List<String> statuses);
}
