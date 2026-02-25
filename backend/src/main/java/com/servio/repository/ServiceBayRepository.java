package com.servio.repository;

import com.servio.entity.ServiceBay;
import com.servio.entity.ServiceBayStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ServiceBayRepository extends JpaRepository<ServiceBay, Long> {
    Optional<ServiceBay> findByBayNumber(String bayNumber);

    List<ServiceBay> findByStatus(ServiceBayStatus status);

    List<ServiceBay> findByIsActiveTrue();
}
