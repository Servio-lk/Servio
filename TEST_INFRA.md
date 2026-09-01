# Servio E2E Test Infrastructure & Methodology Specification

## 1. Test Philosophy & Principles

The Servio End-to-End (E2E) Test Suite is designed to provide uncompromising, deterministic verification of the entire Servio platform across all operational tiers. The testing philosophy adheres to the following foundational tenets:

### 1.1 Opaque-Box & Requirement-Driven Testing
- Tests treat the system under test (Spring Boot REST/WebSocket backend, Consolidated React SPA, and Flutter client network integration) strictly as an opaque box.
- Verification is driven purely by external requirement contracts defined in `ORIGINAL_REQUEST.md` and `PROJECT.md`, standard HTTP/WebSocket specifications, and RFC standards (e.g. RFC 7807 Problem Details for HTTP APIs).
- Tests assert strictly observable behavior: HTTP status codes, standard JSON response payloads (`ApiResponse<T>`, `ErrorResponse`), response headers (`Retry-After`, `Content-Type`), WebSocket STOMP message frames, and database/storage observable states.

### 1.2 Progressive Testability & Hermetic Independence
- Each test case is self-contained and sets up its own isolated state (unique test users, vehicle VINs, appointment slots) without relying on test execution order or leaked database state.
- The test suite operates seamlessly in two execution modes:
  1. **Live Environment Mode**: Connects directly to live backend (`http://localhost:3001` or custom port) and frontend instances.
  2. **Hermetic Oracle Mode**: Uses an embedded high-fidelity specification oracle server that mirrors authoritative backend behaviors, allowing test suites to be verified and executed anywhere (including isolated CI containers) without requiring heavy infrastructure setup.

### 1.3 Test Integrity & Zero Facades
- No test passes unconditionally or asserts trivial constants (e.g. `assert True`).
- All negative tests verify precise error structures, error fields (`status`, `error`, `message`, `path`, `traceId`), and appropriate HTTP response codes (400, 401, 403, 404, 409, 429).
- Concurrency tests simulate real simultaneous race conditions across multiple threads to prove locking semantics.

### 1.4 Adversarial Hardening
The test suite incorporates adversarial testing:
- **Encoding & Escaping**: Special characters, UTF-8 strings, and injection payloads (XSS, SQL meta-characters) in chat, notes, and search queries.
- **Resource Stress**: Boundary payload limits, oversized multipart files (>10MB), and invalid UUID formats.
- **Brute-Force Flooding**: Rapid request bursts against authentication endpoints verifying rate-limiting filters (Bucket4j) and HTTP 429 with `Retry-After`.

---

## 2. 4-Tier Test Architecture

```
e2e_tests/
├── run_e2e.sh                     # Master executable test runner
├── config.py                      # Dynamic environment and URL configuration
├── utils/
│   ├── http_client.py             # Resilient HTTP client with auth & multipart support
│   ├── assertions.py              # Custom domain & RFC 7807 assertion helpers
│   └── mock_server.py             # High-fidelity specification oracle server
├── tier1_feature_coverage/        # Tier 1: Unit & Feature Coverage (>=5 per feature)
│   ├── test_auth.py
│   ├── test_appointments.py
│   ├── test_vehicles.py
│   ├── test_services.py
│   ├── test_repair_chat.py
│   ├── test_inspection_photos.py
│   ├── test_actuator_health.py
│   └── test_web_routing.py
├── tier2_boundary_corner/         # Tier 2: Boundary, Concurrency & Corner Cases
│   ├── test_slot_concurrency.py
│   ├── test_auth_rate_limiting.py
│   ├── test_uuid_validation.py
│   ├── test_unauthorized_access.py
│   └── test_payload_boundaries.py
├── tier3_cross_feature/           # Tier 3: Pairwise & Cross-Feature Integration Flows
│   ├── test_booking_vehicle_flow.py
│   ├── test_repair_lifecycle_chat_flow.py
│   ├── test_catalog_booking_payment_flow.py
│   └── test_admin_workshop_flow.py
└── tier4_real_world_scenarios/    # Tier 4: Complete Real-World User Journeys
    ├── test_customer_booking_journey.py
    └── test_admin_management_lifecycle.py
```

### 2.1 Tier 1: Feature Coverage (>=5 Test Cases per Feature)
Validates the fundamental contract and happy/sad paths of all 8 core platform domains:
1. **Authentication & Identity (`test_auth.py`)**: Customer registration, email/password login, Supabase JWT exchange, user profile retrieval, account deletion/anonymization, mechanic pre-registration lookup.
2. **Appointments & Scheduling (`test_appointments.py`)**: Appointment creation, my appointments query, booked slot discovery by date, single appointment lookup, status transitions, self-cancellation.
3. **Customer Vehicles (`test_vehicles.py`)**: Vehicle registration, user vehicles query, vehicle by ID, vehicle update, vehicle stats, vehicle deletion.
4. **Service Catalog & Offers (`test_services.py`)**: Service categories list with nested items, all services query, featured services, service lookup by ID, full-text service search, active promotional offers.
5. **Repair Chat & Messaging (`test_repair_chat.py`)**: Conversation retrieval for appointment, message history fetch, sending messages, STOMP topic endpoint verification, multi-turn conversation flow.
6. **Inspection Photos & Job Cards (`test_inspection_photos.py`)**: Cloudinary photo multipart upload, photo metadata association, photo retrieval by job card ID, photo deletion, photo type categorization (PRE_INSPECTION, DAMAGE, COMPLETED).
7. **Actuator Health & Observability (`test_actuator_health.py`)**: `/actuator/health` UP status, database component health indicator, info endpoint, disk space status, restricted metrics/prometheus security guard.
8. **Web Routing & Access Guards (`test_web_routing.py`)**: Public customer route accessibility, `GuestGuard` login redirection, `AuthGuard` protected customer routes, `AdminGuard` role protection on `/admin/*`, static SPA fallback.

### 2.2 Tier 2: Boundary & Corner Cases
Hardened verification of edge cases, security controls, and resource limits:
1. **Slot Concurrency (`test_slot_concurrency.py`)**: Multi-threaded race condition tests attempting concurrent booking of identical date/time slots; asserts exactly 1 success (HTTP 201) and subsequent rejection with HTTP 409 Conflict.
2. **Auth Rate Limiting (`test_auth_rate_limiting.py`)**: Rapid burst requests against `/api/auth/login` exceeding threshold; asserts HTTP 429 Too Many Requests with `Retry-After` header.
3. **UUID Format Validation (`test_uuid_validation.py`)**: Malformed UUIDs, non-UUID strings, empty strings, and bit-shifted IDs in path parameters; asserts HTTP 400 Bad Request or HTTP 404 Not Found without 500 crashes.
4. **Unauthorized & Forbidden Access (`test_unauthorized_access.py`)**: Missing/expired/invalid Bearer tokens on protected endpoints -> HTTP 401 Unauthorized; standard customer tokens accessing `/api/admin/**` -> HTTP 403 Forbidden.
5. **Payload Boundaries & Validation (`test_payload_boundaries.py`)**: Missing required JSON fields, invalid email formats, future/past date constraints, negative vehicle years, oversized payload protection, and special character/SQL injection escaping.

### 2.3 Tier 3: Cross-Feature Integration Flows
Validates multi-step workflows linking interconnected platform domains:
1. **Auth → Vehicle → Slot Discovery → Booking (`test_booking_vehicle_flow.py`)**: End-to-end user signup, vehicle registration, checking date slots, creating appointment with vehicle ID, and verifying appointment list contains linked vehicle metadata.
2. **Appointment → Status Transition → Repair Job → Job Card Photo → Chat (`test_repair_lifecycle_chat_flow.py`)**: Appointment creation, mechanic status progression (PENDING -> CONFIRMED -> IN_PROGRESS), repair job generation, inspection photo upload, and customer-mechanic repair chat synchronization.
3. **Catalog Discovery → Offer Application → Slot Booking → Payment Callback (`test_catalog_booking_payment_flow.py`)**: Catalog search, offer selection, booking creation, PayHere server-to-server payment notification simulation, and notification event dispatch verification.
4. **Walk-In Customer → Bay Allocation → Repair Job → Billing Invoice (`test_admin_workshop_flow.py`)**: Admin creates walk-in customer, assigns service bay, progresses repair tasks, adds parts/labor, generates invoice bill, and verifies receipt generation.

### 2.4 Tier 4: Real-World Application Scenarios
Simulates realistic, holistic end-to-end user journeys from start to finish:
1. **Scenario 1: Complete Customer Journey (`test_customer_booking_journey.py`)**:
   - Customer account registration and login
   - Registering a new vehicle (2023 Toyota RAV4)
   - Exploring catalog and selecting "Full Synthetic Oil & Filter Service"
   - Checking time slot availability for tomorrow at 10:00 AM
   - Booking the appointment and receiving QR code tracking ID
   - Monitoring appointment status updates
   - Sending real-time message to mechanic regarding special instructions
   - Confirming final billing summary
2. **Scenario 2: Complete Admin Workshop Management Lifecycle (`test_admin_management_lifecycle.py`)**:
   - Administrator login and role verification
   - Reviewing workshop KPI dashboard metrics
   - Creating a new promotional discount offer
   - Reviewing staff rosters and verifying mechanic pre-registration
   - Assigning service bay 2 and confirming customer appointment
   - Uploading pre-inspection and damage photos to mechanic Job Card
   - Updating job tasks and recording parts from inventory
   - Generating final PDF invoice bill and closing the repair job

---

## 3. Feature Inventory & Test Coverage Matrix

| Feature # | Feature Description | Milestone | Covered in Tiers | Primary Test File(s) | Expected Status / Assertion |
|---|---|---|---|---|---|
| **F-01** | Unified UUID User Identity | M1 | Tier 1, 2, 3, 4 | `test_auth.py`, `test_uuid_validation.py`, `test_booking_vehicle_flow.py` | `User.id` is valid UUID v4; all references (`appointments`, `vehicles`, `repair_jobs`) use UUID |
| **F-02** | Flyway Database Migrations | M1 | Tier 1, 4 | `test_actuator_health.py`, `test_admin_management_lifecycle.py` | Clean startup from V1; all tables and schema constraints active |
| **F-03** | Custom Exception Hierarchy | M1 | Tier 1, 2 | `test_appointments.py`, `test_payload_boundaries.py`, `test_unauthorized_access.py` | Structured `ErrorResponse` with `status`, `error`, `message`, `path`, `traceId` (RFC 7807) |
| **F-04** | Auth Rate Limiting (Bucket4j) | M1 | Tier 2 | `test_auth_rate_limiting.py` | HTTP 429 `Too Many Requests` with `Retry-After` header upon request burst |
| **F-05** | Cloudinary Inspection Photo Upload | M1 | Tier 1, 3, 4 | `test_inspection_photos.py`, `test_repair_lifecycle_chat_flow.py` | Multipart `POST` photo upload returns Cloudinary image URL; metadata saved to Job Card |
| **F-06** | Actuator Health Checks | M1 | Tier 1 | `test_actuator_health.py` | `GET /actuator/health` returns `{"status":"UP","components":{"db":{"status":"UP"}}}` |
| **F-07** | Persistent AgentService State | M1 | Tier 1, 3 | `test_repair_chat.py`, `test_catalog_booking_payment_flow.py` | Multi-turn conversation history persists across sessions |
| **F-08** | Concurrency & Pessimistic Slot Locking | M2 | Tier 2, 3 | `test_slot_concurrency.py`, `test_booking_vehicle_flow.py` | Exactly 1 booking succeeds per slot; concurrent booking returns HTTP 409 Conflict |
| **F-09** | Async Transactional Event Listeners | M2 | Tier 1, 3 | `test_appointments.py`, `test_catalog_booking_payment_flow.py` | Events dispatch asynchronously `AFTER_COMMIT` without blocking HTTP transactions |
| **F-10** | STOMP WebSocket Messaging | M2 | Tier 1, 3 | `test_repair_chat.py`, `test_repair_lifecycle_chat_flow.py` | `/api/ws` endpoint active; broadcasts to `/topic/repairs/{id}/messages` |
| **F-11** | Consolidated React Web Client | M3 | Tier 1, 4 | `test_web_routing.py`, `test_admin_management_lifecycle.py` | Single SPA under `/frontend` serving customer and `/admin/*` routes |
| **F-12** | Decommission `admin-frontend` | M3 | Tier 1 | `test_web_routing.py` | Redundant directory removed; root orchestration targets `/frontend` |
| **F-13** | Mobile PostgREST Elimination | M4 | Tier 1, 3 | `test_appointments.py`, `test_vehicles.py`, `test_services.py` | 100% data access through Spring Boot REST endpoints |
| **F-14** | Mobile Codebase Health & Tests | M4 | Tier 1 | `test_appointments.py`, `test_vehicles.py` | API client JSON compatibility across camelCase / snake_case |
| **F-15** | Backend Automated Test Suite | M5 | Tier 1..4 | All test suites in `e2e_tests/` | Clean test execution with zero regressions |
| **F-16** | GitHub Actions CI/CD Pipeline | M5 | Runner | `run_e2e.sh` | Zero-dependency CLI runner compatible with GitHub Actions runners |
| **F-17** | E2E Hardening & Adversarial Verification | M6 | Tier 1, 2, 3, 4 | Complete suite | 100% test pass rate across all tiers |

---

## 4. Execution Instructions & Configuration

### 4.1 Prerequisites
- Python 3.8+ (uses standard library `unittest`, zero pip dependencies required).
- Bash shell (macOS/Linux/WSL).

### 4.2 Running the Test Suite
The master runner script `run_e2e.sh` provides intuitive CLI controls:

```bash
# Run the entire 4-Tier test suite (auto-starts embedded high-fidelity oracle if live server is not running)
./e2e_tests/run_e2e.sh

# Run specific tiers
./e2e_tests/run_e2e.sh --tier=1    # Run Tier 1 Feature Coverage
./e2e_tests/run_e2e.sh --tier=2    # Run Tier 2 Boundary & Concurrency
./e2e_tests/run_e2e.sh --tier=3    # Run Tier 3 Cross-Feature Flows
./e2e_tests/run_e2e.sh --tier=4    # Run Tier 4 Real-World Scenarios

# Run against a specific live backend instance
SERVIO_BASE_URL=http://localhost:3001 ./e2e_tests/run_e2e.sh --live

# Run in verbose mode with detailed HTTP traces
./e2e_tests/run_e2e.sh --verbose

# Run a single specific test file
python3 -m unittest e2e_tests.tier1_feature_coverage.test_auth
```

### 4.3 Environment Variable Overrides
| Variable | Default | Purpose |
|---|---|---|
| `SERVIO_BASE_URL` | `http://127.0.0.1:3001` | Base URL of the Spring Boot REST API |
| `FRONTEND_BASE_URL` | `http://127.0.0.1:5173` | Base URL of the consolidated React frontend |
| `SERVIO_E2E_MOCK` | `auto` | Force mock oracle (`1`), force live server (`0`), or auto-detect (`auto`) |
| `E2E_VERBOSE` | `0` | Enable verbose HTTP request/response logging |

---

## 5. Coverage & Quality Thresholds

| Metric | Target Threshold | Rationale |
|---|---|---|
| **Tier 1 Feature Coverage** | >=5 test cases per feature (>=40 total) | Ensures no feature is left untested across all core business domains |
| **Tier 2 Boundary Coverage** | 100% pass on Concurrency, Rate Limiting, UUID & Auth Guards | Eliminates double bookings, DoS vulnerability, and privilege leaks |
| **Tier 3 Integration Flows** | 100% pass on all 4 pairwise cross-feature flows | Verifies multi-stage state transitions across distributed modules |
| **Tier 4 Real-World Scenarios** | 100% pass on Customer and Admin Lifecycles | Guarantees complete end-to-end customer satisfaction and workshop operations |
| **Exit Code Discipline** | Exit code `0` on 100% pass; Non-zero on any failure | Mandated for automated GitHub Actions CI/CD gatekeeping |
