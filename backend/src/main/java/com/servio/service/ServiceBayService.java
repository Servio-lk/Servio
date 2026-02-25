package com.servio.service;

import com.servio.dto.ServiceBayDto;
import com.servio.entity.ServiceBay;
import com.servio.entity.ServiceBayStatus;
import com.servio.entity.ServiceBayType;
import com.servio.repository.ServiceBayRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ServiceBayService {
    private final ServiceBayRepository serviceBayRepository;

    public ServiceBayDto createServiceBay(ServiceBayDto dto) {
        ServiceBay bay = ServiceBay.builder()
                .bayNumber(dto.getBayNumber())
                .description(dto.getDescription())
                .type(ServiceBayType.valueOf(dto.getType() != null ? dto.getType() : "GENERAL"))
                .status(ServiceBayStatus.AVAILABLE)
                .capacity(dto.getCapacity() != null ? dto.getCapacity() : 1)
                .isActive(true)
                .build();

        ServiceBay saved = serviceBayRepository.save(bay);
        return convertToDto(saved);
    }

    public ServiceBayDto getServiceBayById(Long id) {
        ServiceBay bay = serviceBayRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service bay not found"));
        return convertToDto(bay);
    }

    public List<ServiceBayDto> getAllServiceBays() {
        return serviceBayRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<ServiceBayDto> getAvailableBays() {
        return serviceBayRepository.findByStatus(ServiceBayStatus.AVAILABLE).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public ServiceBayDto updateServiceBay(Long id, ServiceBayDto dto) {
        ServiceBay bay = serviceBayRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service bay not found"));

        bay.setBayNumber(dto.getBayNumber());
        bay.setDescription(dto.getDescription());
        if (dto.getType() != null) {
            bay.setType(ServiceBayType.valueOf(dto.getType()));
        }
        if (dto.getStatus() != null) {
            bay.setStatus(ServiceBayStatus.valueOf(dto.getStatus()));
        }
        if (dto.getCapacity() != null) {
            bay.setCapacity(dto.getCapacity());
        }
        if (dto.getIsActive() != null) {
            bay.setIsActive(dto.getIsActive());
        }

        ServiceBay updated = serviceBayRepository.save(bay);
        return convertToDto(updated);
    }

    public void deleteServiceBay(Long id) {
        serviceBayRepository.deleteById(id);
    }

    public void updateServiceBayStatus(Long id, String status) {
        ServiceBay bay = serviceBayRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service bay not found"));
        bay.setStatus(ServiceBayStatus.valueOf(status));
        serviceBayRepository.save(bay);
    }

    private ServiceBayDto convertToDto(ServiceBay bay) {
        return ServiceBayDto.builder()
                .id(bay.getId())
                .bayNumber(bay.getBayNumber())
                .description(bay.getDescription())
                .type(bay.getType().toString())
                .status(bay.getStatus().toString())
                .capacity(bay.getCapacity())
                .isActive(bay.getIsActive())
                .createdAt(bay.getCreatedAt())
                .updatedAt(bay.getUpdatedAt())
                .build();
    }
}
