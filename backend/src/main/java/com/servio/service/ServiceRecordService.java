package com.servio.service;

import com.servio.dto.ServiceRecordDto;
import com.servio.dto.ServiceRecordRequest;
import com.servio.entity.ServiceRecord;
import com.servio.entity.Vehicle;
import com.servio.repository.ServiceRecordRepository;
import com.servio.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

        ServiceRecord saved = serviceRecordRepository.save(record);
        return toDto(saved);
    }

    public List<ServiceRecordDto> getServiceRecordsByVehicle(Long vehicleId) {
        return serviceRecordRepository.findByVehicleId(vehicleId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ServiceRecordDto updateServiceRecord(Long id, ServiceRecordRequest request) {
        ServiceRecord record = serviceRecordRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service record not found with id: " + id));

        if (request.getServiceType() != null) {
            record.setServiceType(request.getServiceType());
        }
        if (request.getDescription() != null) {
            record.setDescription(request.getDescription());
        }
        if (request.getServiceDate() != null) {
            record.setServiceDate(request.getServiceDate());
        }
        if (request.getMileage() != null) {
            record.setMileage(request.getMileage());
        }
        if (request.getCost() != null) {
            record.setCost(request.getCost());
        }

        ServiceRecord updated = serviceRecordRepository.save(record);
        return toDto(updated);
    }

    @Transactional
    public void deleteServiceRecord(Long id) {
        if (!serviceRecordRepository.existsById(id)) {
            throw new RuntimeException("Service record not found with id: " + id);
        }
        serviceRecordRepository.deleteById(id);
    }

    private ServiceRecordDto toDto(ServiceRecord record) {
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
