package com.servio.service;

import com.servio.dto.WalkInCustomerDto;
import com.servio.entity.WalkInCustomer;
import com.servio.repository.WalkInCustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WalkInCustomerService {
    private final WalkInCustomerRepository walkInCustomerRepository;

    public WalkInCustomerDto createWalkInCustomer(WalkInCustomerDto dto) {
        WalkInCustomer customer = WalkInCustomer.builder()
                .fullName(dto.getFullName())
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .vehicleMake(dto.getVehicleMake())
                .vehicleModel(dto.getVehicleModel())
                .vehicleYear(dto.getVehicleYear())
                .licensePlate(dto.getLicensePlate())
                .notes(dto.getNotes())
                .isRegistered(false)
                .build();

        WalkInCustomer saved = walkInCustomerRepository.save(customer);
        return convertToDto(saved);
    }

    public WalkInCustomerDto getWalkInCustomerById(Long id) {
        WalkInCustomer customer = walkInCustomerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Walk-in customer not found"));
        return convertToDto(customer);
    }

    public List<WalkInCustomerDto> getAllWalkInCustomers() {
        return walkInCustomerRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<WalkInCustomerDto> getUnregisteredCustomers() {
        return walkInCustomerRepository.findByIsRegisteredFalse().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public WalkInCustomerDto updateWalkInCustomer(Long id, WalkInCustomerDto dto) {
        WalkInCustomer customer = walkInCustomerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Walk-in customer not found"));

        customer.setFullName(dto.getFullName());
        customer.setPhone(dto.getPhone());
        if (dto.getEmail() != null) {
            customer.setEmail(dto.getEmail());
        }
        customer.setVehicleMake(dto.getVehicleMake());
        customer.setVehicleModel(dto.getVehicleModel());
        customer.setVehicleYear(dto.getVehicleYear());
        customer.setLicensePlate(dto.getLicensePlate());
        customer.setNotes(dto.getNotes());

        WalkInCustomer updated = walkInCustomerRepository.save(customer);
        return convertToDto(updated);
    }

    public void deleteWalkInCustomer(Long id) {
        walkInCustomerRepository.deleteById(id);
    }

    public void markAsRegistered(Long id, Long userId) {
        WalkInCustomer customer = walkInCustomerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Walk-in customer not found"));
        customer.setIsRegistered(true);
        customer.setRegisteredUserId(userId);
        walkInCustomerRepository.save(customer);
    }

    private WalkInCustomerDto convertToDto(WalkInCustomer customer) {
        return WalkInCustomerDto.builder()
                .id(customer.getId())
                .fullName(customer.getFullName())
                .phone(customer.getPhone())
                .email(customer.getEmail())
                .vehicleMake(customer.getVehicleMake())
                .vehicleModel(customer.getVehicleModel())
                .vehicleYear(customer.getVehicleYear())
                .licensePlate(customer.getLicensePlate())
                .notes(customer.getNotes())
                .isRegistered(customer.getIsRegistered())
                .registeredUserId(customer.getRegisteredUserId())
                .createdAt(customer.getCreatedAt())
                .updatedAt(customer.getUpdatedAt())
                .build();
    }
}
