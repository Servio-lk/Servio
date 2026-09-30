package com.servio.admin.service;

import com.servio.admin.entity.JobCard;
import com.servio.admin.entity.JobTask;
import com.servio.admin.repository.JobTaskRepository;
import com.servio.admin.repository.JobCardRepository;
import com.servio.admin.entity.Mechanic;
import com.servio.admin.entity.TaskStatus;
import com.servio.admin.repository.MechanicRepository;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;

import com.servio.admin.dto.JobTaskDto;
import com.servio.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class JobTaskService {
    private final JobTaskRepository jobTaskRepository;
    private final JobCardRepository jobCardRepository;
    private final MechanicRepository mechanicRepository;
    private final AppointmentRepository appointmentRepository;

    public JobTaskDto createJobTask(JobTaskDto dto) {
        JobCard jobCard = null;
        if (dto.getJobCardId() != null) {
            jobCard = jobCardRepository.findById(dto.getJobCardId())
                    .orElseThrow(() -> new ResourceNotFoundException("Job card not found with id: " + dto.getJobCardId()));
        }

        Appointment appointment = null;
        if (dto.getAppointmentId() != null) {
            appointment = appointmentRepository.findById(dto.getAppointmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id: " + dto.getAppointmentId()));
        } else if (jobCard != null) {
            appointment = jobCard.getAppointment();
        }

        if (jobCard == null && appointment == null) {
            throw new IllegalArgumentException("Either jobCardId or appointmentId must be provided");
        }

        Mechanic mechanic = null;
        if (dto.getMechanicId() != null) {
            mechanic = mechanicRepository.findById(dto.getMechanicId())
                    .orElseThrow(() -> new ResourceNotFoundException("Mechanic not found with id: " + dto.getMechanicId()));
        } else if (jobCard != null && jobCard.getAssignedMechanic() != null) {
            mechanic = jobCard.getAssignedMechanic();
        }

        JobTask task = JobTask.builder()
                .appointment(appointment)
                .jobCard(jobCard)
                .assignedMechanic(mechanic)
                .taskNumber(dto.getTaskNumber())
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
                .orElseThrow(() -> new ResourceNotFoundException("Job task not found with id: " + id));
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
                .orElseThrow(() -> new ResourceNotFoundException("Job task not found with id: " + id));

        if (dto.getDescription() != null) {
            task.setDescription(dto.getDescription());
        }
        if (dto.getInstructions() != null) {
            task.setInstructions(dto.getInstructions());
        }
        if (dto.getMechanicId() != null && !dto.getMechanicId()
                .equals(task.getAssignedMechanic() != null ? task.getAssignedMechanic().getId() : null)) {
            Mechanic mechanic = mechanicRepository.findById(dto.getMechanicId())
                    .orElseThrow(() -> new ResourceNotFoundException("Mechanic not found with id: " + dto.getMechanicId()));
            task.setAssignedMechanic(mechanic);
        }
        if (dto.getSequenceOrder() != null) {
            task.setSequenceOrder(dto.getSequenceOrder());
        }
        if (dto.getEstimatedHours() != null) {
            task.setEstimatedHours(dto.getEstimatedHours());
        }
        if (dto.getAppointmentId() != null) {
            Appointment appointment = appointmentRepository.findById(dto.getAppointmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id: " + dto.getAppointmentId()));
            task.setAppointment(appointment);
        }

        JobTask updated = jobTaskRepository.save(task);
        return convertToDto(updated);
    }

    public List<JobTaskDto> getTasksByAppointment(Long appointmentId) {
        List<JobTask> tasks = jobTaskRepository.findByAppointmentIdOrderBySequenceOrder(appointmentId);
        if (tasks.isEmpty()) {
            Appointment appointment = appointmentRepository.findById(appointmentId).orElse(null);
            if (appointment != null) {
                tasks = seedStandardTasksForAppointment(appointment);
            }
        }
        return tasks.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    private List<JobTask> seedStandardTasksForAppointment(Appointment appointment) {
        String[][] standardTasks = {
                {"Initial vehicle inspection & diagnostics", "Inspect vehicle exterior, interior, lights, and fluids", "1.0"},
                {"Diagnostic scan & fault code analysis", "Connect OBD-II scanner and check error codes", "0.5"},
                {"Engine oil & filter replacement", "Drain old oil, replace oil filter, refill synthetic oil", "1.5"},
                {"Brake system inspection & pad check", "Check brake pad thickness, rotors, and brake lines", "1.0"},
                {"Tire pressure check & rotation", "Inspect tread depth, adjust pressure, rotate tires", "0.5"},
                {"Final quality check & road test", "Verify repair resolution and perform short road test", "1.0"}
        };

        List<JobCard> jobCards = jobCardRepository.findByAppointmentId(appointment.getId());
        JobCard jobCard = jobCards.isEmpty() ? null : jobCards.get(0);
        Mechanic assignedMechanic = jobCard != null ? jobCard.getAssignedMechanic() : null;

        List<JobTask> seeded = new ArrayList<>();
        long timestamp = System.currentTimeMillis();
        for (int i = 0; i < standardTasks.length; i++) {
            JobTask task = JobTask.builder()
                    .appointment(appointment)
                    .jobCard(jobCard)
                    .assignedMechanic(assignedMechanic)
                    .taskNumber("TASK-" + timestamp + "-" + (i + 1))
                    .description(standardTasks[i][0])
                    .instructions(standardTasks[i][1])
                    .status(TaskStatus.PENDING)
                    .sequenceOrder(i + 1)
                    .estimatedHours(Double.parseDouble(standardTasks[i][2]))
                    .build();
            seeded.add(jobTaskRepository.save(task));
        }
        return seeded;
    }

    public JobTaskDto updateTaskStatus(Long id, String status) {
        JobTask task = jobTaskRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Job task not found with id: " + id));

        TaskStatus newStatus = TaskStatus.valueOf(status.toUpperCase());
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
        Long jobCardId = task.getJobCard() != null ? task.getJobCard().getId() : null;
        String jobNumber = task.getJobCard() != null ? task.getJobCard().getJobNumber() : null;
        Long appointmentId = task.getAppointment() != null ? task.getAppointment().getId() :
                (task.getJobCard() != null && task.getJobCard().getAppointment() != null ? task.getJobCard().getAppointment().getId() : null);

        return JobTaskDto.builder()
                .id(task.getId())
                .appointmentId(appointmentId)
                .jobCardId(jobCardId)
                .jobNumber(jobNumber)
                .mechanicId(task.getAssignedMechanic() != null ? task.getAssignedMechanic().getId() : null)
                .mechanicName(task.getAssignedMechanic() != null ? task.getAssignedMechanic().getFullName() : null)
                .taskNumber(task.getTaskNumber())
                .description(task.getDescription())
                .instructions(task.getInstructions())
                .status(task.getStatus() != null ? task.getStatus().toString() : TaskStatus.PENDING.toString())
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
