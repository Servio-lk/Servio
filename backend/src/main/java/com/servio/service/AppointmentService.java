package com.servio.service;

import com.servio.dto.*;
import com.servio.entity.Appointment;
import com.servio.entity.User;
import com.servio.entity.Vehicle;
import com.servio.repository.AppointmentRepository;
import com.servio.repository.UserRepository;
import com.servio.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;

    @Transactional
    public AppointmentDto createAppointment(AppointmentRequest request) {
        // If userId is not provided, use a default test user (ID: 1)
        Long userId = request.getUserId() != null ? request.getUserId() : 1L;

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));

        // Check if the time slot is already booked
        List<Appointment> existingAppointments = appointmentRepository
                .findByAppointmentDateAndStatusNotIn(
                        request.getAppointmentDate(),
                        List.of("CANCELLED"));

        if (!existingAppointments.isEmpty()) {
            throw new RuntimeException("This time slot is already booked. Please choose another time.");
        }

        Vehicle vehicle = null;
        if (request.getVehicleId() != null) {
            vehicle = vehicleRepository.findById(request.getVehicleId())
                    .orElseThrow(() -> new RuntimeException("Vehicle not found"));
        }

        Appointment appointment = Appointment.builder()
                .user(user)
                .vehicle(vehicle)
                .serviceType(request.getServiceType())
                .appointmentDate(request.getAppointmentDate())
                .location(request.getLocation())
                .notes(request.getNotes())
                .estimatedCost(request.getEstimatedCost())
                .status("PENDING")
                .build();

        appointment = appointmentRepository.save(appointment);
        return convertToDto(appointment);
    }

    public List<AppointmentDto> getAllAppointments() {
        return appointmentRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<AppointmentDto> getRecentAppointments() {
        return appointmentRepository.findRecentAppointments().stream()
                .limit(10)
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<AppointmentDto> getAppointmentsByStatus(String status) {
        return appointmentRepository.findByStatusOrderByAppointmentDateDesc(status).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<AppointmentDto> getUserAppointments(Long userId) {
        return appointmentRepository.findUserAppointmentsOrderByDate(userId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public AppointmentDto getAppointmentById(Long id) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Appointment not found"));
        return convertToDto(appointment);
    }

    @Transactional
    public AppointmentDto updateAppointmentStatus(Long id, String status) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Appointment not found"));

        appointment.setStatus(status);
        appointment = appointmentRepository.save(appointment);
        return convertToDto(appointment);
    }

    @Transactional
    public void deleteAppointment(Long id) {
        appointmentRepository.deleteById(id);
    }

    private AppointmentDto convertToDto(Appointment appointment) {
        return AppointmentDto.builder()
                .id(appointment.getId())
                .userId(appointment.getUser().getId())
                .userName(appointment.getUser().getFullName())
                .userEmail(appointment.getUser().getEmail())
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
