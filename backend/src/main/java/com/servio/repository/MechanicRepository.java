package com.servio.repository;

import com.servio.entity.Mechanic;
import com.servio.entity.MechanicStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface MechanicRepository extends JpaRepository<Mechanic, Long> {
    Optional<Mechanic> findByEmail(String email);

    List<Mechanic> findByStatus(MechanicStatus status);

    List<Mechanic> findBySpecialization(String specialization);

    List<Mechanic> findByIsActiveTrue();
}
