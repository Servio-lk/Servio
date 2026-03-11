package com.servio.backend.service;

import com.servio.dto.AppointmentDto;
import com.servio.dto.admin.DashboardStatsDto;
import com.servio.entity.Appointment;
import com.servio.entity.Payment;
import com.servio.repository.AppointmentRepository;
import com.servio.repository.PaymentRepository;
import com.servio.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    private final AppointmentRepository appointmentRepository;
    private final ProfileRepository profileRepository;
    private final PaymentRepository paymentRepository;

    public DashboardStatsDto getDashboardStats() {
        long totalCustomers = profileRepository.count();
        long totalAppointments = appointmentRepository.count();

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
                .totalRevenue(totalRevenue)
                .cardRevenue(cardRevenue)
                .cashRevenue(cashRevenue)
                .pendingCashRevenue(pendingCashRevenue)
                .upcomingAppointments(upcomingAppointments)
                .pendingCashAppointments(pendingCashAppointments)
                .build();
    }

    AppointmentDto convertToDto(Appointment appointment) {
        Long userId = null;
        String userName = null;
        String userEmail = null;

        if (appointment.getProfile() != null) {
            userName = appointment.getProfile().getFullName();
            userEmail = appointment.getProfile().getEmail();
        } else if (appointment.getUser() != null) {
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
