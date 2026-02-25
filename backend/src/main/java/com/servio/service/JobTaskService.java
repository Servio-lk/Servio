package com.servio.service;

import com.servio.dto.JobTaskDto;
import com.servio.entity.*;
import com.servio.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class JobTaskService {
    private final JobTaskRepository jobTaskRepository;
    private final JobCardRepository jobCardRepository;
    private final MechanicRepository mechanicRepository;

    public JobTaskDto createJobTask(JobTaskDto dto) {
        JobCard jobCard = jobCardRepository.findById(dto.getJobCardId())
                .orElseThrow(() -> new RuntimeException("Job card not found"));

        Mechanic mechanic = null;
        if (dto.getMechanicId() != null) {
            mechanic = mechanicRepository.findById(dto.getMechanicId())
                    .orElseThrow(() -> new RuntimeException("Mechanic not found"));
        }

        JobTask task = JobTask.builder()
                .jobCard(jobCard)
                .assignedMechanic(mechanic)
                .description(dto.getDescription())
                .instructions(dto.getInstructions())
                .status(TaskStatus.PENDING)
                .sequenceOrder(dto.getSequenceOrder())
                .estimatedHours(dto.getEstimatedHours())
                .build();

        JobTask saved = jobTaskRepository.save(task);
        return convertToDto(saved);
    }

    public JobTaskDto getJobTaskById(Long id) {
        JobTask task = jobTaskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Job task not found"));
        return convertToDto(task);
    }

    public List<JobTaskDto> getTasksByJobCard(Long jobCardId) {
        return jobTaskRepository.findByJobCardIdOrderBySequenceOrder(jobCardId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<JobTaskDto> getTasksByMechanic(Long mechanicId) {
        return jobTaskRepository.findByAssignedMechanicId(mechanicId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<JobTaskDto> getTasksByStatus(String status) {
        TaskStatus taskStatus = TaskStatus.valueOf(status);
        return jobTaskRepository.findByStatus(taskStatus).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public JobTaskDto updateJobTask(Long id, JobTaskDto dto) {
        JobTask task = jobTaskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Job task not found"));

        if (dto.getDescription() != null) {
            task.setDescription(dto.getDescription());
        }
        if (dto.getInstructions() != null) {
            task.setInstructions(dto.getInstructions());
        }
        if (dto.getMechanicId() != null && !dto.getMechanicId()
                .equals(task.getAssignedMechanic() != null ? task.getAssignedMechanic().getId() : null)) {
            Mechanic mechanic = mechanicRepository.findById(dto.getMechanicId())
                    .orElseThrow(() -> new RuntimeException("Mechanic not found"));
            task.setAssignedMechanic(mechanic);
        }
        if (dto.getSequenceOrder() != null) {
            task.setSequenceOrder(dto.getSequenceOrder());
        }
        if (dto.getEstimatedHours() != null) {
            task.setEstimatedHours(dto.getEstimatedHours());
        }

        JobTask updated = jobTaskRepository.save(task);
        return convertToDto(updated);
    }

    public JobTaskDto updateTaskStatus(Long id, String status) {
        JobTask task = jobTaskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Job task not found"));

        TaskStatus newStatus = TaskStatus.valueOf(status);
        task.setStatus(newStatus);

        if (newStatus == TaskStatus.IN_PROGRESS && task.getStartedAt() == null) {
            task.setStartedAt(LocalDateTime.now());
        } else if (newStatus == TaskStatus.COMPLETED && task.getCompletedAt() == null) {
            task.setCompletedAt(LocalDateTime.now());
        }

        JobTask updated = jobTaskRepository.save(task);
        return convertToDto(updated);
    }

    public void deleteJobTask(Long id) {
        jobTaskRepository.deleteById(id);
    }

    private JobTaskDto convertToDto(JobTask task) {
        return JobTaskDto.builder()
                .id(task.getId())
                .jobCardId(task.getJobCard().getId())
                .jobNumber(task.getJobCard().getJobNumber())
                .mechanicId(task.getAssignedMechanic() != null ? task.getAssignedMechanic().getId() : null)
                .mechanicName(task.getAssignedMechanic() != null ? task.getAssignedMechanic().getFullName() : null)
                .taskNumber(task.getTaskNumber())
                .description(task.getDescription())
                .instructions(task.getInstructions())
                .status(task.getStatus().toString())
                .sequenceOrder(task.getSequenceOrder())
                .estimatedHours(task.getEstimatedHours())
                .actualHours(task.getActualHours())
                .startedAt(task.getStartedAt())
                .completedAt(task.getCompletedAt())
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
    }
}
