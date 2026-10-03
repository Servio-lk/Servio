package com.servio.catalog.service;

import com.servio.admin.dto.DashboardStatsDto;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.catalog.repository.ServiceRepository;
import com.servio.payment.entity.Payment;
import com.servio.payment.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    private final AppointmentRepository appointmentRepository;
    private final UserRepository userRepository;
    private final PaymentRepository paymentRepository;
    private final ServiceRepository serviceRepository;

    public DashboardStatsDto getDashboardStats() {
        long totalCustomers = userRepository.count();
        long totalAppointments = appointmentRepository.count();
        long pendingAppointments = appointmentRepository.countByStatus("PENDING");
        long totalServices = serviceRepository.count();
        long activeServices = serviceRepository.countByIsActiveTrue();
        LocalDateTime startOfToday = LocalDate.now().atStartOfDay();
        long bookingsToday = appointmentRepository.countBookingsBetween(startOfToday, startOfToday.plusDays(1));
        BigDecimal unpaidBookings = appointmentRepository.sumUnpaidEstimatedCost();
        if (unpaidBookings == null) unpaidBookings = BigDecimal.ZERO;

        // Payments table is the authoritative revenue source
        BigDecimal totalRevenue = paymentRepository.getTotalRevenue();
        if (totalRevenue == null) totalRevenue = BigDecimal.ZERO;

        BigDecimal cardRevenue = paymentRepository.getRevenueByPaymentMethods(
                Arrays.asList("CREDIT_CARD", "DEBIT_CARD", "WALLET"));
        if (cardRevenue == null) cardRevenue = BigDecimal.ZERO;

        BigDecimal cashRevenue = paymentRepository.getRevenueByPaymentMethods(
                Arrays.asList("CASH"));
        if (cashRevenue == null) cashRevenue = BigDecimal.ZERO;

        // Appointments awaiting cash collection
        List<Appointment> pendingCashEntities = appointmentRepository.findAppointmentsNeedingPayment();
        BigDecimal pendingCashRevenue = pendingCashEntities.stream()
                .map(a -> a.getEstimatedCost() != null ? a.getEstimatedCost() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<AppointmentDto> pendingCashAppointments = pendingCashEntities.stream()
                .limit(10)
                .map(this::convertToDto)
                .collect(Collectors.toList());

        List<Appointment> upcomingEntities = appointmentRepository.findUpcomingAppointments();
        List<AppointmentDto> upcomingAppointments = upcomingEntities.stream()
                .limit(5)
                .map(this::convertToDto)
                .collect(Collectors.toList());

        return DashboardStatsDto.builder()
                .totalCustomers(totalCustomers)
                .totalAppointments(totalAppointments)
                .pendingAppointments(pendingAppointments)
                .bookingsToday(bookingsToday)
                .totalServices(totalServices)
                .activeServices(activeServices)
                .unpaidBookings(unpaidBookings)
                .totalRevenue(totalRevenue)
                .cardRevenue(cardRevenue)
                .cashRevenue(cashRevenue)
                .pendingCashRevenue(pendingCashRevenue)
                .upcomingAppointments(upcomingAppointments)
                .pendingCashAppointments(pendingCashAppointments)
                .build();
    }

    AppointmentDto convertToDto(Appointment appointment) {
        UUID userId = null;
        String userName = null;
        String userEmail = null;

        if (appointment.getUser() != null) {
            userId = appointment.getUser().getId();
            userName = appointment.getUser().getFullName();
            userEmail = appointment.getUser().getEmail();
        }

        List<Payment> completedPayments = paymentRepository.findCompletedPaymentsByAppointmentId(appointment.getId());
        BigDecimal paidAmount = completedPayments.stream()
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        String paymentMethod = completedPayments.isEmpty() ? null : completedPayments.get(0).getPaymentMethod();

        return AppointmentDto.builder()
                .id(appointment.getId())
                .userId(userId)
                .profileId(userId != null ? userId.toString() : null)
                .userName(userName)
                .userEmail(userEmail)
                .vehicleId(appointment.getVehicle() != null ? appointment.getVehicle().getId() : null)
                .vehicleMake(appointment.getVehicle() != null ? appointment.getVehicle().getMake() : null)
                .vehicleModel(appointment.getVehicle() != null ? appointment.getVehicle().getModel() : null)
                .serviceType(appointment.getServiceType())
                .appointmentDate(appointment.getAppointmentDate())
                .status(appointment.getStatus())
                .location(appointment.getLocation())
                .notes(appointment.getNotes())
                .estimatedCost(appointment.getEstimatedCost())
                .actualCost(appointment.getActualCost())
                .paidAmount(paidAmount)
                .paymentMethod(paymentMethod)
                .createdAt(appointment.getCreatedAt())
                .updatedAt(appointment.getUpdatedAt())
                .build();
    }
}