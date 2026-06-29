package com.servio.admin.repository;

import com.servio.admin.entity.Mechanic;
import com.servio.admin.entity.MechanicStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface MechanicRepository extends JpaRepository<Mechanic, Long> {
    Optional<Mechanic> findByEmail(String email);

    Optional<Mechanic> findByEmailIgnoreCase(String email);

    List<Mechanic> findByStatus(MechanicStatus status);

    List<Mechanic> findBySpecialization(String specialization);

    List<Mechanic> findByIsActiveTrue();
}
