package com.servio.challenger;

import com.servio.admin.controller.AdminAppointmentController;
import com.servio.admin.controller.AdminJobTaskController;
import com.servio.admin.controller.AdminStaffController;
import com.servio.admin.dto.JobTaskDto;
import com.servio.admin.dto.PartRequestDto;
import com.servio.admin.entity.JobCard;
import com.servio.admin.entity.JobTask;
import com.servio.admin.entity.Mechanic;
import com.servio.admin.entity.TaskStatus;
import com.servio.admin.repository.JobCardRepository;
import com.servio.admin.repository.JobTaskRepository;
import com.servio.admin.repository.MechanicRepository;
import com.servio.booking.entity.Appointment;
import com.servio.booking.entity.Vehicle;
import com.servio.booking.repository.AppointmentRepository;
import com.servio.common.exception.ResourceNotFoundException;
import com.servio.inventory.controller.InventoryController;
import com.servio.inventory.entity.PartRequest;
import com.servio.inventory.repository.PartRequestRepository;
import com.servio.inventory.service.PartRequestService;
import com.servio.admin.service.JobTaskService;
import com.servio.repair.controller.RepairJobController;
import com.servio.repair.dto.RepairPartRequest;
import com.servio.repair.entity.RepairJob;
import com.servio.repair.entity.RepairPart;
import com.servio.repair.repository.RepairJobRepository;
import com.servio.repair.repository.RepairPartRepository;
import com.servio.repair.service.RepairJobService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.expression.Expression;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.expression.spel.support.StandardEvaluationContext;
import org.springframework.security.access.expression.SecurityExpressionRoot;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Empirical Adversarial Challenge Test Suite for Milestone 1 (Backend V23 Migration & Endpoints).
 * Stress tests:
 * 1. Missing optional fields, null foreign keys, and edge-case vehicle string formatting in PartRequestService.
 * 2. Null jobCard, missing appointments, task lifecycle transitions, and empty auto-seeding in JobTaskService.
 * 3. Security role authorization (MECHANIC vs ADMIN vs CUSTOMER vs Unauthenticated).
 * 4. Boundary defaults and cost arithmetic in RepairJobService parts logging.
 */
@ExtendWith(MockitoExtension.class)
public class Milestone1AdversarialStressTest {

    // =========================================================================
    // SECTION 1: PART REQUEST ADVERSARIAL STRESS TESTS
    // =========================================================================
    @Nested
    @DisplayName("PartRequest Edge Cases & Missing Optional Fields")
    class PartRequestStressTests {

        @Mock
        private PartRequestRepository partRequestRepository;
        @Mock
        private MechanicRepository mechanicRepository;
        @Mock
        private AppointmentRepository appointmentRepository;
        @Mock
        private Authentication authentication;

        @InjectMocks
        private PartRequestService partRequestService;

        private Appointment appointmentWithVehicle;

        @BeforeEach
        void setUp() {
            Vehicle vehicle = Vehicle.builder()
                    .year(2021)
                    .make("Honda")
                    .model("Civic")
                    .build();
            appointmentWithVehicle = Appointment.builder()
                    .id(200L)
                    .vehicle(vehicle)
                    .build();
        }

        @Test
        @DisplayName("Stress: Part request with ALL optional fields missing applies defaults without crashing")
        void testCreatePartRequest_AllOptionalFieldsNull() {
            PartRequestDto minimalDto = PartRequestDto.builder()
                    .partName("Serpentine Belt")
                    .build(); // notes, partNumber, quantity, unit, urgency, mechanicId, appointmentId ALL null

            ArgumentCaptor<PartRequest> captor = ArgumentCaptor.forClass(PartRequest.class);
            when(partRequestRepository.save(captor.capture())).thenAnswer(invocation -> {
                PartRequest p = invocation.getArgument(0);
                p.setId(99L);
                p.setCreatedAt(LocalDateTime.now());
                return p;
            });

            PartRequestDto result = partRequestService.createRequest(minimalDto, null);

            assertNotNull(result);
            assertEquals(99L, result.getId());
            assertEquals("Serpentine Belt", result.getPartName());
            assertEquals(BigDecimal.ONE, result.getQuantity(), "Quantity must default to BigDecimal.ONE (1)");
            assertEquals("units", result.getUnit(), "Unit must default to 'units'");
            assertEquals("STANDARD", result.getUrgency(), "Urgency must default to 'STANDARD'");
            assertEquals("PENDING", result.getStatus(), "Status must default to 'PENDING'");
            assertNull(result.getPartNumber(), "Part number should be null");
            assertNull(result.getNotes(), "Notes should be null");
            assertNull(result.getMechanicId(), "Mechanic ID should be null");
            assertNull(result.getMechanicName(), "Mechanic Name should be null");
            assertNull(result.getAppointmentId(), "Appointment ID should be null");
            assertNull(result.getVehicleDisplay(), "Vehicle display should be null");

            PartRequest entity = captor.getValue();
            assertNull(entity.getMechanic());
            assertNull(entity.getAppointment());
            assertEquals("STANDARD", entity.getUrgency());
            assertEquals(BigDecimal.ONE, entity.getQuantity());
        }

        @Test
        @DisplayName("Stress: Non-existent mechanicId and appointmentId fall back to null foreign keys gracefully")
        void testCreatePartRequest_NonExistentForeignKeys() {
            PartRequestDto inputDto = PartRequestDto.builder()
                    .partName("Brake Caliper")
                    .mechanicId(99999L)
                    .appointmentId(88888L)
                    .build();

            when(mechanicRepository.findById(99999L)).thenReturn(Optional.empty());
            when(appointmentRepository.findById(88888L)).thenReturn(Optional.empty());
            when(partRequestRepository.save(any(PartRequest.class))).thenAnswer(i -> {
                PartRequest p = i.getArgument(0);
                p.setId(105L);
                return p;
            });

            PartRequestDto result = partRequestService.createRequest(inputDto, null);

            assertNotNull(result);
            assertNull(result.getMechanicId());
            assertNull(result.getAppointmentId());
            verify(partRequestRepository, times(1)).save(any(PartRequest.class));
        }

        @Test
        @DisplayName("Stress: Vehicle display string formatting handles partial, empty, and null fields")
        void testVehicleDisplayFormattingVariants() {
            // Case 1: Vehicle with only model
            Vehicle vModelOnly = Vehicle.builder().model("Aqua").build();
            Appointment app1 = Appointment.builder().id(1L).vehicle(vModelOnly).build();

            // Case 2: Vehicle with only year
            Vehicle vYearOnly = Vehicle.builder().year(2018).build();
            Appointment app2 = Appointment.builder().id(2L).vehicle(vYearOnly).build();

            // Case 3: Vehicle with all null attributes
            Vehicle vEmpty = Vehicle.builder().build();
            Appointment app3 = Appointment.builder().id(3L).vehicle(vEmpty).build();

            // Case 4: Appointment with null vehicle
            Appointment app4 = Appointment.builder().id(4L).vehicle(null).build();

            List<PartRequest> list = List.of(
                    PartRequest.builder().id(1L).partName("Part A").appointment(app1).build(),
                    PartRequest.builder().id(2L).partName("Part B").appointment(app2).build(),
                    PartRequest.builder().id(3L).partName("Part C").appointment(app3).build(),
                    PartRequest.builder().id(4L).partName("Part D").appointment(app4).build()
            );

            when(partRequestRepository.findAllByOrderByCreatedAtDesc()).thenReturn(list);

            List<PartRequestDto> results = partRequestService.getAllRequests();
            assertEquals("Aqua", results.get(0).getVehicleDisplay());
            assertEquals("2018", results.get(1).getVehicleDisplay());
            assertNull(results.get(2).getVehicleDisplay(), "Empty vehicle attributes should yield null display string");
            assertNull(results.get(3).getVehicleDisplay(), "Null vehicle should yield null display string");
        }

        @Test
        @DisplayName("Stress: Status update forces uppercase and throws ResourceNotFoundException on invalid ID")
        void testUpdateStatus_ValidAndInvalidId() {
            PartRequest req = PartRequest.builder().id(10L).partName("Oil").status("PENDING").build();
            when(partRequestRepository.findById(10L)).thenReturn(Optional.of(req));
            when(partRequestRepository.save(any(PartRequest.class))).thenAnswer(i -> i.getArgument(0));

            PartRequestDto updated = partRequestService.updateStatus(10L, "rejected");
            assertEquals("REJECTED", updated.getStatus());

            when(partRequestRepository.findById(999L)).thenReturn(Optional.empty());
            assertThrows(ResourceNotFoundException.class, () -> partRequestService.updateStatus(999L, "APPROVED"));
        }
    }

    // =========================================================================
    // SECTION 2: JOB TASK SERVICE NULL JOBCARD & SEEDING STRESS TESTS
    // =========================================================================
    @Nested
    @DisplayName("JobTaskService Null JobCard & Auto-Seeding Resilience")
    class JobTaskServiceStressTests {

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

        private Appointment appointment;

        @BeforeEach
        void setUp() {
            appointment = Appointment.builder().id(300L).serviceType("Brake Service").build();
        }

        @Test
        @DisplayName("Stress: getTasksByAppointment auto-seeds 6 tasks when tasks empty and NO jobCard exists")
        void testAutoSeeding_NoExistingJobCard() {
            when(jobTaskRepository.findByAppointmentIdOrderBySequenceOrder(300L)).thenReturn(Collections.emptyList());
            when(appointmentRepository.findById(300L)).thenReturn(Optional.of(appointment));
            when(jobCardRepository.findByAppointmentId(300L)).thenReturn(Collections.emptyList()); // No job cards exist!

            when(jobTaskRepository.save(any(JobTask.class))).thenAnswer(invocation -> {
                JobTask t = invocation.getArgument(0);
                t.setId((long) (t.getSequenceOrder() + 500));
                return t;
            });

            List<JobTaskDto> seededTasks = jobTaskService.getTasksByAppointment(300L);

            assertEquals(6, seededTasks.size(), "Must auto-seed exactly 6 standard tasks");
            for (int i = 0; i < seededTasks.size(); i++) {
                JobTaskDto dto = seededTasks.get(i);
                assertEquals(300L, dto.getAppointmentId());
                assertNull(dto.getJobCardId(), "JobCardId must be null when no job card exists");
                assertNull(dto.getJobNumber(), "JobNumber must be null when no job card exists");
                assertNull(dto.getMechanicId(), "MechanicId must be null when no job card exists");
                assertEquals(i + 1, dto.getSequenceOrder());
                assertEquals("PENDING", dto.getStatus());
                assertNotNull(dto.getDescription());
                assertNotNull(dto.getInstructions());
                assertTrue(dto.getEstimatedHours() > 0);
            }
            verify(jobTaskRepository, times(6)).save(any(JobTask.class));
        }

        @Test
        @DisplayName("Stress: getTasksByAppointment for non-existent appointment ID returns empty list safely")
        void testGetTasksByAppointment_NonExistentAppointmentReturnsEmpty() {
            when(jobTaskRepository.findByAppointmentIdOrderBySequenceOrder(9999L)).thenReturn(Collections.emptyList());
            when(appointmentRepository.findById(9999L)).thenReturn(Optional.empty());

            List<JobTaskDto> result = jobTaskService.getTasksByAppointment(9999L);
            assertNotNull(result);
            assertTrue(result.isEmpty(), "Must return empty list if appointment ID does not exist");
            verify(jobTaskRepository, never()).save(any(JobTask.class));
        }

        @Test
        @DisplayName("Stress: createJobTask with neither jobCardId nor appointmentId throws IllegalArgumentException")
        void testCreateJobTask_MissingBothIdsThrowsException() {
            JobTaskDto invalidDto = JobTaskDto.builder()
                    .description("Orphan task without appointment or jobCard")
                    .build();

            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                    () -> jobTaskService.createJobTask(invalidDto));
            assertTrue(ex.getMessage().contains("Either jobCardId or appointmentId must be provided"));
        }

        @Test
        @DisplayName("Stress: createJobTask directly for appointment without jobCard succeeds without NPE")
        void testCreateJobTask_DirectAppointmentNoJobCard() {
            JobTaskDto requestDto = JobTaskDto.builder()
                    .appointmentId(300L)
                    .description("Custom diagnostic inspection")
                    .instructions("Use OBD scanner")
                    .sequenceOrder(1)
                    .estimatedHours(1.5)
                    .build();

            when(appointmentRepository.findById(300L)).thenReturn(Optional.of(appointment));
            when(jobTaskRepository.save(any(JobTask.class))).thenAnswer(i -> {
                JobTask saved = i.getArgument(0);
                saved.setId(777L);
                return saved;
            });

            JobTaskDto created = jobTaskService.createJobTask(requestDto);

            assertNotNull(created);
            assertEquals(777L, created.getId());
            assertEquals(300L, created.getAppointmentId());
            assertNull(created.getJobCardId());
            assertNull(created.getJobNumber());
            assertEquals("Custom diagnostic inspection", created.getDescription());
        }

        @Test
        @DisplayName("Stress: updateJobTask on task with null jobCard does not throw NullPointerException")
        void testUpdateJobTask_TaskWithNullJobCard() {
            JobTask existingTask = JobTask.builder()
                    .id(400L)
                    .appointment(appointment)
                    .jobCard(null) // Null jobCard
                    .description("Initial description")
                    .status(TaskStatus.PENDING)
                    .build();

            when(jobTaskRepository.findById(400L)).thenReturn(Optional.of(existingTask));
            when(jobTaskRepository.save(any(JobTask.class))).thenAnswer(i -> i.getArgument(0));

            JobTaskDto updateDto = JobTaskDto.builder()
                    .description("Updated description")
                    .sequenceOrder(3)
                    .estimatedHours(2.0)
                    .build();

            JobTaskDto updated = jobTaskService.updateJobTask(400L, updateDto);

            assertEquals("Updated description", updated.getDescription());
            assertEquals(3, updated.getSequenceOrder());
            assertEquals(2.0, updated.getEstimatedHours());
            assertNull(updated.getJobCardId());
        }

        @Test
        @DisplayName("Stress: Task status lifecycle preserves startedAt and completedAt on re-entry")
        void testTaskStatusLifecycle_PreservesTimestamps() {
            LocalDateTime originalStart = LocalDateTime.of(2026, 9, 29, 9, 0);
            JobTask task = JobTask.builder()
                    .id(500L)
                    .appointment(appointment)
                    .status(TaskStatus.IN_PROGRESS)
                    .startedAt(originalStart)
                    .build();

            when(jobTaskRepository.findById(500L)).thenReturn(Optional.of(task));
            when(jobTaskRepository.save(any(JobTask.class))).thenAnswer(i -> i.getArgument(0));

            // Re-update to IN_PROGRESS: should not change startedAt
            JobTaskDto result = jobTaskService.updateTaskStatus(500L, "IN_PROGRESS");
            assertEquals(originalStart, result.getStartedAt());

            // Transition to COMPLETED
            JobTaskDto completedResult = jobTaskService.updateTaskStatus(500L, "COMPLETED");
            assertNotNull(completedResult.getCompletedAt());
            LocalDateTime originalCompleted = completedResult.getCompletedAt();

            // Re-update to COMPLETED: should not change completedAt
            JobTaskDto reCompletedResult = jobTaskService.updateTaskStatus(500L, "COMPLETED");
            assertEquals(originalCompleted, reCompletedResult.getCompletedAt());
        }
    }

    // =========================================================================
    // SECTION 3: SECURITY ROLE AUTHORIZATION CONSTRAINT TESTS
    // =========================================================================
    @Nested
    @DisplayName("Security Constraints & Role Evaluation (MECHANIC vs ADMIN vs CUSTOMER)")
    class SecurityRoleConstraintsTests {

        private boolean evaluateSpel(String expression, Authentication auth) {
            SecurityExpressionRoot root = new SecurityExpressionRoot(auth) {};
            StandardEvaluationContext context = new StandardEvaluationContext(root);
            SpelExpressionParser parser = new SpelExpressionParser();
            Expression exp = parser.parseExpression(expression);
            Boolean val = exp.getValue(context, Boolean.class);
            return val != null && val;
        }

        private Authentication createAuth(String role) {
            return new UsernamePasswordAuthenticationToken(
                    "user@servio.lk",
                    "secret",
                    List.of(new SimpleGrantedAuthority(role))
            );
        }

        @Test
        @DisplayName("Empirical SpEL: hasAnyAuthority('ADMIN', 'MECHANIC') permits ADMIN and MECHANIC, blocks others")
        void testHasAnyAuthorityAdminMechanicEvaluation() {
            String expr = "hasAnyAuthority('ADMIN', 'MECHANIC')";

            assertTrue(evaluateSpel(expr, createAuth("ADMIN")), "ADMIN must be allowed");
            assertTrue(evaluateSpel(expr, createAuth("MECHANIC")), "MECHANIC must be allowed");
            assertFalse(evaluateSpel(expr, createAuth("CUSTOMER")), "CUSTOMER must be blocked");
            assertFalse(evaluateSpel(expr, createAuth("USER")), "USER must be blocked");
            assertFalse(evaluateSpel(expr, createAuth("RECEPTIONIST")), "RECEPTIONIST must be blocked");
        }

        @Test
        @DisplayName("Empirical SpEL: hasAuthority('ADMIN') permits ADMIN and strictly blocks MECHANIC and CUSTOMER")
        void testHasAuthorityAdminEvaluation() {
            String expr = "hasAuthority('ADMIN')";

            assertTrue(evaluateSpel(expr, createAuth("ADMIN")), "ADMIN must be allowed");
            assertFalse(evaluateSpel(expr, createAuth("MECHANIC")), "MECHANIC must be blocked on admin endpoints");
            assertFalse(evaluateSpel(expr, createAuth("CUSTOMER")), "CUSTOMER must be blocked on admin endpoints");
        }

        @Test
        @DisplayName("Controller Annotations: InventoryController has correct PreAuthorize annotations on all methods")
        void testInventoryControllerSecurityAnnotations() throws NoSuchMethodException {
            Method getAll = InventoryController.class.getMethod("getAllItems");
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", getAll.getAnnotation(PreAuthorize.class).value());

            Method getLowStock = InventoryController.class.getMethod("getLowStockItems");
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", getLowStock.getAnnotation(PreAuthorize.class).value());

            Method createPartReq = InventoryController.class.getMethod("createPartRequest", PartRequestDto.class, Authentication.class);
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", createPartReq.getAnnotation(PreAuthorize.class).value());

            Method getAllPartReq = InventoryController.class.getMethod("getAllPartRequests");
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", getAllPartReq.getAnnotation(PreAuthorize.class).value());

            Method getReqByApp = InventoryController.class.getMethod("getRequestsByAppointment", Long.class);
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", getReqByApp.getAnnotation(PreAuthorize.class).value());

            // Status modification must remain ADMIN-only (mechanic cannot approve their own requests)
            Method updateStatus = InventoryController.class.getMethod("updateRequestStatus", Long.class, String.class);
            assertEquals("hasAuthority('ADMIN')", updateStatus.getAnnotation(PreAuthorize.class).value());

            // Inventory mutations must remain ADMIN-only
            Method createItem = InventoryController.class.getMethod("createItem", com.servio.admin.dto.InventoryItemRequest.class, Authentication.class);
            assertEquals("hasAuthority('ADMIN')", createItem.getAnnotation(PreAuthorize.class).value());
        }

        @Test
        @DisplayName("Controller Annotations: AdminJobTaskController enforces class-level PreAuthorize for ADMIN and MECHANIC")
        void testJobTaskControllerSecurityAnnotation() {
            PreAuthorize classAnnotation = AdminJobTaskController.class.getAnnotation(PreAuthorize.class);
            assertNotNull(classAnnotation, "AdminJobTaskController must have @PreAuthorize at class level");
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", classAnnotation.value());
        }

        @Test
        @DisplayName("Controller Annotations: AdminAppointmentController assignMechanic endpoint permits MECHANIC")
        void testAssignMechanicSecurityAnnotation() throws NoSuchMethodException {
            Method assignMechanic = AdminAppointmentController.class.getMethod("assignMechanic", Long.class, com.servio.admin.dto.AssignMechanicRequest.class);
            assertNotNull(assignMechanic.getAnnotation(PreAuthorize.class));
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", assignMechanic.getAnnotation(PreAuthorize.class).value());

            // Other appointment methods must remain ADMIN only
            Method getAll = AdminAppointmentController.class.getMethod("getAllAppointments", String.class);
            assertEquals("hasAuthority('ADMIN')", getAll.getAnnotation(PreAuthorize.class).value());
        }

        @Test
        @DisplayName("Controller Annotations: RepairJobController logPartUsed allows MECHANIC and ADMIN")
        void testRepairJobControllerSecurityAnnotations() throws NoSuchMethodException {
            Method logPart = RepairJobController.class.getMethod("logPartUsed", Long.class, RepairPartRequest.class);
            assertNotNull(logPart.getAnnotation(PreAuthorize.class));
            assertEquals("hasAnyAuthority('ADMIN', 'MECHANIC')", logPart.getAnnotation(PreAuthorize.class).value());
        }
    }

    // =========================================================================
    // SECTION 4: REPAIR PARTS USED LOGGING BOUNDARY TESTS
    // =========================================================================
    @Nested
    @DisplayName("RepairJobService Parts Used Logging Stress Tests")
    class RepairPartsUsedStressTests {

        @Mock
        private RepairJobRepository repairJobRepository;
        @Mock
        private RepairPartRepository repairPartRepository;
        @Mock
        private AppointmentRepository appointmentRepository;

        @InjectMocks
        private RepairJobService repairJobService;

        private RepairJob repairJob;

        @BeforeEach
        void setUp() {
            repairJob = RepairJob.builder()
                    .id(50L)
                    .partsCost(BigDecimal.valueOf(1000))
                    .laborCost(BigDecimal.valueOf(2000))
                    .actualCost(BigDecimal.valueOf(3000))
                    .build();
        }

        @Test
        @DisplayName("Stress: logPartUsed defaults null unitCost and null quantity to 0 and 1")
        void testLogPartUsed_NullDefaults() {
            Long appointmentId = 123L;
            when(repairJobRepository.findFirstByAppointmentId(appointmentId)).thenReturn(Optional.of(repairJob));

            RepairPartRequest req = RepairPartRequest.builder()
                    .partName("Brake Bleeder Valve")
                    .build(); // unitCost, quantity, totalCost, status ALL null

            ArgumentCaptor<RepairPart> partCaptor = ArgumentCaptor.forClass(RepairPart.class);
            when(repairPartRepository.save(partCaptor.capture())).thenAnswer(i -> {
                RepairPart p = i.getArgument(0);
                p.setId(601L);
                return p;
            });

            RepairPart result = repairJobService.logPartUsed(appointmentId, req);

            assertNotNull(result);
            assertEquals(601L, result.getId());

            RepairPart captured = partCaptor.getValue();
            assertEquals("Brake Bleeder Valve", captured.getPartName());
            assertEquals(BigDecimal.ZERO, captured.getUnitCost(), "unitCost must default to BigDecimal.ZERO");
            assertEquals(1, captured.getQuantity(), "quantity must default to 1");
            assertEquals(BigDecimal.ZERO, captured.getTotalCost(), "totalCost must default to BigDecimal.ZERO");
            assertEquals("INSTALLED", captured.getStatus(), "status must default to 'INSTALLED'");

            // Verify repair job actual cost remains consistent
            verify(repairJobRepository, times(1)).save(repairJob);
            assertEquals(BigDecimal.valueOf(1000), repairJob.getPartsCost());
            assertEquals(BigDecimal.valueOf(3000), repairJob.getActualCost());
        }

        @Test
        @DisplayName("Stress: getPartsForAppointment when no repairJob exists returns empty list without error")
        void testGetPartsForAppointment_NoJobReturnsEmptyList() {
            when(repairJobRepository.findFirstByAppointmentId(999L)).thenReturn(Optional.empty());

            List<RepairPart> parts = repairJobService.getPartsForAppointment(999L);
            assertNotNull(parts);
            assertTrue(parts.isEmpty());
            verify(repairPartRepository, never()).findByRepairJobIdOrderByCreatedDateDesc(any());
        }
    }
}
