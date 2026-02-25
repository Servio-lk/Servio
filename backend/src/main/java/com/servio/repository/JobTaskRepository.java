package com.servio.repository;

import com.servio.entity.JobTask;
import com.servio.entity.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface JobTaskRepository extends JpaRepository<JobTask, Long> {
    List<JobTask> findByJobCardId(Long jobCardId);

    List<JobTask> findByAssignedMechanicId(Long mechanicId);

    List<JobTask> findByStatus(TaskStatus status);

    List<JobTask> findByJobCardIdOrderBySequenceOrder(Long jobCardId);
}
