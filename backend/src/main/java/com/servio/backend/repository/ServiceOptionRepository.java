package com.servio.backend.repository;

import com.servio.backend.entity.ServiceOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ServiceOptionRepository extends JpaRepository<ServiceOption, Long> {
    List<ServiceOption> findByServiceIdOrderByDisplayOrderAsc(Long serviceId);
}