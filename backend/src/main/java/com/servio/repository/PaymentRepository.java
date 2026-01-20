package com.servio.repository;

import com.servio.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    
    List<Payment> findByUserId(Long userId);
    
    List<Payment> findByPaymentStatus(String paymentStatus);
    
    @Query("SELECT SUM(p.amount) FROM Payment p WHERE p.paymentStatus = 'COMPLETED'")
    BigDecimal getTotalRevenue();
    
    @Query("SELECT SUM(p.amount) FROM Payment p WHERE p.paymentStatus = 'COMPLETED' " +
           "AND p.paymentDate >= :startDate AND p.paymentDate <= :endDate")
    BigDecimal getRevenueForPeriod(
        @Param("startDate") LocalDateTime startDate, 
        @Param("endDate") LocalDateTime endDate
    );
    
    @Query("SELECT p FROM Payment p ORDER BY p.createdAt DESC")
    List<Payment> findRecentPayments();
    
    @Query("SELECT p FROM Payment p WHERE p.user.id = :userId ORDER BY p.paymentDate DESC")
    List<Payment> findUserPaymentsOrderByDate(@Param("userId") Long userId);
}
