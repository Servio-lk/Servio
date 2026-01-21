package com.servio.repository;

import com.servio.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {
    
    List<Review> findByUserId(Long userId);
    
    List<Review> findByAppointmentId(Long appointmentId);
    
    @Query("SELECT AVG(r.rating) FROM Review r")
    Double getAverageRating();
    
    @Query("SELECT r FROM Review r ORDER BY r.createdAt DESC")
    List<Review> findRecentReviews();
    
    @Query("SELECT r FROM Review r WHERE r.rating >= :minRating ORDER BY r.createdAt DESC")
    List<Review> findReviewsByMinRating(@Param("minRating") Integer minRating);
}
