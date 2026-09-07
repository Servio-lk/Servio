package com.servio.admin.repository;

import com.servio.admin.entity.JobCardPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface JobCardPhotoRepository extends JpaRepository<JobCardPhoto, Long> {
    List<JobCardPhoto> findByJobCardId(Long jobCardId);
}
