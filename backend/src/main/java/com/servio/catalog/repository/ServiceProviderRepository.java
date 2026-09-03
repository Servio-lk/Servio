package com.servio.catalog.repository;

import com.servio.catalog.entity.ServiceProvider;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ServiceProviderRepository extends JpaRepository<ServiceProvider, Long> {
    List<ServiceProvider> findByIsActiveTrueOrderByRatingDesc();
    
    List<ServiceProvider> findByCityAndIsActiveTrue(String city);
}