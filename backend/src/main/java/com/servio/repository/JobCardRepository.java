package com.servio.repository;

import com.servio.entity.JobCard;
import com.servio.entity.JobCardStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface JobCardRepository extends JpaRepository<JobCard, Long> {
    Optional<JobCard> findByJobNumber(String jobNumber);

    List<JobCard> findByAppointmentId(Long appointmentId);

    List<JobCard> findByAssignedMechanicId(Long mechanicId);

    List<JobCard> findByStatus(JobCardStatus status);

    List<JobCard> findByAssignedBayId(Long bayId);
}
