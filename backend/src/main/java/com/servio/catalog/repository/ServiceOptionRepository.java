package com.servio.catalog.repository;

import com.servio.catalog.entity.ServiceOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ServiceOptionRepository extends JpaRepository<ServiceOption, Long> {
    List<ServiceOption> findByServiceIdOrderByDisplayOrderAsc(Long serviceId);
}