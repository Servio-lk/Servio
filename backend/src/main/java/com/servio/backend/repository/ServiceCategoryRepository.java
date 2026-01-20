package com.servio.backend.repository;

import com.servio.backend.entity.ServiceCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ServiceCategoryRepository extends JpaRepository<ServiceCategory, Long> {
    List<ServiceCategory> findByIsActiveTrueOrderByDisplayOrderAsc();
    
    @Query("SELECT DISTINCT c FROM ServiceCategory c LEFT JOIN FETCH c.services s WHERE c.isActive = true AND (s.isActive = true OR s.isActive IS NULL) ORDER BY c.displayOrder")
    List<ServiceCategory> findAllActiveWithServices();
}