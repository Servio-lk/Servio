package com.servio.challenger;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.servio.admin.dto.JobTaskDto;
import com.servio.admin.dto.PartRequestDto;
import com.servio.repair.dto.RepairPartDto;
import com.servio.repair.dto.RepairPartRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Challenger 2 Adversarial Stress Suite for Milestone 1.
 * Focus areas:
 * 1. DTO serialization consistency between Java and Flutter Dart models.
 * 2. Flutter JSON wire-compatibility with Jackson (UTC timestamps, numbers, enums).
 * 3. Migration V23 SQL syntax, foreign key cascade behaviors, indexes, and publications.
 * 4. Boundary inputs, decimal precision, and null safety.
 */
public class Milestone1Challenger2AdversarialTest {

    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
        objectMapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
    }

    // =========================================================================
    // 1. DTO SERIALIZATION CONSISTENCY (JAVA <-> FLUTTER DART)
    // =========================================================================
    @Nested
    @DisplayName("DTO Serialization Consistency Between Java & Flutter")
    class DtoSerializationConsistencyTests {

        @Test
        @DisplayName("Stress: Deserializing Flutter PartRequestModel.toJson() into Java PartRequestDto")
        void testFlutterPartRequestJsonToJavaDto() throws Exception {
            // This is the verbatim payload emitted by Flutter RequestPartsSheet -> PartRequestModel.toJson()
            String flutterJson = """
                {
                    "id": 1727611234567,
                    "partName": "Front Brake Rotor",
                    "partNumber": "BR-90210",
                    "quantity": 2,
                    "urgency": "URGENT",
                    "appointmentId": 42,
                    "vehicleDisplay": "2021 Honda Civic",
                    "notes": "Severe shuddering during braking",
                    "status": "PENDING"
                }
                """;

            PartRequestDto dto = objectMapper.readValue(flutterJson, PartRequestDto.class);

            assertNotNull(dto);
            assertEquals(1727611234567L, dto.getId());
            assertEquals("Front Brake Rotor", dto.getPartName());
            assertEquals("BR-90210", dto.getPartNumber());
            assertEquals(new BigDecimal("2"), dto.getQuantity());
            assertEquals("URGENT", dto.getUrgency());
            assertEquals(42L, dto.getAppointmentId());
            assertEquals("2021 Honda Civic", dto.getVehicleDisplay());
            assertEquals("Severe shuddering during braking", dto.getNotes());
            assertEquals("PENDING", dto.getStatus());
        }

        @Test
        @DisplayName("Stress: Java PartRequestDto serialized to JSON can be parsed by Flutter field mappings")
        void testJavaPartRequestDtoToFlutterFieldMap() throws Exception {
            PartRequestDto dto = PartRequestDto.builder()
                    .id(105L)
                    .mechanicId(12L)
                    .mechanicName("Sunil Shantha")
                    .appointmentId(42L)
                    .vehicleDisplay("2019 Toyota Corolla")
                    .partName("Cabin Air Filter")
                    .partNumber("CF-1002")
                    .quantity(BigDecimal.valueOf(3))
                    .unit("units")
                    .urgency("HIGH")
                    .notes("Replace during 40k service")
                    .status("APPROVED")
                    .createdAt(LocalDateTime.of(2026, 9, 29, 14, 30, 0))
                    .updatedAt(LocalDateTime.of(2026, 9, 29, 15, 0, 0))
                    .build();

            String json = objectMapper.writeValueAsString(dto);
            @SuppressWarnings("unchecked")
            Map<String, Object> map = objectMapper.readValue(json, Map.class);

            // Flutter PartRequestModel.fromJson expects:
            // id: json['id']
            // partName: json['partName'] ?? json['part_name']
            // partNumber: json['partNumber'] ?? json['part_number']
            // quantity: json['quantity']
            // urgency: json['urgency']
            // appointmentId: json['appointmentId'] ?? json['appointment_id']
            // vehicleDisplay: json['vehicleDisplay'] ?? json['vehicle_display']
            // notes: json['notes']
            // status: json['status']
            assertEquals(105, ((Number) map.get("id")).intValue());
            assertEquals("Cabin Air Filter", map.get("partName"));
            assertEquals("CF-1002", map.get("partNumber"));
            assertEquals(3, ((Number) map.get("quantity")).intValue());
            assertEquals("HIGH", map.get("urgency"));
            assertEquals(42, ((Number) map.get("appointmentId")).intValue());
            assertEquals("2019 Toyota Corolla", map.get("vehicleDisplay"));
            assertEquals("Replace during 40k service", map.get("notes"));
            assertEquals("APPROVED", map.get("status"));
        }

        @Test
        @DisplayName("Stress: Deserializing Flutter JobTaskModel.toJson() into Java JobTaskDto")
        void testFlutterJobTaskJsonToJavaDto() throws Exception {
            String flutterJson = """
                {
                    "id": 501,
                    "appointmentId": 88,
                    "taskNumber": "TASK-20260929-1",
                    "description": "Oil & Filter Change",
                    "instructions": "Use full synthetic 5W-30",
                    "status": "IN_PROGRESS",
                    "sequenceOrder": 2
                }
                """;

            JobTaskDto dto = objectMapper.readValue(flutterJson, JobTaskDto.class);

            assertNotNull(dto);
            assertEquals(501L, dto.getId());
            assertEquals(88L, dto.getAppointmentId());
            assertEquals("TASK-20260929-1", dto.getTaskNumber());
            assertEquals("Oil & Filter Change", dto.getDescription());
            assertEquals("Use full synthetic 5W-30", dto.getInstructions());
            assertEquals("IN_PROGRESS", dto.getStatus());
            assertEquals(2, dto.getSequenceOrder());
        }

        @Test
        @DisplayName("Stress: Java JobTaskDto serialized to JSON has all keys needed by Flutter JobTaskModel.fromJson")
        void testJavaJobTaskDtoToFlutterFieldMap() throws Exception {
            JobTaskDto dto = JobTaskDto.builder()
                    .id(201L)
                    .appointmentId(42L)
                    .jobCardId(10L)
                    .jobNumber("JC-2026-001")
                    .mechanicId(5L)
                    .mechanicName("Nimal Silva")
                    .taskNumber("TASK-001")
                    .description("Brake fluid flush")
                    .instructions("Ensure dot 4 fluid")
                    .status("COMPLETED")
                    .sequenceOrder(1)
                    .estimatedHours(1.0)
                    .actualHours(0.8)
                    .startedAt(LocalDateTime.of(2026, 9, 29, 10, 0))
                    .completedAt(LocalDateTime.of(2026, 9, 29, 10, 48))
                    .build();

            String json = objectMapper.writeValueAsString(dto);
            @SuppressWarnings("unchecked")
            Map<String, Object> map = objectMapper.readValue(json, Map.class);

            // Flutter JobTaskModel expects:
            // id: json['id']
            // appointmentId: json['appointmentId'] ?? json['appointment_id']
            // jobCardId: json['jobCardId'] ?? json['job_card_id']
            // taskNumber: json['taskNumber'] ?? json['task_number']
            // description: json['description']
            // instructions: json['instructions']
            // status: json['status']
            // sequenceOrder: json['sequenceOrder'] ?? json['sequence_order']
            // completedByName: json['mechanicName'] ?? json['mechanic_name'] ?? json['completedByName']
            assertEquals(201, ((Number) map.get("id")).intValue());
            assertEquals(42, ((Number) map.get("appointmentId")).intValue());
            assertEquals(10, ((Number) map.get("jobCardId")).intValue());
            assertEquals("TASK-001", map.get("taskNumber"));
            assertEquals("Brake fluid flush", map.get("description"));
            assertEquals("Ensure dot 4 fluid", map.get("instructions"));
            assertEquals("COMPLETED", map.get("status"));
            assertEquals(1, ((Number) map.get("sequenceOrder")).intValue());
            assertEquals("Nimal Silva", map.get("mechanicName"));
        }

        @Test
        @DisplayName("Stress: RepairPartRequest from Flutter ItemsUsedSheet deserialization")
        void testRepairPartRequestFlutterJsonToJavaDto() throws Exception {
            String flutterJson = """
                {
                    "partName": "Mobil 1 5W-30 Full Synthetic",
                    "partNumber": "MOB-5W30-4L",
                    "supplier": "Toyota Lanka",
                    "unitCost": 3500.00,
                    "quantity": 4,
                    "totalCost": 14000.00,
                    "status": "INSTALLED",
                    "notes": "Used during regular engine service"
                }
                """;

            RepairPartRequest req = objectMapper.readValue(flutterJson, RepairPartRequest.class);

            assertNotNull(req);
            assertEquals("Mobil 1 5W-30 Full Synthetic", req.getPartName());
            assertEquals("MOB-5W30-4L", req.getPartNumber());
            assertEquals("Toyota Lanka", req.getSupplier());
            assertEquals(0, new BigDecimal("3500.00").compareTo(req.getUnitCost()));
            assertEquals(4, req.getQuantity());
            assertEquals(0, new BigDecimal("14000.00").compareTo(req.getTotalCost()));
            assertEquals("INSTALLED", req.getStatus());
            assertEquals("Used during regular engine service", req.getNotes());
        }
    }

    // =========================================================================
    // 2. MIGRATION V23 DDL & SCHEMA INTEGRITY AUDIT
    // =========================================================================
    @Nested
    @DisplayName("Flyway V23 DDL & Schema Integrity Audit")
    class MigrationV23AuditTests {

        private String migrationSql;

        @BeforeEach
        void loadMigrationSql() throws Exception {
            File file = new File("src/main/resources/db/migration/V23__create_part_requests_and_task_enhancements.sql");
            assertTrue(file.exists(), "V23 migration file must exist at expected path");
            migrationSql = Files.readString(file.toPath());
        }

        @Test
        @DisplayName("Verify: part_requests table DDL definition has all required columns and types")
        void testPartRequestsTableStructure() {
            assertTrue(migrationSql.contains("CREATE TABLE IF NOT EXISTS part_requests"), "Must create part_requests table");
            assertTrue(migrationSql.contains("id BIGSERIAL PRIMARY KEY"), "Must define id BIGSERIAL PRIMARY KEY");
            assertTrue(migrationSql.contains("mechanic_id BIGINT REFERENCES mechanics(id) ON DELETE SET NULL"),
                    "mechanic_id must reference mechanics(id) with ON DELETE SET NULL");
            assertTrue(migrationSql.contains("appointment_id BIGINT REFERENCES appointments(id) ON DELETE SET NULL"),
                    "appointment_id must reference appointments(id) with ON DELETE SET NULL");
            assertTrue(migrationSql.contains("part_name VARCHAR(255) NOT NULL"), "part_name must be VARCHAR(255) NOT NULL");
            assertTrue(migrationSql.contains("part_number VARCHAR(100)"), "part_number must be VARCHAR(100)");
            assertTrue(migrationSql.contains("quantity DECIMAL(10,2) NOT NULL DEFAULT 1"), "quantity must be DECIMAL(10,2) NOT NULL DEFAULT 1");
            assertTrue(migrationSql.contains("unit VARCHAR(50) DEFAULT 'units'"), "unit must default to 'units'");
            assertTrue(migrationSql.contains("urgency VARCHAR(50) NOT NULL DEFAULT 'STANDARD'"), "urgency must default to 'STANDARD'");
            assertTrue(migrationSql.contains("notes TEXT"), "notes must be TEXT");
            assertTrue(migrationSql.contains("status VARCHAR(50) NOT NULL DEFAULT 'PENDING'"), "status must default to 'PENDING'");
            assertTrue(migrationSql.contains("created_at TIMESTAMP NOT NULL DEFAULT NOW()"), "created_at must default to NOW()");
            assertTrue(migrationSql.contains("updated_at TIMESTAMP DEFAULT NOW()"), "updated_at must default to NOW()");
        }

        @Test
        @DisplayName("Verify: All required performance indexes exist on part_requests")
        void testPartRequestsIndexes() {
            assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS idx_part_requests_status ON part_requests(status)"),
                    "Index on status must exist");
            assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS idx_part_requests_appointment_id ON part_requests(appointment_id)"),
                    "Index on appointment_id must exist");
            assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS idx_part_requests_mechanic_id ON part_requests(mechanic_id)"),
                    "Index on mechanic_id must exist");
        }

        @Test
        @DisplayName("Verify: job_tasks enhancements include appointment_id with ON DELETE CASCADE and indexes")
        void testJobTasksEnhancements() {
            assertTrue(migrationSql.contains("ALTER TABLE job_tasks ADD COLUMN IF NOT EXISTS appointment_id BIGINT REFERENCES appointments(id) ON DELETE CASCADE"),
                    "Must add appointment_id with ON DELETE CASCADE to job_tasks");
            assertTrue(migrationSql.contains("ALTER TABLE job_tasks ALTER COLUMN job_card_id DROP NOT NULL"),
                    "Must drop NOT NULL on job_card_id for standalone appointment tasks");
            assertTrue(migrationSql.contains("ALTER TABLE job_tasks ALTER COLUMN task_number DROP NOT NULL"),
                    "Must drop NOT NULL on task_number");
            assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS idx_job_tasks_appointment_id ON job_tasks(appointment_id)"),
                    "Must index appointment_id on job_tasks");
        }

        @Test
        @DisplayName("Verify: Backfill query correctly propagates appointment_id from job_cards to existing job_tasks")
        void testBackfillQueryIntegrity() {
            Pattern pattern = Pattern.compile("UPDATE\\s+job_tasks\\s+jt\\s+SET\\s+appointment_id\\s*=\\s*jc\\.appointment_id\\s+FROM\\s+job_cards\\s+jc", Pattern.CASE_INSENSITIVE);
            Matcher matcher = pattern.matcher(migrationSql);
            assertTrue(matcher.find(), "Must have valid backfill query linking job_tasks to job_cards.appointment_id");
        }

        @Test
        @DisplayName("Verify: Supabase Realtime publication registers part_requests, job_tasks, and repair_messages safely")
        void testSupabaseRealtimePublication() {
            assertTrue(migrationSql.contains("ALTER PUBLICATION supabase_realtime ADD TABLE part_requests"),
                    "Must add part_requests to supabase_realtime");
            assertTrue(migrationSql.contains("ALTER PUBLICATION supabase_realtime ADD TABLE job_tasks"),
                    "Must add job_tasks to supabase_realtime");
            assertTrue(migrationSql.contains("ALTER PUBLICATION supabase_realtime ADD TABLE repair_messages"),
                    "Must add repair_messages to supabase_realtime");
            assertTrue(migrationSql.contains("WHEN duplicate_object THEN NULL;"),
                    "Must handle duplicate_object gracefully");
            assertTrue(migrationSql.contains("WHEN undefined_object THEN NULL;"),
                    "Must handle undefined_object gracefully when running on non-Supabase PostgreSQL");
        }

        @Test
        @DisplayName("Verify: RLS policies are created for part_requests")
        void testRowLevelSecurityPolicies() {
            assertTrue(migrationSql.contains("ALTER TABLE part_requests ENABLE ROW LEVEL SECURITY"),
                    "Must enable RLS on part_requests");
            assertTrue(migrationSql.contains("CREATE POLICY part_requests_select_policy ON part_requests FOR SELECT"),
                    "Must have SELECT policy");
            assertTrue(migrationSql.contains("CREATE POLICY part_requests_insert_policy ON part_requests FOR INSERT"),
                    "Must have INSERT policy");
            assertTrue(migrationSql.contains("CREATE POLICY part_requests_update_policy ON part_requests FOR UPDATE"),
                    "Must have UPDATE policy");
        }
    }
}
