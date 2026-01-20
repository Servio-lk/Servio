package com.servio.backend.repository;

import com.servio.backend.entity.Service;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ServiceRepository extends JpaRepository<Service, Long> {
    List<Service> findByIsActiveTrueOrderByNameAsc();
    
    List<Service> findByIsFeaturedTrueAndIsActiveTrue();
    
    List<Service> findByCategoryIdAndIsActiveTrue(Long categoryId);
    
    @Query("SELECT s FROM Service s WHERE s.isActive = true AND (LOWER(s.name) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(s.description) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Service> searchServices(@Param("query") String query);
    
    @Query("SELECT s FROM Service s LEFT JOIN FETCH s.options WHERE s.id = :id AND s.isActive = true")
    Optional<Service> findByIdWithOptions(@Param("id") Long id);
}