# Project: Servio System Architecture Overhaul

## Architecture
Servio is an automotive service management platform consisting of:
1. **Authoritative Backend (`backend/`)**: Spring Boot 3.3.4 (Java 17) REST & WebSocket API, Spring Data JPA / Hibernate, Flyway migrations, PostgreSQL, Spring Security JWT, Bucket4j rate limiting, Cloudinary, and Spring Boot Actuator.
2. **Unified Web Client (`frontend/`)**: React 19 + TypeScript + Vite SPA serving both customer flows (`/`, `/booking`, `/services`, `/profile`) and admin management flows (`/admin/*`) with role-based route guards (`AuthGuard`, `AdminGuard`) and code-split lazy loading.
3. **Mobile Clients (`mobile/`)**: Flutter multi-app architecture (`customer_app`, `mechanic_app`, and `shared_core` package) communicating exclusively with the Spring Boot REST API and STOMP WebSocket broker.
4. **Data Layer**: PostgreSQL with unified UUID user identifiers linked to Supabase Auth, versioned Flyway migrations, and slot concurrency constraints.
5. **CI/CD Pipeline**: GitHub Actions workflow (`.github/workflows/ci.yml`) validating backend tests (`mvn clean test`), frontend build and lint (`npm run lint`, `npm run build`), and mobile analysis and tests (`flutter analyze`, `flutter test`).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Unified UUID User Identity | Reconcile dual `users.id` (Long) / `profiles.id` (UUID) to single UUID user identity across all JPA entities and DB foreign keys | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Clean Flyway Migrations | Consolidate and fix Flyway migrations so clean databases initialize from V1 without errors | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Custom Exception Hierarchy | Global exception handling with `ConflictException`, `ResourceNotFoundException`, `BusinessException`, returning RFC 7807 `ErrorResponse` | M1 | ORIGINAL_REQUEST §R3 |
| 4 | Auth Rate Limiting | Bucket4j brute-force protection filter on `/api/auth/**` returning HTTP 429 Too Many Requests | M1 | ORIGINAL_REQUEST §R3 |
| 5 | Cloudinary Inspection Photo Upload | Multipart photo upload endpoint in backend for mechanic inspection cards | M1 | ORIGINAL_REQUEST §R3 |
| 6 | Actuator Health Checks | Configure `/actuator/health` reporting DB and service status for container orchestration | M1 | ORIGINAL_REQUEST §R3 |
| 7 | Persistent AgentService State | Replace in-memory `ConcurrentHashMap` conversation history with database persistence | M1 | ORIGINAL_REQUEST §R3 |
| 8 | Concurrency Control & Slot Locking | Pessimistic row locking (`@Lock(LockModeType.PESSIMISTIC_WRITE)`) and partial unique index on appointment slots preventing double bookings | M2 | ORIGINAL_REQUEST §R3 |
| 9 | Async Transactional Event Listeners | `@Async` + `@TransactionalEventListener(AFTER_COMMIT)` for inter-module events (`AppointmentCreatedEvent`, `PaymentCompletedEvent`, `RepairStatusChangedEvent`) with non-blocking error handling | M2 | ORIGINAL_REQUEST §R3 |
| 10 | STOMP WebSocket Messaging | Spring Boot STOMP broker at `/api/ws` broadcasting repair and appointment chat messages | M2 | ORIGINAL_REQUEST §R1 |
| 11 | Web Client Consolidation | Merge `admin-frontend` into `frontend` under `/admin/*`, configure `AdminGuard` and code-split lazy loading | M3 | ORIGINAL_REQUEST §R2 |
| 12 | Decommission `admin-frontend` | Remove duplicate `/admin-frontend` codebase and update Docker Compose and dev scripts | M3 | ORIGINAL_REQUEST §R2 |
| 13 | Mobile PostgREST Elimination | Replace all direct Supabase PostgREST queries in `customer_app` and `mechanic_app` with Spring Boot REST endpoints | M4 | ORIGINAL_REQUEST §R1 |
| 14 | Mobile Codebase Health & Test Fixes | Fix `mechanic_app` compilation errors, `customer_app` widget test initialization, and `shared_core` deprecations | M4 | ORIGINAL_REQUEST §R1, R4 |
| 15 | Backend Automated Test Suite | Comprehensive JUnit 5 + Mockito + Testcontainers test suite in `backend/src/test` covering auth, booking, and concurrency | M5 | ORIGINAL_REQUEST §R4 |
| 16 | GitHub Actions CI/CD Workflow | `.github/workflows/ci.yml` validating backend `mvn test`, frontend `npm run build`, and mobile `flutter test` | M5 | ORIGINAL_REQUEST §R4 |
| 17 | E2E & Adversarial Hardening | Validate 100% E2E test suite and execute Tier 5 adversarial verification | M6 | ORIGINAL_REQUEST Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Backend Identity, Flyway & Core Services | UUID user identity reconciliation, Flyway migrations, custom exceptions, rate limiting, Cloudinary photo upload, Actuator health, AgentService persistence | none | DONE |
| M2 | Concurrency Control & Event-Driven Architecture | Slot pessimistic locking & database constraints, async transactional event dispatching, STOMP chat broadcasting | M1 | DONE |
| M3 | Web Client Consolidation | Migrate admin components to `/frontend/src/pages/admin/*`, configure `AdminGuard`, lazy-load `/admin/*`, update Compose/scripts, delete `/admin-frontend` | none | DONE |
| M4 | Mobile Apps API Migration | Eliminate direct PostgREST calls in `customer_app`, `mechanic_app`, `shared_core`, integrate with Spring Boot REST/WS, fix compilation and tests | M1, M2 | DONE |
| M5 | Test Suite & CI/CD Pipeline | JUnit 5 + Mockito + Testcontainers integration tests in `backend/src/test`, GitHub Actions `.github/workflows/ci.yml` | M1, M2, M3, M4 | DONE |
| M6 | E2E Hardening & Post-Victory Verification | Pass 100% E2E test suite (Tiers 1-4) and adversarial verification (Tier 5) across all clients and backend | M5 | DONE |

## Code Layout
- `backend/`:
  - `src/main/java/com/servio/`: Spring Boot Java source code
    - `auth/`: User entity (UUID PK), Profile, Supabase JWT auth filter, RateLimitingFilter
    - `booking/`: Appointment entity, Vehicle entity, AppointmentService (pessimistic locking), AppointmentController, VehicleController
    - `catalog/`: ServiceItem, Category entities and controllers
    - `repair/`: RepairJob, JobCardPhotoController (Cloudinary upload), RepairChatController
    - `agent/`: AgentService with DB conversation persistence
    - `event/` & `notification/`: Domain events and `@Async` `@TransactionalEventListener`
    - `common/exception/`: `ConflictException`, `ResourceNotFoundException`, `BusinessException`, `GlobalExceptionHandler`, `ErrorResponse`
  - `src/main/resources/`: `application.properties`, `db/migration/` (versioned Flyway scripts V1..V19)
  - `src/test/java/com/servio/`: JUnit 5, Mockito, and Testcontainers integration tests (117 tests)
- `frontend/`:
  - `src/`: Consolidated React SPA
    - `components/`: UI components, `AuthGuard.tsx`, `AdminGuard.tsx`, `layouts/AdminAppLayout.tsx`
    - `pages/`: Customer pages (`Home.tsx`, `Booking.tsx`, etc.) and `admin/` pages (`Dashboard.tsx`, `Appointments.tsx`, `Billing.tsx`, etc.)
    - `contexts/AuthContext.tsx`: Unified auth and role state
    - `services/`: `api.ts`, `adminApi.ts`, `billingApi.ts`, `inventoryApi.ts`
  - `vite.config.ts`, `package.json`, `nginx.conf`, `Dockerfile`
- `mobile/`:
  - `packages/shared_core/`: `ApiClient`, Supabase auth token bridge, models, theme (14 tests)
  - `apps/customer_app/`: Customer Flutter app using Spring Boot API (8 tests)
  - `apps/mechanic_app/`: Mechanic Flutter app using Spring Boot API (4 tests)
- `e2e_tests/`:
  - 4-Tier test suite (68 tests across Tiers 1-4)
- `.github/workflows/`:
  - `ci.yml`: Unified CI workflow for Backend, Frontend, and Mobile

## Interface Contracts
### Spring Boot ↔ Web / Mobile Clients
- **Auth**: `POST /api/auth/supabase-login` -> `{ success: true, data: { user: { id: UUID, email: string, role: string }, token: string } }`
- **Rate Limiting**: `429 Too Many Requests` with `Retry-After` header when threshold exceeded on `/api/auth/**`.
- **Appointments**:
  - `POST /api/appointments` -> `201 Created` or `409 Conflict` (if slot/bay occupied).
  - `GET /api/appointments/my` -> list of appointments for authenticated user.
  - `GET /api/appointments/booked-slots?date=YYYY-MM-DD` -> booked slots for date.
- **Vehicles**:
  - `GET /api/vehicles/my` -> list of vehicles for authenticated user.
  - `POST /api/vehicles/my` -> create vehicle.
- **Repair Chat**:
  - `GET /api/repairs/{id}/conversation`, `GET /api/repairs/{id}/messages`, `POST /api/repairs/{id}/messages`
  - WebSocket STOMP endpoint `/api/ws`, topic `/topic/repairs/{repairId}/messages`
- **Inspection Photos**:
  - `POST /api/repairs/{id}/job-cards/{cardId}/photos` (multipart form `file`) -> uploaded photo URL.
- **Actuator**:
  - `GET /actuator/health` -> `{ status: "UP", components: { db: { status: "UP" } } }`
