package com.servio.service;

import com.servio.dto.AdminCustomerDetailsDto;
import com.servio.dto.AdminCustomerUserDto;
import com.servio.dto.CustomerVehicleHistoryDto;
import com.servio.dto.ServiceRecordDto;
import com.servio.dto.VehicleDto;
import com.servio.entity.Profile;
import com.servio.entity.Role;
import com.servio.entity.ServiceRecord;
import com.servio.entity.User;
import com.servio.entity.Vehicle;
import com.servio.repository.ProfileRepository;
import com.servio.repository.ServiceRecordRepository;
import com.servio.repository.UserRepository;
import com.servio.repository.VehicleRepository;
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
                        // Use a deterministic UUID derived from the user's numeric ID so
                        // the details endpoint can identify it as a local-user record.
                        .id(new UUID(0L, u.getId()))
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
                .orElseThrow(() -> new RuntimeException("Customer not found with id: " + id));
    }

    public List<Profile> searchCustomers(String query) {
        return profileRepository.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(query, query);
    }

    public AdminCustomerDetailsDto getCustomerDetails(String id) {
        // Check if this is a synthetic UUID created from a local User numeric ID
        // (getMostSignificantBits() == 0 is our marker)
        try {
            UUID uuid = UUID.fromString(id);
            if (uuid.getMostSignificantBits() == 0L) {
                long userId = uuid.getLeastSignificantBits();
                User localUser = userRepository.findById(userId)
                        .orElseThrow(() -> new RuntimeException("Customer not found: " + id));
                return buildDetailsFromUser(localUser);
            }
        } catch (IllegalArgumentException ignored) {
            // Not a UUID — fall through
        }

        Profile profile = getCustomerById(id);

        User user = null;
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

        List<CustomerVehicleHistoryDto> vehicles = user == null ? List.of()
                : vehicleRepository.findByUserId(user.getId()).stream()
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
        Profile syntheticProfile = Profile.builder()
                .id(new UUID(0L, user.getId()))
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
                .profile(syntheticProfile)
                .user(userDto)
                .vehicles(vehicles)
                .build();
    }

    private VehicleDto toVehicleDto(Vehicle vehicle) {
        return VehicleDto.builder()
                .id(vehicle.getId())
                .userId(vehicle.getUser().getId())
                .userName(vehicle.getUser().getFullName())
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
