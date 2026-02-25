package com.servio.service;

import com.servio.entity.*;
import com.servio.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class RepairJobService {
    
    private final RepairJobRepository repairJobRepository;
    private final RepairProgressRepository repairProgressRepository;
    private final RepairActivityRepository repairActivityRepository;
    private final AppointmentRepository appointmentRepository;
    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;
    
    public RepairJob createRepairJob(Long appointmentId, String title, String description, 
                                     Integer estimatedHours, BigDecimal estimatedCost) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new RuntimeException("Appointment not found"));
        
        RepairJob repairJob = RepairJob.builder()
                .appointment(appointment)
                .vehicle(appointment.getVehicle())
                .user(appointment.getUser())
                .title(title)
                .description(description)
                .status("INITIAL_INSPECTION")
                .priority("NORMAL")
                .estimatedDurationHours(estimatedHours)
                .estimatedCost(estimatedCost)
                .build();
        
        RepairJob savedJob = repairJobRepository.save(repairJob);
        
        // Create initial repair progress
        RepairProgress progress = RepairProgress.builder()
                .repairJob(savedJob)
                .currentStatus("INITIAL_INSPECTION")
                .progressPercentage(0)
                .lastUpdatedAt(LocalDateTime.now())
                .build();
        repairProgressRepository.save(progress);
        
        // Log activity
        RepairActivity activity = RepairActivity.builder()
                .repairJob(savedJob)
                .activityType("SYSTEM")
                .description("Repair job created: " + title)
                .performedByUser(null)
                .build();
        repairActivityRepository.save(activity);
        
        return savedJob;
    }
    
    public RepairJob updateRepairJobStatus(Long repairJobId, String newStatus) {
        RepairJob repairJob = repairJobRepository.findById(repairJobId)
                .orElseThrow(() -> new RuntimeException("Repair job not found"));
        
        repairJob.setStatus(newStatus);
        if ("COMPLETED".equals(newStatus)) {
            repairJob.setCompletionDate(LocalDateTime.now());
        } else if ("IN_PROGRESS".equals(newStatus) && repairJob.getStartDate() == null) {
            repairJob.setStartDate(LocalDateTime.now());
        }
        
        RepairJob savedJob = repairJobRepository.save(repairJob);
        
        // Update progress
        RepairProgress progress = repairProgressRepository.findByRepairJobId(repairJobId)
                .orElse(null);
        if (progress != null) {
            progress.setCurrentStatus(newStatus);
            repairProgressRepository.save(progress);
        }
        
        // Log activity
        RepairActivity activity = RepairActivity.builder()
                .repairJob(savedJob)
                .activityType("STATUS_CHANGE")
                .description("Status changed to: " + newStatus)
                .performedByUser(null)
                .build();
        repairActivityRepository.save(activity);
        
        return savedJob;
    }
    
    public RepairJob getRepairJobById(Long id) {
        return repairJobRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Repair job not found"));
    }
    
    public List<RepairJob> getUserRepairJobs(Long userId) {
        return repairJobRepository.findUserRepairJobsOrderByDate(userId);
    }
    
    public List<RepairJob> getRepairJobsByStatus(String status) {
        return repairJobRepository.findByStatusOrderByCreatedDateDesc(status);
    }
    
    public List<RepairJob> getVehicleRepairJobs(Long vehicleId) {
        return repairJobRepository.findByVehicleId(vehicleId);
    }
    
    public void deleteRepairJob(Long id) {
        repairJobRepository.deleteById(id);
    }
}
