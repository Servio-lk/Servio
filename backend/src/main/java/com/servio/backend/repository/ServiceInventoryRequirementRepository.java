package com.servio.backend.repository;

import com.servio.backend.entity.ServiceInventoryRequirement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ServiceInventoryRequirementRepository extends JpaRepository<ServiceInventoryRequirement, Long> {
    List<ServiceInventoryRequirement> findByServiceId(Long serviceId);
}
