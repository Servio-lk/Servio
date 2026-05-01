package com.servio.service;

import com.servio.dto.ServiceRecordDto;
import com.servio.dto.VehicleDto;
import com.servio.dto.VehicleRequest;
import com.servio.dto.VehicleStatsDto;
import com.servio.entity.Profile;
import com.servio.entity.User;
import com.servio.entity.Vehicle;
import com.servio.entity.ServiceRecord;
import com.servio.repository.ProfileRepository;
import com.servio.repository.UserRepository;
import com.servio.repository.VehicleRepository;
import com.servio.repository.ServiceRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;
    private final ServiceRecordRepository serviceRecordRepository;
    private final ProfileRepository profileRepository;

    /**
     * Resolves the Profile for the authenticated principal.
     * The principal may be a UUID (Supabase profile id) or a numeric backend user id.
     * When it's a numeric id, we look up the backend User, then find the Profile by email.
     */
    private Profile resolveProfile(String principalId) {
        // Try UUID first (Supabase profile id)
        try {
            UUID profileId = UUID.fromString(principalId);
            return profileRepository.findById(profileId).orElse(null);
        } catch (IllegalArgumentException ignored) {
            // Not a UUID — try as numeric backend user id
        }

        try {
            Long userId = Long.parseLong(principalId);
            User user = userRepository.findById(userId).orElse(null);
            if (user != null && user.getEmail() != null) {
                return profileRepository.findByEmail(user.getEmail()).orElse(null);
            }
        } catch (NumberFormatException ignored) {
            // Not a valid number either
        }

        return null;
    }

    /**
     * Returns vehicles for the currently authenticated user.
     */
    @Transactional(readOnly = true)
    public List<VehicleDto> getMyVehicles(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return List.of();
        }
        String principalId = authentication.getPrincipal().toString();
        Profile profile = resolveProfile(principalId);
        if (profile == null) {
            return List.of();
        }
        return vehicleRepository.findByProfileId(profile.getId()).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Creates a vehicle for the currently authenticated user.
     */
    @Transactional
    public VehicleDto createMyVehicle(VehicleRequest request, Authentication authentication) {
        String principalId = authentication.getPrincipal().toString();
        Profile profile = resolveProfile(principalId);

        if (profile == null) {
            throw new RuntimeException("Profile not found for authenticated user: " + principalId);
        }

        Vehicle vehicle = Vehicle.builder()
                .profile(profile)
                .make(request.getMake())
                .model(request.getModel())
                .year(request.getYear())
                .licensePlate(request.getLicensePlate())
                .vin(request.getVin())
                .build();

        vehicle = vehicleRepository.save(vehicle);
        return convertToDto(vehicle);
    }

    @Transactional
    public VehicleDto createVehicle(VehicleRequest request) {
        Profile profile = null;
        if (request.getUserId() != null) {
            // Try as UUID profile id first, then as numeric user id
            profile = resolveProfile(String.valueOf(request.getUserId()));
        }

        Vehicle vehicle = Vehicle.builder()
                .profile(profile)
                .make(request.getMake())
                .model(request.getModel())
                .year(request.getYear())
                .licensePlate(request.getLicensePlate())
                .vin(request.getVin())
                .build();

        vehicle = vehicleRepository.save(vehicle);
        return convertToDto(vehicle);
    }

    public List<VehicleDto> getAllVehicles() {
        return vehicleRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<VehicleDto> getVehiclesByUserId(Long userId) {
        // Legacy method — resolve profile from user id, then find vehicles
        User user = userRepository.findById(userId).orElse(null);
        if (user != null && user.getEmail() != null) {
            Profile profile = profileRepository.findByEmail(user.getEmail()).orElse(null);
            if (profile != null) {
                return vehicleRepository.findByProfileId(profile.getId()).stream()
                        .map(this::convertToDto)
                        .collect(Collectors.toList());
            }
        }
        return List.of();
    }

    public VehicleDto getVehicleById(Long id) {
        Vehicle vehicle = vehicleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Vehicle not found with id: " + id));
        return convertToDto(vehicle);
    }

    public List<ServiceRecordDto> getServiceRecordsByVehicle(Long vehicleId) {
        return serviceRecordRepository.findByVehicleId(vehicleId).stream()
                .map(this::convertToRecordDto)
                .collect(Collectors.toList());
    }

    public VehicleStatsDto getVehicleStats(Long vehicleId) {
        Vehicle vehicle = vehicleRepository.findById(vehicleId)
                .orElseThrow(() -> new RuntimeException("Vehicle not found with id: " + vehicleId));

        List<ServiceRecord> records = serviceRecordRepository.findAll().stream()
                .filter(r -> r.getVehicle().getId().equals(vehicleId))
                .collect(Collectors.toList());

        Long totalServices = (long) records.size();

        BigDecimal totalCost = records.stream()
                .filter(r -> r.getCost() != null)
                .map(ServiceRecord::getCost)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Integer lastMileage = records.stream()
                .filter(r -> r.getMileage() != null)
                .map(ServiceRecord::getMileage)
                .max(Integer::compareTo)
                .orElse(null);

        return VehicleStatsDto.builder()
                .vehicleId(vehicleId)
                .vehicleInfo(vehicle.getMake() + " " + vehicle.getModel() + " " + vehicle.getYear())
                .totalServices(totalServices)
                .totalCost(totalCost)
                .lastMileage(lastMileage)
                .build();
    }

    @Transactional
    public VehicleDto updateVehicle(Long id, VehicleRequest request) {
        Vehicle vehicle = vehicleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Vehicle not found with id: " + id));

        if (request.getMake() != null)
            vehicle.setMake(request.getMake());
        if (request.getModel() != null)
            vehicle.setModel(request.getModel());
        if (request.getYear() != null)
            vehicle.setYear(request.getYear());
        if (request.getLicensePlate() != null)
            vehicle.setLicensePlate(request.getLicensePlate());
        if (request.getVin() != null)
            vehicle.setVin(request.getVin());

        vehicle = vehicleRepository.save(vehicle);
        return convertToDto(vehicle);
    }

    @Transactional
    public void deleteVehicle(Long id) {
        if (!vehicleRepository.existsById(id)) {
            throw new RuntimeException("Vehicle not found with id: " + id);
        }
        vehicleRepository.deleteById(id);
    }

    private VehicleDto convertToDto(Vehicle vehicle) {
        return VehicleDto.builder()
                .id(vehicle.getId())
                .profileId(vehicle.getProfile() != null ? vehicle.getProfile().getId().toString() : null)
                .ownerName(vehicle.getProfile() != null ? vehicle.getProfile().getFullName() : null)
                .make(vehicle.getMake())
                .model(vehicle.getModel())
                .year(vehicle.getYear())
                .licensePlate(vehicle.getLicensePlate())
                .vin(vehicle.getVin())
                .createdAt(vehicle.getCreatedAt())
                .updatedAt(vehicle.getUpdatedAt())
                .build();
    }

    private ServiceRecordDto convertToRecordDto(ServiceRecord record) {
        return ServiceRecordDto.builder()
                .id(record.getId())
                .vehicleId(record.getVehicle().getId())
                .vehicleMake(record.getVehicle().getMake())
                .vehicleModel(record.getVehicle().getModel())
                .serviceType(record.getServiceType())
                .description(record.getDescription())
                .serviceDate(record.getServiceDate())
                .mileage(record.getMileage())
                .cost(record.getCost())
                .createdAt(record.getCreatedAt())
                .updatedAt(record.getUpdatedAt())
                .build();
    }
}
