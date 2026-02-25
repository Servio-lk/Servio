package com.servio.service;

import com.servio.entity.RepairProgressUpdate;
import com.servio.repository.RepairProgressUpdateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class RepairProgressService {
    
    private final RepairProgressUpdateRepository repairProgressUpdateRepository;
    
    public RepairProgressUpdate createProgressUpdate(Long repairJobId, String status, 
                                                      Integer progressPercentage, String description) {
        RepairProgressUpdate update = RepairProgressUpdate.builder()
                .status(status)
                .progressPercentage(progressPercentage != null ? progressPercentage : 0)
                .description(description)
                .estimatedCompletionTime(LocalDateTime.now().plusDays(1))
                .build();
        
        return repairProgressUpdateRepository.save(update);
    }
    
    public List<RepairProgressUpdate> getProgressUpdates(Long repairJobId) {
        return repairProgressUpdateRepository.findByRepairJobIdOrderByCreatedDateDesc(repairJobId);
    }
    
    public RepairProgressUpdate getLatestProgressUpdate(Long repairJobId) {
        return repairProgressUpdateRepository.findLatestProgressUpdateByRepairJobId(repairJobId);
    }
}
