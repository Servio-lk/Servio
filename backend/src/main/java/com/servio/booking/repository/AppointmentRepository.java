package com.servio.booking.repository;

import com.servio.payment.entity.Payment;

import com.servio.booking.entity.Appointment;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Long> {

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle ORDER BY a.createdAt DESC")
        List<Appointment> findAll();

        List<Appointment> findByUserId(UUID userId);

        void deleteByUserIdAndStatusIn(UUID userId, List<String> statuses);

        long countByUserIdAndStatusIn(UUID userId, List<String> statuses);

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle WHERE a.status = :status ORDER BY a.appointmentDate DESC")
        List<Appointment> findByStatus(@Param("status") String status);

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle WHERE a.status = :status ORDER BY a.appointmentDate DESC")
        List<Appointment> findByStatusOrderByAppointmentDateDesc(@Param("status") String status);

        @Query("SELECT COUNT(a) FROM Appointment a WHERE a.status = :status")
        Long countByStatus(@Param("status") String status);

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle ORDER BY a.createdAt DESC")
        List<Appointment> findRecentAppointments();

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle WHERE a.appointmentDate BETWEEN :startDate AND :endDate")
        List<Appointment> findAppointmentsBetweenDates(
                        @Param("startDate") LocalDateTime startDate,
                        @Param("endDate") LocalDateTime endDate);

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle WHERE a.user.id = :userId ORDER BY a.appointmentDate DESC")
        List<Appointment> findUserAppointmentsOrderByDate(@Param("userId") UUID userId);

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle WHERE a.user.id = :userId ORDER BY a.createdAt DESC")
        List<Appointment> findUserAppointmentsOrderByCreatedAt(@Param("userId") UUID userId);

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle WHERE a.appointmentDate = :appointmentDate AND a.status NOT IN :excludeStatuses")
        List<Appointment> findByAppointmentDateAndStatusNotIn(
                        @Param("appointmentDate") LocalDateTime appointmentDate,
                        @Param("excludeStatuses") List<String> excludeStatuses);

        @Lock(LockModeType.PESSIMISTIC_WRITE)
        @Query("SELECT a FROM Appointment a WHERE a.appointmentDate = :appointmentDate AND a.status NOT IN :excludeStatuses")
        List<Appointment> findForUpdateByAppointmentDateAndStatusNotIn(
                        @Param("appointmentDate") LocalDateTime appointmentDate,
                        @Param("excludeStatuses") List<String> excludeStatuses);

        // Returns all active appointments for a given date (used to show booked slots
        // to customers)
        @Query("SELECT a FROM Appointment a WHERE a.appointmentDate >= :startOfDay AND a.appointmentDate < :endOfDay AND a.status NOT IN ('CANCELLED')")
        List<Appointment> findBookedSlotsForDate(
                        @Param("startOfDay") LocalDateTime startOfDay,
                        @Param("endOfDay") LocalDateTime endOfDay);

        @Query("SELECT SUM(a.actualCost) FROM Appointment a WHERE a.status = 'COMPLETED'")
        java.math.BigDecimal calculateTotalRevenue();

        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle WHERE a.appointmentDate >= CURRENT_TIMESTAMP AND a.status NOT IN ('CANCELLED', 'COMPLETED') ORDER BY a.appointmentDate ASC")
        List<Appointment> findUpcomingAppointments();

        // Appointments whose date falls within [windowStart, windowEnd] — used by reminder scheduler
        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user " +
               "WHERE a.appointmentDate >= :windowStart AND a.appointmentDate < :windowEnd " +
               "AND a.status NOT IN ('CANCELLED', 'COMPLETED')")
        List<Appointment> findUpcomingAppointmentsInWindow(
                        @Param("windowStart") LocalDateTime windowStart,
                        @Param("windowEnd") LocalDateTime windowEnd);

        // Appointments stuck in PENDING_PAYMENT that were created before a given cutoff
        // — used by the expiry scheduler to auto-release time slots after 10 minutes.
        @Query("SELECT a FROM Appointment a WHERE a.status = 'PENDING_PAYMENT' AND a.createdAt < :cutoff")
        List<Appointment> findExpiredPendingPayments(@Param("cutoff") LocalDateTime cutoff);

        // CONFIRMED or IN_PROGRESS appointments that have no completed payment yet
        // — used to identify appointments needing cash collection.
        @Query("SELECT DISTINCT a FROM Appointment a LEFT JOIN FETCH a.user LEFT JOIN FETCH a.vehicle " +
               "WHERE a.status IN ('CONFIRMED', 'IN_PROGRESS') " +
               "AND NOT EXISTS (SELECT p FROM Payment p WHERE p.appointment = a AND p.paymentStatus = 'COMPLETED') " +
               "ORDER BY a.appointmentDate ASC")
        List<Appointment> findAppointmentsNeedingPayment();
}
