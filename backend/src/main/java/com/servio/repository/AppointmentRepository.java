package com.servio.repository;

import com.servio.entity.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Long> {
    
    List<Appointment> findByUserId(Long userId);
    
    List<Appointment> findByStatus(String status);
    
    List<Appointment> findByStatusOrderByAppointmentDateDesc(String status);
    
    @Query("SELECT COUNT(a) FROM Appointment a WHERE a.status = :status")
    Long countByStatus(@Param("status") String status);
    
    @Query("SELECT a FROM Appointment a ORDER BY a.createdAt DESC")
    List<Appointment> findRecentAppointments();
    
    @Query("SELECT a FROM Appointment a WHERE a.appointmentDate BETWEEN :startDate AND :endDate")
    List<Appointment> findAppointmentsBetweenDates(
        @Param("startDate") LocalDateTime startDate, 
        @Param("endDate") LocalDateTime endDate
    );
    
    @Query("SELECT a FROM Appointment a WHERE a.user.id = :userId ORDER BY a.appointmentDate DESC")
    List<Appointment> findUserAppointmentsOrderByDate(@Param("userId") Long userId);
}
