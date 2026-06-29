package com.servio.repository;

import com.servio.entity.MechanicStaffDetails;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MechanicStaffDetailsRepository extends JpaRepository<MechanicStaffDetails, Long> {
    Optional<MechanicStaffDetails> findByMechanicId(Long mechanicId);

    boolean existsByEmployeeCodeAndMechanicIdNot(String employeeCode, Long mechanicId);

    boolean existsByEmployeeCode(String employeeCode);

    @Query("SELECT d.employeeCode FROM MechanicStaffDetails d WHERE d.employeeCode IS NOT NULL")
    List<String> findAllEmployeeCodes();
}
