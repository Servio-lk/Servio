package com.servio.service;

import com.servio.dto.MechanicDto;
import com.servio.entity.Mechanic;
import com.servio.entity.MechanicStatus;
import com.servio.repository.MechanicRepository;
import com.servio.repository.RepairJobRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MechanicService {
    private final MechanicRepository mechanicRepository;
    private final RepairJobRepository repairJobRepository;

    public MechanicDto createMechanic(MechanicDto dto) {
        Mechanic mechanic = Mechanic.builder()
                .fullName(dto.getFullName())
                .email(dto.getEmail())
                .phone(dto.getPhone())
                .specialization(dto.getSpecialization())
                .experienceYears(dto.getExperienceYears())
                .status(dto.getStatus() == null ? MechanicStatus.AVAILABLE : MechanicStatus.valueOf(dto.getStatus()))
                .isActive(true)
                .build();

        Mechanic saved = mechanicRepository.save(mechanic);
        return convertToDto(saved);
    }

    public MechanicDto getMechanicById(Long id) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Mechanic not found"));
        return convertToDto(mechanic);
    }

    public List<MechanicDto> getAllMechanics() {
        return mechanicRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<MechanicDto> getMechanicsByStatus(String status) {
        try {
            MechanicStatus mechanicStatus = MechanicStatus.valueOf(status);
            return mechanicRepository.findByStatus(mechanicStatus).stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + status);
        }
    }

    public List<MechanicDto> getAvailableMechanics() {
        return mechanicRepository.findByStatus(MechanicStatus.AVAILABLE).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public MechanicDto updateMechanic(Long id, MechanicDto dto) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Mechanic not found"));

        if (dto.getFullName() != null) {
            mechanic.setFullName(dto.getFullName());
        }
        if (dto.getEmail() != null) {
            mechanic.setEmail(dto.getEmail());
        }
        if (dto.getPhone() != null) {
            mechanic.setPhone(dto.getPhone());
        }
        if (dto.getSpecialization() != null) {
            mechanic.setSpecialization(dto.getSpecialization());
        }
        if (dto.getExperienceYears() != null) {
            mechanic.setExperienceYears(dto.getExperienceYears());
        }
        if (dto.getStatus() != null) {
            mechanic.setStatus(MechanicStatus.valueOf(dto.getStatus()));
        }
        if (dto.getIsActive() != null) {
            mechanic.setIsActive(dto.getIsActive());
        }

        Mechanic updated = mechanicRepository.save(mechanic);
        return convertToDto(updated);
    }

    public void deleteMechanic(Long id) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Mechanic not found"));
        mechanic.setIsActive(false);
        mechanicRepository.save(mechanic);
    }

    public void updateMechanicStatus(Long id, String status) {
        Mechanic mechanic = mechanicRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Mechanic not found"));
        mechanic.setStatus(MechanicStatus.valueOf(status));
        mechanicRepository.save(mechanic);
    }

    private MechanicDto convertToDto(Mechanic mechanic) {
        return MechanicDto.builder()
                .id(mechanic.getId())
                .fullName(mechanic.getFullName())
                .email(mechanic.getEmail())
                .phone(mechanic.getPhone())
                .specialization(mechanic.getSpecialization())
                .experienceYears(mechanic.getExperienceYears())
                .status(mechanic.getStatus().toString())
                .isActive(mechanic.getIsActive())
                .activeJobCount(repairJobRepository.countByAssignedTechnicianIdAndStatusNotIn(
                        mechanic.getId(),
                        List.of("COMPLETED", "CANCELLED")
                ))
                .createdAt(mechanic.getCreatedAt())
                .updatedAt(mechanic.getUpdatedAt())
                .build();
    }
}
