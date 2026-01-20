package com.servio.service;

import com.servio.dto.ServiceRecordDto;
import com.servio.dto.ServiceRecordRequest;
import com.servio.dto.ServiceHistoryDto;
import com.servio.dto.MaintenanceReminderDto;
import com.servio.entity.ServiceRecord;
import com.servio.entity.Vehicle;
import com.servio.repository.ServiceRecordRepository;
import com.servio.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ServiceRecordService {
    
    private final ServiceRecordRepository serviceRecordRepository;
    private final VehicleRepository vehicleRepository;
    
    @Transactional
    public ServiceRecordDto createServiceRecord(ServiceRecordRequest request) {
        Vehicle vehicle = vehicleRepository.findById(request.getVehicleId())
            .orElseThrow(() -> new RuntimeException("Vehicle not found with id: " + request.getVehicleId()));
        
        ServiceRecord record = ServiceRecord.builder()
            .vehicle(vehicle)
            .serviceType(request.getServiceType())
            .description(request.getDescription())
            .serviceDate(request.getServiceDate())
            .mileage(request.getMileage())
            .cost(request.getCost())
            .build();
        
        record = serviceRecordRepository.save(record);
        return convertToDto(record);
    }
    
    public List<ServiceRecordDto> getAllServiceRecords() {
        return serviceRecordRepository.findAll().stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public List<ServiceRecordDto> getServiceRecordsByVehicleId(Long vehicleId) {
        return serviceRecordRepository.findAll().stream()
            .filter(r -> r.getVehicle().getId().equals(vehicleId))
            .sorted((a, b) -> b.getServiceDate().compareTo(a.getServiceDate()))
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public ServiceRecordDto getServiceRecordById(Long id) {
        ServiceRecord record = serviceRecordRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Service record not found with id: " + id));
        return convertToDto(record);
    }
    
    public List<ServiceRecordDto> getRecentServiceRecords(int limit) {
        return serviceRecordRepository.findAll().stream()
            .sorted((a, b) -> b.getServiceDate().compareTo(a.getServiceDate()))
            .limit(limit)
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }
    
    public ServiceHistoryDto getVehicleServiceHistory(Long vehicleId) {
        Vehicle vehicle = vehicleRepository.findById(vehicleId)
            .orElseThrow(() -> new RuntimeException("Vehicle not found with id: " + vehicleId));
        
        List<ServiceRecord> records = serviceRecordRepository.findAll().stream()
            .filter(r -> r.getVehicle().getId().equals(vehicleId))
            .sorted((a, b) -> b.getServiceDate().compareTo(a.getServiceDate()))
            .collect(Collectors.toList());
        
        BigDecimal totalCost = records.stream()
            .filter(r -> r.getCost() != null)
            .map(ServiceRecord::getCost)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        LocalDate lastServiceDate = records.isEmpty() ? null : records.get(0).getServiceDate();
        Integer lastMileage = records.stream()
            .filter(r -> r.getMileage() != null)
            .map(ServiceRecord::getMileage)
            .max(Integer::compareTo)
            .orElse(null);
        
        return ServiceHistoryDto.builder()
            .vehicleId(vehicleId)
            .vehicleInfo(vehicle.getMake() + " " + vehicle.getModel())
            .totalServices((long) records.size())
            .totalCost(totalCost)
            .lastServiceDate(lastServiceDate)
            .lastMileage(lastMileage)
            .serviceRecords(records.stream().map(this::convertToDto).collect(Collectors.toList()))
            .build();
    }
    
    public List<MaintenanceReminderDto> getMaintenanceReminders(Long vehicleId) {
        List<MaintenanceReminderDto> reminders = new ArrayList<>();
        
        List<ServiceRecord> records = serviceRecordRepository.findAll().stream()
            .filter(r -> r.getVehicle().getId().equals(vehicleId))
            .sorted((a, b) -> b.getServiceDate().compareTo(a.getServiceDate()))
            .collect(Collectors.toList());
        
        if (!records.isEmpty()) {
            ServiceRecord lastService = records.get(0);
            
            // Check if oil change is due (every 5000 miles or 6 months)
            if (lastService.getServiceType().toLowerCase().contains("oil")) {
                long monthsSinceService = ChronoUnit.MONTHS.between(lastService.getServiceDate(), LocalDate.now());
                if (monthsSinceService >= 6) {
                    reminders.add(MaintenanceReminderDto.builder()
                        .serviceType("Oil Change")
                        .description("Oil change due - last service was " + monthsSinceService + " months ago")
                        .dueDate(lastService.getServiceDate().plusMonths(6))
                        .priority("MEDIUM")
                        .build());
                }
            }
            
            // Check for general service (every 12 months)
            long monthsSinceLastService = ChronoUnit.MONTHS.between(lastService.getServiceDate(), LocalDate.now());
            if (monthsSinceLastService >= 12) {
                reminders.add(MaintenanceReminderDto.builder()
                    .serviceType("Annual Service")
                    .description("Annual service due")
                    .dueDate(lastService.getServiceDate().plusYears(1))
                    .priority("HIGH")
                    .build());
            }
        } else {
            // No service history - recommend initial inspection
            reminders.add(MaintenanceReminderDto.builder()
                .serviceType("Initial Inspection")
                .description("No service history found - schedule an inspection")
                .dueDate(LocalDate.now())
                .priority("HIGH")
                .build());
        }
        
        return reminders;
    }
    
    @Transactional
    public ServiceRecordDto updateServiceRecord(Long id, ServiceRecordRequest request) {
        ServiceRecord record = serviceRecordRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Service record not found with id: " + id));
        
        if (request.getServiceType() != null) record.setServiceType(request.getServiceType());
        if (request.getDescription() != null) record.setDescription(request.getDescription());
        if (request.getServiceDate() != null) record.setServiceDate(request.getServiceDate());
        if (request.getMileage() != null) record.setMileage(request.getMileage());
        if (request.getCost() != null) record.setCost(request.getCost());
        
        record = serviceRecordRepository.save(record);
        return convertToDto(record);
    }
    
    @Transactional
    public void deleteServiceRecord(Long id) {
        if (!serviceRecordRepository.existsById(id)) {
            throw new RuntimeException("Service record not found with id: " + id);
        }
        serviceRecordRepository.deleteById(id);
    }
    
    private ServiceRecordDto convertToDto(ServiceRecord record) {
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
