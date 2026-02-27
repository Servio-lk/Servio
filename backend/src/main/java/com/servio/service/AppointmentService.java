package com.servio.service;

import com.servio.dto.*;

import com.servio.entity.Appointment;
import com.servio.entity.Profile;
import com.servio.entity.User;
import com.servio.entity.Vehicle;
import com.servio.repository.AppointmentRepository;
import com.servio.repository.ProfileRepository;
import com.servio.repository.UserRepository;
import com.servio.repository.VehicleRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;
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
    private final ProfileRepository profileRepository;
    private final JdbcTemplate jdbcTemplate;
    private final EntityManager entityManager;
    private final AppointmentEventPublisher eventPublisher;

    @Transactional
    public AppointmentDto createAppointment(AppointmentRequest request, Authentication authentication) {
        User user = null;
        Profile profile = null;

        // Get user from authentication context
        if (authentication != null && authentication.isAuthenticated()) {
            String userId = authentication.getPrincipal().toString();
            String role = resolveRole(authentication);

            // Try to parse as UUID (Supabase user)
            try {
                UUID profileId = UUID.fromString(userId);
                profile = profileRepository.findById(profileId).orElse(null);
                if (profile == null) {
                    createProfileIfMissing(profileId, request, role);
                    profile = profileRepository.findById(profileId)
                            .orElseThrow(() -> new RuntimeException("Profile not found with ID: " + userId));
                } else {
                    // Profile exists from Supabase auth, but may not have full_name
                    // Update it if the customer name is provided
                    ensureProfileHasName(profileId, request);
                    // Refresh the profile to get the latest data
                    profile = profileRepository.findById(profileId).orElse(profile);
                }
            } catch (IllegalArgumentException e) {
                // Not a UUID, try as Long (local user)
                try {
                    Long localUserId = Long.parseLong(userId);
                    user = userRepository.findById(localUserId)
                            .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));
                } catch (NumberFormatException nfe) {
                    throw new RuntimeException("Invalid user ID format: " + userId);
                }
            }
        } else if (request.getUserId() != null) {
            // Fallback to request userId for backwards compatibility
            user = userRepository.findById(request.getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found with ID: " + request.getUserId()));
        } else {
            throw new RuntimeException("User authentication required to create appointment");
        }

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
                .profile(profile)
                .vehicle(vehicle)
                .serviceType(request.getServiceType())
                .appointmentDate(request.getAppointmentDate())
                .location(request.getLocation())
                .notes(request.getNotes())
                .estimatedCost(request.getEstimatedCost())
                .status("PENDING")
                .build();

        appointment = appointmentRepository.save(appointment);
        AppointmentDto dto = convertToDto(appointment);
        eventPublisher.publish("CREATED", dto);
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

    private void createProfileIfMissing(UUID profileId, AppointmentRequest request, String role) {
        jdbcTemplate.update(
                "INSERT INTO profiles (id, full_name, email, phone, role, is_admin, created_at, joined) "
                        + "VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW()) ON CONFLICT (id) DO NOTHING",
                profileId,
                request.getCustomerName(),
                request.getCustomerEmail(),
                request.getCustomerPhone(),
                role,
                "ADMIN".equalsIgnoreCase(role));
    }

    private void ensureProfileHasName(UUID profileId, AppointmentRequest request) {
        // Update profile with customer name and contact info if they're empty
        if (request.getCustomerName() != null && !request.getCustomerName().trim().isEmpty()) {
            jdbcTemplate.update(
                    "UPDATE profiles SET full_name = COALESCE(NULLIF(full_name, ''), ?), "
                            + "email = COALESCE(NULLIF(email, ''), ?), "
                            + "phone = COALESCE(NULLIF(phone, ''), ?) "
                            + "WHERE id = ? AND (full_name IS NULL OR full_name = '')",
                    request.getCustomerName(),
                    request.getCustomerEmail(),
                    request.getCustomerPhone(),
                    profileId);
            // Ensure Hibernate doesn't cache the old value
            entityManager.getEntityManagerFactory().getCache().evict(Profile.class, profileId);
        }
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
            Long localUserId = Long.parseLong(userId);
            return appointmentRepository.findUserAppointmentsOrderByCreatedAt(localUserId).stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
        } catch (NumberFormatException e) {
            try {
                UUID profileId = UUID.fromString(userId);
                return appointmentRepository.findProfileAppointmentsOrderByDate(profileId).stream()
                        .map(this::convertToDto)
                        .collect(Collectors.toList());
            } catch (IllegalArgumentException ex) {
                return List.of();
            }
        }
    }

    /**
     * Returns appointments for the currently authenticated user by reading
     * the user ID directly from the JWT — no need for the frontend to pass it.
     */
    @Transactional(readOnly = true)
    public List<AppointmentDto> getMyAppointments(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return List.of();
        }
        String userId = authentication.getPrincipal().toString();
        return getUserAppointments(userId);
    }

    @Transactional(readOnly = true)
    public List<AppointmentDto> getMyAppointments(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new RuntimeException("User not authenticated");
        }

        String userId = authentication.getPrincipal().toString();

        // Try to parse as UUID (Supabase user)
        try {
            UUID profileId = UUID.fromString(userId);
            return appointmentRepository.findProfileAppointmentsOrderByDate(profileId).stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
        } catch (IllegalArgumentException e) {
            // Not a UUID, try as Long (local user)
            try {
                Long localUserId = Long.parseLong(userId);
                return appointmentRepository.findUserAppointmentsOrderByDate(localUserId).stream()
                        .map(this::convertToDto)
                        .collect(Collectors.toList());
            } catch (NumberFormatException nfe) {
                throw new RuntimeException("Invalid user ID format: " + userId);
            }
        }
    }

    @Transactional(readOnly = true)
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
        AppointmentDto dto = convertToDto(appointment);
        eventPublisher.publish("UPDATED", dto);
        return dto;
    }

    @Transactional
    public void deleteAppointment(Long id) {
        appointmentRepository.deleteById(id);
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
        Long userId = null;
        String userName = null;
        String userEmail = null;

        // Check if this is a profile-based appointment (Supabase) or user-based (local)
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
