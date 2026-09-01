package com.servio.booking.repository;

import com.servio.booking.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {
    List<Vehicle> findByUserId(UUID userId);
    
    @Query("SELECT v FROM Vehicle v WHERE v.user.id = :userId")
    List<Vehicle> findByProfileId(@Param("userId") UUID userId);
}
