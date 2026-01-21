package com.servio.service;

import com.servio.dto.VehicleDto;
import com.servio.dto.VehicleRequest;
import com.servio.dto.VehicleStatsDto;
import com.servio.entity.User;
import com.servio.entity.Vehicle;
import com.servio.entity.ServiceRecord;
import com.servio.repository.UserRepository;
import com.servio.repository.VehicleRepository;
import com.servio.repository.ServiceRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class VehicleService {
    
    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;
    private final ServiceRecordRepository serviceRecordRepository;
    
    @Transactional
    public VehicleDto createVehicle(VehicleRequest request) {
        User user = userRepository.findById(request.getUserId())
            .orElseThrow(() -> new RuntimeException("User not found with id: " + request.getUserId()));
        
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
    
    public List<VehicleDto> getVehiclesByUserId(Long userId) {
        return vehicleRepository.findAll().stream()
            .filter(v -> v.getUser().getId().equals(userId))
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public VehicleDto getVehicleById(Long id) {
        Vehicle vehicle = vehicleRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Vehicle not found with id: " + id));
        return convertToDto(vehicle);
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
        
        if (request.getMake() != null) vehicle.setMake(request.getMake());
        if (request.getModel() != null) vehicle.setModel(request.getModel());
        if (request.getYear() != null) vehicle.setYear(request.getYear());
        if (request.getLicensePlate() != null) vehicle.setLicensePlate(request.getLicensePlate());
        if (request.getVin() != null) vehicle.setVin(request.getVin());
        
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
}
