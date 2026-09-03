package com.servio.booking.service;


import com.servio.booking.dto.ServiceRecordDto;
import com.servio.booking.dto.VehicleDto;
import com.servio.booking.dto.VehicleRequest;
import com.servio.booking.dto.VehicleStatsDto;
import com.servio.auth.entity.Profile;
import com.servio.auth.entity.User;
import com.servio.booking.entity.Vehicle;
import com.servio.booking.entity.ServiceRecord;
import com.servio.auth.repository.ProfileRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.repository.VehicleRepository;
import com.servio.booking.repository.ServiceRecordRepository;
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

    @Transactional(readOnly = true)
    public List<VehicleDto> getMyVehicles(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return List.of();
        }
        String principalId = authentication.getPrincipal().toString();
        try {
            UUID userId = UUID.fromString(principalId);
            return vehicleRepository.findByUserId(userId).stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
        } catch (IllegalArgumentException e) {
            return List.of();
        }
    }

    /**
     * Creates a vehicle for the currently authenticated user.
     */
    @Transactional
    public VehicleDto createMyVehicle(VehicleRequest request, Authentication authentication) {
        String principalId = authentication.getPrincipal().toString();
        UUID userId;
        try {
            userId = UUID.fromString(principalId);
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid user ID format: " + principalId);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found for authenticated ID: " + userId));

        Vehicle vehicle = Vehicle.builder()
                .user(user)
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
        User user = null;
        if (request.getUserId() != null) {
            user = userRepository.findById(request.getUserId()).orElse(null);
        }

        Vehicle vehicle = Vehicle.builder()
                .user(user)
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

    public List<VehicleDto> getVehiclesByUserId(UUID userId) {
        return vehicleRepository.findByUserId(userId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
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
                .userId(vehicle.getUser() != null ? vehicle.getUser().getId() : null)
                .profileId(vehicle.getUser() != null ? vehicle.getUser().getId().toString() : null)
                .ownerName(vehicle.getUser() != null ? vehicle.getUser().getFullName() : null)
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
