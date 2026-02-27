package com.servio.service;

import com.servio.entity.RepairActivity;
import com.servio.repository.RepairActivityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class RepairActivityService {
    
    private final RepairActivityRepository repairActivityRepository;
    
    public RepairActivity logActivity(Long repairJobId, String activityType, String description, Long performedByUserId) {
        RepairActivity activity = RepairActivity.builder()
                .activityType(activityType)
                .description(description)
                .build();
        
        return repairActivityRepository.save(activity);
    }
    
    public List<RepairActivity> getRepairActivities(Long repairJobId) {
        return repairActivityRepository.findByRepairJobIdOrderByCreatedDateDesc(repairJobId);
    }
    
    public List<RepairActivity> getActivitiesByType(Long repairJobId, String activityType) {
        return repairActivityRepository.findByRepairJobIdAndActivityType(repairJobId, activityType);
    }
}
