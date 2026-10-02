package com.servio.admin.service;

import com.servio.admin.dto.JobTaskDto;
import com.servio.admin.entity.JobCard;
import com.servio.admin.entity.JobTask;
import com.servio.admin.entity.Mechanic;
import com.servio.admin.entity.TaskStatus;
import com.servio.admin.repository.JobCardRepository;
import com.servio.admin.repository.JobTaskRepository;
import com.servio.admin.repository.MechanicRepository;
import com.servio.booking.entity.Appointment;
import com.servio.booking.repository.AppointmentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JobTaskServiceTest {

    @Mock
    private JobTaskRepository jobTaskRepository;

    @Mock
    private JobCardRepository jobCardRepository;

    @Mock
    private MechanicRepository mechanicRepository;

    @Mock
    private AppointmentRepository appointmentRepository;

    @InjectMocks
    private JobTaskService jobTaskService;

    private Appointment testAppointment;
    private Mechanic testMechanic;

    @BeforeEach
    void setUp() {
        testMechanic = Mechanic.builder()
                .id(1L)
                .fullName("Sunil Shantha")
                .build();

        testAppointment = Appointment.builder()
                .id(50L)
                .serviceType("Standard Maintenance")
                .build();
    }

    @Test
    @DisplayName("getTasksByAppointment should return existing tasks if already present")
    void testGetTasksByAppointment_ExistingTasks() {
        JobTask existingTask = JobTask.builder()
                .id(101L)
                .appointment(testAppointment)
                .taskNumber("TASK-001")
                .description("Check engine oil")
                .status(TaskStatus.PENDING)
                .sequenceOrder(1)
                .build();

        when(jobTaskRepository.findByAppointmentIdOrderBySequenceOrder(50L))
                .thenReturn(List.of(existingTask));

        List<JobTaskDto> tasks = jobTaskService.getTasksByAppointment(50L);

        assertEquals(1, tasks.size());
        assertEquals(101L, tasks.get(0).getId());
        assertEquals(50L, tasks.get(0).getAppointmentId());
        assertEquals("Check engine oil", tasks.get(0).getDescription());
        verify(jobTaskRepository, never()).save(any(JobTask.class));
    }

    @Test
    @DisplayName("getTasksByAppointment should auto-seed standard 6 checklist items when no tasks exist")
    void testGetTasksByAppointment_AutoSeedWhenEmpty() {
        when(jobTaskRepository.findByAppointmentIdOrderBySequenceOrder(50L))
                .thenReturn(Collections.emptyList());
        when(appointmentRepository.findById(50L))
                .thenReturn(Optional.of(testAppointment));
        when(jobCardRepository.findByAppointmentId(50L))
                .thenReturn(Collections.emptyList());
        when(jobTaskRepository.save(any(JobTask.class)))
                .thenAnswer(invocation -> {
                    JobTask t = invocation.getArgument(0);
                    return JobTask.builder()
                            .id((long) (t.getSequenceOrder() + 1000))
                            .appointment(t.getAppointment())
                            .taskNumber(t.getTaskNumber())
                            .description(t.getDescription())
                            .instructions(t.getInstructions())
                            .status(t.getStatus())
                            .sequenceOrder(t.getSequenceOrder())
                            .estimatedHours(t.getEstimatedHours())
                            .build();
                });

        List<JobTaskDto> tasks = jobTaskService.getTasksByAppointment(50L);

        assertEquals(6, tasks.size());
        assertEquals("Initial vehicle inspection & diagnostics", tasks.get(0).getDescription());
        assertEquals(1, tasks.get(0).getSequenceOrder());
        assertEquals(50L, tasks.get(0).getAppointmentId());

        assertEquals("Final quality check & road test", tasks.get(5).getDescription());
        assertEquals(6, tasks.get(5).getSequenceOrder());

        verify(jobTaskRepository, times(6)).save(any(JobTask.class));
    }

    @Test
    @DisplayName("updateTaskStatus should set startedAt on IN_PROGRESS and completedAt on COMPLETED")
    void testUpdateTaskStatus_Lifecycle() {
        JobTask task = JobTask.builder()
                .id(200L)
                .taskNumber("TASK-200")
                .description("Brake fluid flush")
                .status(TaskStatus.PENDING)
                .appointment(testAppointment)
                .build();

        when(jobTaskRepository.findById(200L)).thenReturn(Optional.of(task));
        when(jobTaskRepository.save(any(JobTask.class))).thenAnswer(i -> i.getArgument(0));

        JobTaskDto inProgressDto = jobTaskService.updateTaskStatus(200L, "IN_PROGRESS");
        assertEquals("IN_PROGRESS", inProgressDto.getStatus());
        assertNotNull(inProgressDto.getStartedAt());
        assertNull(inProgressDto.getCompletedAt());

        JobTaskDto completedDto = jobTaskService.updateTaskStatus(200L, "COMPLETED");
        assertEquals("COMPLETED", completedDto.getStatus());
        assertNotNull(completedDto.getCompletedAt());
    }

    @Test
    @DisplayName("convertToDto handles null jobCard safely without throwing NullPointerException")
    void testCreateJobTask_WithDirectAppointment() {
        JobTaskDto requestDto = JobTaskDto.builder()
                .appointmentId(50L)
                .description("Custom direct appointment task")
                .sequenceOrder(1)
                .build();

        when(appointmentRepository.findById(50L)).thenReturn(Optional.of(testAppointment));
        when(jobTaskRepository.save(any(JobTask.class))).thenAnswer(invocation -> {
            JobTask t = invocation.getArgument(0);
            t.setId(300L);
            return t;
        });

        JobTaskDto result = jobTaskService.createJobTask(requestDto);

        assertNotNull(result);
        assertEquals(300L, result.getId());
        assertEquals(50L, result.getAppointmentId());
        assertNull(result.getJobCardId());
        assertNull(result.getJobNumber());
        assertEquals("Custom direct appointment task", result.getDescription());
    }
}
