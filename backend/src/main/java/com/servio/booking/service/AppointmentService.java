package com.servio.booking.service;

import com.servio.auth.entity.Role;
import com.servio.auth.entity.User;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.dto.AppointmentRequest;
import com.servio.booking.entity.Appointment;
import com.servio.booking.entity.Vehicle;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.booking.repository.VehicleRepository;
import com.servio.common.event.AppointmentCreatedEvent;
import com.servio.common.event.RepairStatusChangedEvent;
import com.servio.common.exception.ConflictException;
import com.servio.common.exception.ResourceNotFoundException;
import com.servio.notification.service.AppointmentEventPublisher;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;
    private final JdbcTemplate jdbcTemplate;
    private final EntityManager entityManager;
    private final AppointmentEventPublisher eventPublisher;
    private final ApplicationEventPublisher applicationEventPublisher;

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public AppointmentDto createAppointment(AppointmentRequest request, Authentication authentication) {
        User user = null;

        // Get user from authentication context
        if (authentication != null && authentication.isAuthenticated()) {
            String userIdStr = authentication.getPrincipal().toString();
            try {
                UUID userUuid = UUID.fromString(userIdStr);
                user = userRepository.findById(userUuid).orElseGet(() -> {
                    String role = resolveRole(authentication);
                    Role userRole = "ADMIN".equalsIgnoreCase(role) ? Role.ADMIN : Role.USER;
                    return userRepository.save(User.builder()
                            .id(userUuid)
                            .fullName(request.getCustomerName() != null && !request.getCustomerName().isBlank() 
                                    ? request.getCustomerName() : "Customer")
                            .email(request.getCustomerEmail() != null && !request.getCustomerEmail().isBlank() 
                                    ? request.getCustomerEmail() : userUuid + "@servio.lk")
                            .phone(request.getCustomerPhone())
                            .passwordHash("")
                            .role(userRole)
                            .build());
                });
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Invalid user UUID format: " + userIdStr);
            }
        } else if (request.getUserId() != null) {
            user = userRepository.findById(request.getUserId())
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + request.getUserId()));
        } else {
            throw new IllegalArgumentException("User authentication required to create appointment");
        }

        // Check if the time slot is already booked with pessimistic locking
        List<Appointment> existingAppointments = appointmentRepository
                .findForUpdateByAppointmentDateAndStatusNotIn(
                        request.getAppointmentDate(),
                        List.of("CANCELLED"));

        if (!existingAppointments.isEmpty()) {
            throw new ConflictException("This time slot is already booked. Please choose another time.");
        }

        Vehicle vehicle = null;
        if (request.getVehicleId() != null) {
            vehicle = vehicleRepository.findById(request.getVehicleId())
                    .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + request.getVehicleId()));
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

        try {
            appointment = appointmentRepository.saveAndFlush(appointment);
        } catch (DataIntegrityViolationException ex) {
            throw new ConflictException("This time slot is already booked. Please choose another time.");
        }
        AppointmentDto dto = convertToDto(appointment);
        eventPublisher.publish("CREATED", dto);

        // Send booking confirmation notification to the user
        if (user != null) {
            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("MMM d, yyyy 'at' h:mm a");
            String dateStr = appointment.getAppointmentDate().format(fmt);
            
            applicationEventPublisher.publishEvent(new com.servio.common.event.AppointmentCreatedEvent(
                this, 
                appointment.getId(), 
                user.getId(), 
                appointment.getServiceType(), 
                dateStr
            ));
        }

        return dto;
    }

    private String resolveRole(Authentication authentication) {
        if (authentication == null || authentication.getAuthorities() == null) {
            return "USER";
        }

        for (GrantedAuthority authority : authentication.getAuthorities()) {
            if (authority != null && authority.getAuthority() != null) {
                return authority.getAuthority();
            }
        }

        return "USER";
    }

    @Transactional(readOnly = true)
    public List<AppointmentDto> getAllAppointments() {
        return appointmentRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AppointmentDto> getRecentAppointments() {
        return appointmentRepository.findRecentAppointments().stream()
                .limit(10)
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AppointmentDto> getAppointmentsByStatus(String status) {
        return appointmentRepository.findByStatusOrderByAppointmentDateDesc(status).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AppointmentDto> getUserAppointments(String userId) {
        try {
            UUID userUuid = UUID.fromString(userId);
            return appointmentRepository.findUserAppointmentsOrderByCreatedAt(userUuid).stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
        } catch (IllegalArgumentException ex) {
            return List.of();
        }
    }

    @Transactional(readOnly = true)
    public List<AppointmentDto> getMyAppointments(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new SecurityException("User not authenticated");
        }

        String userId = authentication.getPrincipal().toString();
        try {
            UUID userUuid = UUID.fromString(userId);
            return appointmentRepository.findUserAppointmentsOrderByDate(userUuid).stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid user ID format: " + userId);
        }
    }

    @Transactional(readOnly = true)
    public AppointmentDto getAppointmentById(Long id) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id: " + id));
        return convertToDto(appointment);
    }

    @Transactional
    public AppointmentDto updateAppointmentStatus(Long id, String status) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id: " + id));

        appointment.setStatus(status);
        appointment = appointmentRepository.save(appointment);
        AppointmentDto dto = convertToDto(appointment);
        eventPublisher.publish("UPDATED", dto);

        // Notify the user about the status change
        if (appointment.getUser() != null) {
            String statusMsg = switch (status.toUpperCase()) {
                case "CONFIRMED"   -> "Your appointment for " + appointment.getServiceType() + " has been confirmed!";
                case "IN_PROGRESS" -> "Your " + appointment.getServiceType() + " service has started.";
                case "COMPLETED"   -> "Your " + appointment.getServiceType() + " service is complete. Thank you!";
                case "CANCELLED"   -> "Your appointment for " + appointment.getServiceType() + " has been cancelled.";
                default            -> "Your appointment status has been updated to " + status + ".";
            };
            
            applicationEventPublisher.publishEvent(new com.servio.common.event.RepairStatusChangedEvent(
                this,
                appointment.getId(),
                appointment.getUser().getId(),
                status,
                statusMsg
            ));
        }

        return dto;
    }

    @Transactional
    public void deleteAppointment(Long id) {
        appointmentRepository.deleteById(id);
    }

    /**
     * Cancels an appointment, verifying that the requester is the owner.
     * Used by the customer when they dismiss the PayHere payment modal, so the
     * reserved time slot is immediately released back for booking.
     */
    @Transactional
    public AppointmentDto cancelOwnAppointment(Long id, Authentication authentication) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Appointment not found: " + id));

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new SecurityException("Authentication required");
        }

        String userId = authentication.getPrincipal().toString();
        boolean isOwner = false;
        try {
            UUID userUuid = UUID.fromString(userId);
            isOwner = appointment.getUser() != null
                    && userUuid.equals(appointment.getUser().getId());
        } catch (IllegalArgumentException ignored) {}

        if (!isOwner) {
            throw new SecurityException("You can only cancel your own appointments");
        }

        appointment.setStatus("CANCELLED");
        appointment = appointmentRepository.save(appointment);
        return convertToDto(appointment);
    }

    @Transactional(readOnly = true)
    public List<String> getBookedSlotsForDate(LocalDate date) {
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();
        return appointmentRepository.findBookedSlotsForDate(startOfDay, endOfDay)
                .stream()
                .map(a -> {
                    // Format as "HH:mm" — this is what the frontend parses from the slot label
                    DateTimeFormatter fmt = DateTimeFormatter.ofPattern("HH:mm");
                    return a.getAppointmentDate().format(fmt);
                })
                .collect(Collectors.toList());
    }

    private AppointmentDto convertToDto(Appointment appointment) {
        UUID userId = appointment.getUser() != null ? appointment.getUser().getId() : null;
        String userName = appointment.getUser() != null ? appointment.getUser().getFullName() : null;
        String userEmail = appointment.getUser() != null ? appointment.getUser().getEmail() : null;

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
                .createdAt(appointment.getCreatedAt())
                .updatedAt(appointment.getUpdatedAt())
                .build();
    }
}
