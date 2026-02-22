package com.servio.service;

import com.servio.dto.AdminCustomerDetailsDto;
import com.servio.dto.AdminCustomerUserDto;
import com.servio.dto.CustomerVehicleHistoryDto;
import com.servio.dto.ServiceRecordDto;
import com.servio.dto.VehicleDto;
import com.servio.entity.Profile;
import com.servio.entity.ServiceRecord;
import com.servio.entity.User;
import com.servio.entity.Vehicle;
import com.servio.repository.ProfileRepository;
import com.servio.repository.ServiceRecordRepository;
import com.servio.repository.UserRepository;
import com.servio.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
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
        return profileRepository.findAll();
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
