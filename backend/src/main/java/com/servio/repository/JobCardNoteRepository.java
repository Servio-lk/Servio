package com.servio.repository;

import com.servio.entity.JobCardNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface JobCardNoteRepository extends JpaRepository<JobCardNote, Long> {
    List<JobCardNote> findByJobCardId(Long jobCardId);

    List<JobCardNote> findByJobCardIdOrderByCreatedAtDesc(Long jobCardId);
}
