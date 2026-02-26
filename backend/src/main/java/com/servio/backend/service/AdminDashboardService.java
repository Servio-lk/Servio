package com.servio.backend.service;

import com.servio.dto.AppointmentDto;
import com.servio.dto.admin.DashboardStatsDto;
import com.servio.entity.Appointment;
import com.servio.repository.AppointmentRepository;
import com.servio.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    private final AppointmentRepository appointmentRepository;
    private final ProfileRepository profileRepository;

    public DashboardStatsDto getDashboardStats() {
        long totalCustomers = profileRepository.count();
        long totalAppointments = appointmentRepository.count();

        BigDecimal totalRevenue = appointmentRepository.calculateTotalRevenue();
        if (totalRevenue == null) {
            totalRevenue = BigDecimal.ZERO;
        }

        List<Appointment> upcomingEntities = appointmentRepository.findUpcomingAppointments();
        // Limit to top 5
        List<AppointmentDto> upcomingAppointments = upcomingEntities.stream()
                .limit(5)
                .map(this::convertToDto)
                .collect(Collectors.toList());

        return DashboardStatsDto.builder()
                .totalCustomers(totalCustomers)
                .totalAppointments(totalAppointments)
                .totalRevenue(totalRevenue)
                .upcomingAppointments(upcomingAppointments)
                .build();
    }

    private AppointmentDto convertToDto(Appointment appointment) {
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
                .createdAt(appointment.getCreatedAt())
                .updatedAt(appointment.getUpdatedAt())
                .build();
    }
}
