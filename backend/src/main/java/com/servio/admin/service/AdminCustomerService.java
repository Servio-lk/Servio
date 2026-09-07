package com.servio.admin.service;


import com.servio.admin.dto.AdminCustomerDetailsDto;
import com.servio.admin.dto.AdminCustomerUserDto;
import com.servio.booking.dto.CustomerVehicleHistoryDto;
import com.servio.booking.dto.ServiceRecordDto;
import com.servio.booking.dto.VehicleDto;
import com.servio.auth.entity.Profile;
import com.servio.auth.entity.Role;
import com.servio.booking.entity.ServiceRecord;
import com.servio.auth.entity.User;
import com.servio.booking.entity.Vehicle;
import com.servio.auth.repository.ProfileRepository;
import com.servio.booking.repository.ServiceRecordRepository;
import com.servio.auth.repository.UserRepository;
import com.servio.booking.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminCustomerService {

    private final ProfileRepository profileRepository;
    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;
    private final ServiceRecordRepository serviceRecordRepository;

    public List<Profile> getAllCustomers() {
        List<Profile> profiles = profileRepository.findAll();

        // Also include users from the local users table not already represented in profiles.
        // This handles local Docker dev where Supabase auth triggers don't populate the profiles table.
        Set<String> profileEmails = profiles.stream()
                .filter(p -> p.getEmail() != null)
                .map(Profile::getEmail)
                .collect(Collectors.toSet());

        List<Profile> usersAsProfiles = userRepository.findAll().stream()
                .filter(u -> u.getRole() != Role.ADMIN)
                .filter(u -> u.getEmail() != null && !profileEmails.contains(u.getEmail()))
                .map(u -> Profile.builder()
                        .id(u.getId())
                        .fullName(u.getFullName())
                        .email(u.getEmail())
                        .phone(u.getPhone())
                        .role(u.getRole().name())
                        .createdAt(u.getCreatedAt() != null
                                ? u.getCreatedAt().atOffset(ZoneOffset.UTC) : null)
                        .joined(u.getCreatedAt() != null
                                ? u.getCreatedAt().atOffset(ZoneOffset.UTC) : null)
                        .build())
                .collect(Collectors.toList());

        List<Profile> combined = new ArrayList<>(profiles);
        combined.addAll(usersAsProfiles);
        return combined;
    }

    public Profile getCustomerById(String id) {
        UUID uuid = UUID.fromString(id);
        return profileRepository.findById(uuid)
                .or(() -> userRepository.findById(uuid).map(u -> Profile.builder()
                        .id(u.getId())
                        .fullName(u.getFullName())
                        .email(u.getEmail())
                        .phone(u.getPhone())
                        .role(u.getRole().name())
                        .createdAt(u.getCreatedAt() != null ? u.getCreatedAt().atOffset(ZoneOffset.UTC) : null)
                        .joined(u.getCreatedAt() != null ? u.getCreatedAt().atOffset(ZoneOffset.UTC) : null)
                        .build()))
                .orElseThrow(() -> new com.servio.common.exception.ResourceNotFoundException("Customer not found with id: " + id));
    }

    public List<Profile> searchCustomers(String query) {
        return profileRepository.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(query, query);
    }

    public AdminCustomerDetailsDto getCustomerDetails(String id) {
        UUID uuid;
        try {
            uuid = UUID.fromString(id);
        } catch (IllegalArgumentException e) {
            throw new com.servio.common.exception.ResourceNotFoundException("Invalid customer ID format: " + id);
        }

        // First check userRepository directly
        User user = userRepository.findById(uuid).orElse(null);
        if (user != null) {
            return buildDetailsFromUser(user);
        }

        // Otherwise check profileRepository
        Profile profile = profileRepository.findById(uuid)
                .orElseThrow(() -> new com.servio.common.exception.ResourceNotFoundException("Customer not found with id: " + id));

        if (profile.getEmail() != null && !profile.getEmail().isBlank()) {
            user = userRepository.findByEmail(profile.getEmail()).orElse(null);
        }

        AdminCustomerUserDto userDto = user == null ? null
                : AdminCustomerUserDto.builder()
                        .id(user.getId())
                        .fullName(user.getFullName())
                        .email(user.getEmail())
                        .phone(user.getPhone())
                        .role(user.getRole().name())
                        .createdAt(user.getCreatedAt())
                        .build();

        List<CustomerVehicleHistoryDto> vehicles = vehicleRepository.findByUserId(profile.getId()).stream()
                .map(vehicle -> CustomerVehicleHistoryDto.builder()
                        .vehicle(toVehicleDto(vehicle))
                        .serviceRecords(serviceRecordRepository.findByVehicleId(vehicle.getId()).stream()
                                .map(this::toServiceRecordDto)
                                .collect(Collectors.toList()))
                        .build())
                .collect(Collectors.toList());

        return AdminCustomerDetailsDto.builder()
                .profile(profile)
                .user(userDto)
                .vehicles(vehicles)
                .build();
    }

    private AdminCustomerDetailsDto buildDetailsFromUser(User user) {
        Profile profile = Profile.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .createdAt(user.getCreatedAt() != null
                        ? user.getCreatedAt().atOffset(ZoneOffset.UTC) : null)
                .joined(user.getCreatedAt() != null
                        ? user.getCreatedAt().atOffset(ZoneOffset.UTC) : null)
                .build();

        AdminCustomerUserDto userDto = AdminCustomerUserDto.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .createdAt(user.getCreatedAt())
                .build();

        List<CustomerVehicleHistoryDto> vehicles = vehicleRepository.findByUserId(user.getId()).stream()
                .map(vehicle -> CustomerVehicleHistoryDto.builder()
                        .vehicle(toVehicleDto(vehicle))
                        .serviceRecords(serviceRecordRepository.findByVehicleId(vehicle.getId()).stream()
                                .map(this::toServiceRecordDto)
                                .collect(Collectors.toList()))
                        .build())
                .collect(Collectors.toList());

        return AdminCustomerDetailsDto.builder()
                .profile(profile)
                .user(userDto)
                .vehicles(vehicles)
                .build();
    }

    private VehicleDto toVehicleDto(Vehicle vehicle) {
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

    private ServiceRecordDto toServiceRecordDto(ServiceRecord record) {
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
