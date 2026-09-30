package com.servio.inventory.service;

import com.servio.admin.dto.PartRequestDto;
import com.servio.admin.entity.Mechanic;
import com.servio.admin.repository.MechanicRepository;
import com.servio.booking.entity.Appointment;
import com.servio.booking.entity.Vehicle;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.common.exception.ResourceNotFoundException;
import com.servio.inventory.entity.PartRequest;
import com.servio.inventory.repository.PartRequestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class PartRequestService {

    private final PartRequestRepository partRequestRepository;
    private final MechanicRepository mechanicRepository;
    private final AppointmentRepository appointmentRepository;

    public PartRequestDto createRequest(PartRequestDto dto, Authentication authentication) {
        Mechanic mechanic = null;
        if (dto.getMechanicId() != null) {
            mechanic = mechanicRepository.findById(dto.getMechanicId()).orElse(null);
        }

        if (mechanic == null && authentication != null && authentication.getName() != null) {
            mechanic = mechanicRepository.findByEmailIgnoreCase(authentication.getName()).orElse(null);
        }

        Appointment appointment = null;
        if (dto.getAppointmentId() != null) {
            appointment = appointmentRepository.findById(dto.getAppointmentId()).orElse(null);
        }

        PartRequest partRequest = PartRequest.builder()
                .mechanic(mechanic)
                .appointment(appointment)
                .partName(dto.getPartName())
                .partNumber(dto.getPartNumber())
                .quantity(dto.getQuantity() != null ? dto.getQuantity() : BigDecimal.ONE)
                .unit(dto.getUnit() != null ? dto.getUnit() : "units")
                .urgency(dto.getUrgency() != null ? dto.getUrgency() : "STANDARD")
                .notes(dto.getNotes())
                .status(dto.getStatus() != null ? dto.getStatus() : "PENDING")
                .build();

        PartRequest saved = partRequestRepository.save(partRequest);
        return convertToDto(saved);
    }

    @Transactional(readOnly = true)
    public List<PartRequestDto> getAllRequests() {
        return partRequestRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PartRequestDto> getRequestsByAppointment(Long appointmentId) {
        return partRequestRepository.findByAppointmentIdOrderByCreatedAtDesc(appointmentId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PartRequestDto getRequestById(Long id) {
        PartRequest partRequest = partRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Part request not found with id: " + id));
        return convertToDto(partRequest);
    }

    public PartRequestDto updateStatus(Long id, String status) {
        PartRequest partRequest = partRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Part request not found with id: " + id));

        partRequest.setStatus(status.toUpperCase());
        PartRequest updated = partRequestRepository.save(partRequest);
        return convertToDto(updated);
    }

    private PartRequestDto convertToDto(PartRequest entity) {
        String vehicleDisplay = null;
        if (entity.getAppointment() != null && entity.getAppointment().getVehicle() != null) {
            Vehicle v = entity.getAppointment().getVehicle();
            StringBuilder sb = new StringBuilder();
            if (v.getYear() != null) sb.append(v.getYear()).append(" ");
            if (v.getMake() != null) sb.append(v.getMake()).append(" ");
            if (v.getModel() != null) sb.append(v.getModel());
            vehicleDisplay = sb.toString().trim();
            if (vehicleDisplay.isEmpty()) vehicleDisplay = null;
        }

        return PartRequestDto.builder()
                .id(entity.getId())
                .mechanicId(entity.getMechanic() != null ? entity.getMechanic().getId() : null)
                .mechanicName(entity.getMechanic() != null ? entity.getMechanic().getFullName() : null)
                .appointmentId(entity.getAppointment() != null ? entity.getAppointment().getId() : null)
                .vehicleDisplay(vehicleDisplay)
                .partName(entity.getPartName())
                .partNumber(entity.getPartNumber())
                .quantity(entity.getQuantity())
                .unit(entity.getUnit())
                .urgency(entity.getUrgency())
                .notes(entity.getNotes())
                .status(entity.getStatus())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
