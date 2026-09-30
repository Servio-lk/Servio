package com.servio.inventory.repository;

import com.servio.inventory.entity.PartRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PartRequestRepository extends JpaRepository<PartRequest, Long> {

    List<PartRequest> findByAppointmentId(Long appointmentId);

    List<PartRequest> findByAppointmentIdOrderByCreatedAtDesc(Long appointmentId);

    List<PartRequest> findByMechanicId(Long mechanicId);

    List<PartRequest> findByStatus(String status);

    List<PartRequest> findAllByOrderByCreatedAtDesc();
}
