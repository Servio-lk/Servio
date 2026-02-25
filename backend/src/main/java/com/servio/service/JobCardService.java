package com.servio.service;

import com.servio.dto.JobCardDto;
import com.servio.entity.*;
import com.servio.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class JobCardService {
    private final JobCardRepository jobCardRepository;
    private final AppointmentRepository appointmentRepository;
    private final MechanicRepository mechanicRepository;
    private final ServiceBayRepository serviceBayRepository;
    private final WalkInCustomerRepository walkInCustomerRepository;

    public JobCardDto createJobCard(JobCardDto dto) {
        Appointment appointment = null;
        if (dto.getAppointmentId() != null) {
            appointment = appointmentRepository.findById(dto.getAppointmentId())
                    .orElseThrow(() -> new RuntimeException("Appointment not found"));
        }

        Mechanic mechanic = null;
        if (dto.getMechanicId() != null) {
            mechanic = mechanicRepository.findById(dto.getMechanicId())
                    .orElseThrow(() -> new RuntimeException("Mechanic not found"));
        }

        ServiceBay bay = null;
        if (dto.getServiceBayId() != null) {
            bay = serviceBayRepository.findById(dto.getServiceBayId())
                    .orElseThrow(() -> new RuntimeException("Service bay not found"));
        }

        WalkInCustomer walkIn = null;
        if (dto.getWalkInCustomerId() != null) {
            walkIn = walkInCustomerRepository.findById(dto.getWalkInCustomerId())
                    .orElseThrow(() -> new RuntimeException("Walk-in customer not found"));
        }

        JobCard jobCard = JobCard.builder()
                .appointment(appointment)
                .assignedMechanic(mechanic)
                .assignedBay(bay)
                .walkInCustomer(walkIn)
                .serviceType(dto.getServiceType())
                .description(dto.getDescription())
                .status(JobCardStatus.NEW)
                .priority(JobPriority.valueOf(dto.getPriority() != null ? dto.getPriority() : "NORMAL"))
                .estimatedHours(dto.getEstimatedHours())
                .estimatedCost(dto.getEstimatedCost())
                .build();

        JobCard saved = jobCardRepository.save(jobCard);
        return convertToDto(saved);
    }

    public JobCardDto getJobCardById(Long id) {
        JobCard jobCard = jobCardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Job card not found"));
        return convertToDto(jobCard);
    }

    public List<JobCardDto> getAllJobCards() {
        return jobCardRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<JobCardDto> getJobCardsByStatus(String status) {
        JobCardStatus jobCardStatus = JobCardStatus.valueOf(status);
        return jobCardRepository.findByStatus(jobCardStatus).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<JobCardDto> getJobCardsByAppointment(Long appointmentId) {
        return jobCardRepository.findByAppointmentId(appointmentId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<JobCardDto> getJobCardsByMechanic(Long mechanicId) {
        return jobCardRepository.findByAssignedMechanicId(mechanicId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public JobCardDto updateJobCard(Long id, JobCardDto dto) {
        JobCard jobCard = jobCardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Job card not found"));

        if (dto.getMechanicId() != null && !dto.getMechanicId()
                .equals(jobCard.getAssignedMechanic() != null ? jobCard.getAssignedMechanic().getId() : null)) {
            Mechanic mechanic = mechanicRepository.findById(dto.getMechanicId())
                    .orElseThrow(() -> new RuntimeException("Mechanic not found"));
            jobCard.setAssignedMechanic(mechanic);
        }

        if (dto.getServiceBayId() != null && !dto.getServiceBayId()
                .equals(jobCard.getAssignedBay() != null ? jobCard.getAssignedBay().getId() : null)) {
            ServiceBay bay = serviceBayRepository.findById(dto.getServiceBayId())
                    .orElseThrow(() -> new RuntimeException("Service bay not found"));
            jobCard.setAssignedBay(bay);
        }

        if (dto.getServiceType() != null) {
            jobCard.setServiceType(dto.getServiceType());
        }
        if (dto.getDescription() != null) {
            jobCard.setDescription(dto.getDescription());
        }
        if (dto.getPriority() != null) {
            jobCard.setPriority(JobPriority.valueOf(dto.getPriority()));
        }
        if (dto.getEstimatedHours() != null) {
            jobCard.setEstimatedHours(dto.getEstimatedHours());
        }
        if (dto.getEstimatedCost() != null) {
            jobCard.setEstimatedCost(dto.getEstimatedCost());
        }

        JobCard updated = jobCardRepository.save(jobCard);
        return convertToDto(updated);
    }

    public JobCardDto updateJobCardStatus(Long id, String status) {
        JobCard jobCard = jobCardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Job card not found"));

        JobCardStatus newStatus = JobCardStatus.valueOf(status);
        jobCard.setStatus(newStatus);

        if (newStatus == JobCardStatus.IN_PROGRESS && jobCard.getStartedAt() == null) {
            jobCard.setStartedAt(LocalDateTime.now());
        } else if (newStatus == JobCardStatus.COMPLETED && jobCard.getCompletedAt() == null) {
            jobCard.setCompletedAt(LocalDateTime.now());
        }

        JobCard updated = jobCardRepository.save(jobCard);
        return convertToDto(updated);
    }

    public void deleteJobCard(Long id) {
        jobCardRepository.deleteById(id);
    }

    private JobCardDto convertToDto(JobCard jobCard) {
        return JobCardDto.builder()
                .id(jobCard.getId())
                .appointmentId(jobCard.getAppointment() != null ? jobCard.getAppointment().getId() : null)
                .mechanicId(jobCard.getAssignedMechanic() != null ? jobCard.getAssignedMechanic().getId() : null)
                .mechanicName(
                        jobCard.getAssignedMechanic() != null ? jobCard.getAssignedMechanic().getFullName() : null)
                .serviceBayId(jobCard.getAssignedBay() != null ? jobCard.getAssignedBay().getId() : null)
                .bayNumber(jobCard.getAssignedBay() != null ? jobCard.getAssignedBay().getBayNumber() : null)
                .walkInCustomerId(jobCard.getWalkInCustomer() != null ? jobCard.getWalkInCustomer().getId() : null)
                .customerName(jobCard.getWalkInCustomer() != null ? jobCard.getWalkInCustomer().getFullName() : null)
                .jobNumber(jobCard.getJobNumber())
                .serviceType(jobCard.getServiceType())
                .description(jobCard.getDescription())
                .status(jobCard.getStatus().toString())
                .priority(jobCard.getPriority().toString())
                .estimatedHours(jobCard.getEstimatedHours())
                .actualHours(jobCard.getActualHours())
                .estimatedCost(jobCard.getEstimatedCost())
                .actualCost(jobCard.getActualCost())
                .startedAt(jobCard.getStartedAt())
                .completedAt(jobCard.getCompletedAt())
                .createdAt(jobCard.getCreatedAt())
                .updatedAt(jobCard.getUpdatedAt())
                .build();
    }
}
