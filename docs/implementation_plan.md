# Servio — Microservice Architecture Completion Plan

## Executive Summary

After thoroughly exploring your codebase, I need to give you an **honest, senior architect's assessment** before we proceed. Let me break down what exists, what's missing, and whether microservices are the right call.

---

## Current State Analysis

### What's Built (Solid Foundation)

Your monolith is **surprisingly well-structured** for a Phase 1 delivery:

| Layer | Count | Status |
|-------|-------|--------|
| REST Controllers | 25 | ✅ Functional |
| Service Classes | 26 | ✅ Business logic separated |
| JPA Entities | 44 | ✅ Rich domain model |
| Repositories | 33 | ✅ Spring Data JPA |
| DTOs | 53+ | ✅ Clean API contracts |
| DB Tables | 20+ | ✅ Indexed, constrained, triggered |
| Frontend Pages | 15 customer + 12 admin | ✅ React/Vite SPA |
| Mobile App | Flutter with Riverpod | ✅ Feature-first structure |

### What's Missing for a Real-World Production System

> [!CAUTION]
> These are **critical gaps** that exist regardless of architecture choice (monolith or microservice):

1. **Zero unit tests** — No test suite exists anywhere in the backend
2. **No API documentation** — No Swagger/OpenAPI specs
3. **No audit logging** — Financial transactions (PayHere) have no audit trail
4. **No rate limiting** — APIs are wide open to abuse
5. **No centralized error handling** — Only a basic `GlobalExceptionHandler`
6. **No data validation beyond basic `@Valid`** — Business rule validation is thin
7. **No environment profile separation** — Only `application.properties` and `application-dev.properties`
8. **No CI/CD pipeline** — No GitHub Actions, no automated build
9. **No monitoring** — No Actuator, no Prometheus, no health checks beyond `/api/health`
10. **No database migration tool** — Raw SQL scripts instead of Flyway/Liquibase
11. **Hardcoded business rules** — Time slots (9AM-6PM, 30-min), currency (LKR) are baked into frontend code
12. **No email/SMS integration** — Notifications are in-app only (no dispatch)

---

## ⚠️ The Microservice Question: My Honest Recommendation

> [!IMPORTANT]
> **For 100-200 customers/month, a microservice architecture is over-engineering.** Here's why:

### The Math

| Metric | Your Scale | Microservice Threshold |
|--------|-----------|----------------------|
| Monthly users | 100-200 | 10,000+ |
| Concurrent requests | ~5-10 peak | 500+ sustained |
| Team size needed for microservices | 3-5 devs minimum | You likely have 1-3 |
| Infra cost (microservices on AWS) | ~$300-500/mo | vs ~$50-100/mo monolith |
| Deployment complexity | 8-12 services, K8s/ECS | vs 1 Docker container |

### What I Recommend Instead: **Modular Monolith → Microservice-Ready**

This gives you:
- ✅ Clean bounded contexts (like microservices, but in one JVM)
- ✅ Can extract into true microservices later when scale demands it
- ✅ 10x simpler deployment, debugging, and operations
- ✅ Same code organization principles as microservices
- ✅ One database, no distributed transaction headaches

---

## Proposed Architecture: Production-Ready Modular Monolith

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CLIENT APPLICATIONS                                  │
│  ┌──────────────┐  ┌──────────────────┐  ┌───────────────────────────────┐ │
│  │  React Web   │  │  Flutter Mobile   │  │  Admin Panel (React /admin)   │ │
│  │     SPA      │  │  (iOS + Android)  │  │                               │ │
│  └──────┬───────┘  └────────┬─────────┘  └──────────────┬────────────────┘ │
└─────────┼──────────────────┼──────────────────────────┼──────────────────┘
          │                  │                          │
          └──────────────────┼──────────────────────────┘
                             │  HTTPS / REST + WebSocket
                    ┌────────▼─────────┐
                    │   Nginx / ALB    │  ← Rate Limiting, SSL Termination
                    │  Reverse Proxy   │
                    └────────┬─────────┘
                             │
┌────────────────────────────▼────────────────────────────────────────────────┐
│                 SPRING BOOT MODULAR MONOLITH                                 │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  CROSS-CUTTING CONCERNS (Shared Infrastructure)                      │    │
│  │  ┌────────────┐ ┌─────────────┐ ┌──────────┐ ┌──────────────────┐  │    │
│  │  │ Security   │ │ Audit Log   │ │ API Docs │ │ Exception Handler│  │    │
│  │  │ (JWT+RBAC) │ │ (Events)    │ │(OpenAPI) │ │ (Global)         │  │    │
│  │  └────────────┘ └─────────────┘ └──────────┘ └──────────────────┘  │    │
│  │  ┌────────────┐ ┌─────────────┐ ┌──────────┐ ┌──────────────────┐  │    │
│  │  │ Rate Limit │ │ Correlation │ │ Caching  │ │ Health/Metrics   │  │    │
│  │  │ (Bucket4j) │ │ ID (MDC)    │ │(Caffeine)│ │ (Actuator)       │  │    │
│  │  └────────────┘ └─────────────┘ └──────────┘ └──────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌───────────────────── BOUNDED CONTEXTS (Modules) ──────────────────────┐ │
│  │                                                                        │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐  │ │
│  │  │  AUTH MODULE     │  │ BOOKING MODULE  │  │  PAYMENT MODULE      │  │ │
│  │  │  ─────────────   │  │  ─────────────  │  │  ──────────────────  │  │ │
│  │  │  AuthController  │  │  AppointmentCtl │  │  PayHereController   │  │ │
│  │  │  AuthService     │  │  AppointmentSvc │  │  BillController      │  │ │
│  │  │  User entity     │  │  Appointment    │  │  PayHereService      │  │ │
│  │  │  Profile entity  │  │  ServiceRecord  │  │  BillService         │  │ │
│  │  │  UserRepository  │  │  Vehicle        │  │  Payment entity      │  │ │
│  │  │                  │  │  Review         │  │  Bill entity         │  │ │
│  │  └─────────────────┘  └─────────────────┘  └──────────────────────┘  │ │
│  │                                                                        │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐  │ │
│  │  │  REPAIR MODULE  │  │  ADMIN MODULE   │  │  NOTIFICATION MODULE │  │ │
│  │  │  ─────────────  │  │  ─────────────  │  │  ──────────────────  │  │ │
│  │  │  RepairJobCtl   │  │  AdminStaffCtl  │  │  NotificationCtl     │  │ │
│  │  │  RepairJobSvc   │  │  AdminApptCtl   │  │  NotificationSvc     │  │ │
│  │  │  JobCardSvc     │  │  MechanicSvc    │  │  ReminderScheduler   │  │ │
│  │  │  RepairProgress │  │  ServiceBaySvc  │  │  (Future: Email/SMS) │  │ │
│  │  │  RepairChat     │  │  WalkInSvc      │  │                      │  │ │
│  │  │  RepairActivity │  │  InventorySvc   │  │                      │  │ │
│  │  └─────────────────┘  └─────────────────┘  └──────────────────────┘  │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  DATA ACCESS LAYER                                                    │    │
│  │  Spring Data JPA + Hibernate + Flyway Migrations                      │    │
│  └──────────────────────────────┬──────────────────────────────────────┘    │
└─────────────────────────────────┼────────────────────────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │  PostgreSQL (Supabase)     │
                    │  + Redis (optional cache)  │
                    └───────────────────────────┘
```

---

## Detailed Implementation Plan

### Phase 1: Foundation Hardening (Week 1-2) — Make It Production-Worthy

#### 1.1 Database Migrations with Flyway

> [!IMPORTANT]
> Replace raw SQL scripts with versioned Flyway migrations. This is non-negotiable for production.

##### [MODIFY] [pom.xml](file:///Users/chamindu/Documents/GitHub/Servio/backend/pom.xml)
- Add Flyway dependency, SpringDoc OpenAPI, Actuator, Bucket4j, Caffeine cache

##### [NEW] `src/main/resources/db/migration/V1__init_schema.sql`
- Convert existing `database/init.sql` into Flyway migration V1

##### [NEW] `src/main/resources/db/migration/V2__admin_migration.sql` through `V8__*.sql`
- Convert each existing migration SQL file into versioned Flyway migrations

---

#### 1.2 Global Exception Handling & API Standardization

##### [MODIFY] [GlobalExceptionHandler.java](file:///Users/chamindu/Documents/GitHub/Servio/backend/src/main/java/com/servio/controller/GlobalExceptionHandler.java)
- Comprehensive exception handling with proper HTTP status codes
- Standardized error response body: `{timestamp, status, error, message, path, traceId}`
- Handle: `ConstraintViolation`, `MethodArgumentNotValid`, `DataIntegrity`, `AccessDenied`, `AuthenticationException`, custom business exceptions

##### [NEW] `src/main/java/com/servio/exception/BusinessException.java`
##### [NEW] `src/main/java/com/servio/exception/ResourceNotFoundException.java`
##### [NEW] `src/main/java/com/servio/exception/ConflictException.java`
##### [NEW] `src/main/java/com/servio/exception/PaymentException.java`
- Custom exception hierarchy for proper error classification

---

#### 1.3 API Documentation (OpenAPI/Swagger)

##### [NEW] `src/main/java/com/servio/config/OpenApiConfig.java`
- SpringDoc OpenAPI configuration
- API grouping by module (Auth, Booking, Repair, Admin, Payment)
- Security scheme definition (JWT Bearer)

##### [MODIFY] All 25 controllers
- Add `@Operation`, `@ApiResponse`, `@Tag` annotations

---

#### 1.4 Audit Logging

##### [NEW] `src/main/java/com/servio/audit/AuditLog.java` (Entity)
##### [NEW] `src/main/java/com/servio/audit/AuditLogRepository.java`
##### [NEW] `src/main/java/com/servio/audit/AuditAspect.java`
- AOP-based audit logging for all state-changing operations
- Captures: who, what, when, IP address, old/new values
- Critical for PayHere payment reconciliation and admin actions

---

#### 1.5 Monitoring & Health Checks

##### [NEW] `src/main/java/com/servio/config/ActuatorConfig.java`
- Spring Boot Actuator with custom health indicators
- Database health, PayHere connectivity, Supabase reachability
- Prometheus metrics endpoint for monitoring

##### [MODIFY] `application.properties`
- Configure Actuator endpoints, info, metrics

---

### Phase 2: Code Reorganization into Modules (Week 2-3)

#### 2.1 Package Restructuring

Reorganize from flat package structure to bounded-context modules:

```
com.servio
├── common/                          # Shared kernel
│   ├── config/                      # SecurityConfig, CorsConfig, etc.
│   ├── exception/                   # Exception hierarchy
│   ├── audit/                       # Audit logging
│   ├── dto/                         # Shared DTOs (ApiResponse, etc.)
│   └── util/                        # JwtTokenProvider, etc.
│
├── auth/                            # AUTH BOUNDED CONTEXT
│   ├── controller/AuthController.java
│   ├── service/AuthService.java
│   ├── entity/User.java, Profile.java
│   ├── repository/UserRepository.java, ProfileRepository.java
│   └── dto/SignupRequest, LoginRequest, AuthResponse, etc.
│
├── booking/                         # BOOKING BOUNDED CONTEXT
│   ├── controller/AppointmentController.java
│   ├── service/AppointmentService.java, VehicleService.java
│   ├── entity/Appointment.java, Vehicle.java, ServiceRecord.java, Review.java
│   ├── repository/AppointmentRepo, VehicleRepo, ReviewRepo
│   └── dto/AppointmentDto, VehicleDto, etc.
│
├── payment/                         # PAYMENT BOUNDED CONTEXT
│   ├── controller/PayHereController.java, BillController.java
│   ├── service/PayHereService.java, BillService.java
│   ├── entity/Payment.java, Bill.java, BillItem.java
│   ├── repository/PaymentRepo, BillRepo
│   └── dto/PaymentDto, PayHereInitiateRequest, etc.
│
├── repair/                          # REPAIR BOUNDED CONTEXT
│   ├── controller/RepairJobController, RepairProgressController, RepairChatController
│   ├── service/RepairJobService, RepairProgressService, RepairChatService, etc.
│   ├── entity/RepairJob, RepairProgress, RepairActivity, RepairPart, etc.
│   ├── repository/RepairJobRepo, RepairProgressRepo, etc.
│   └── dto/RepairJobDto, RepairProgressUpdateDto, etc.
│
├── admin/                           # ADMIN BOUNDED CONTEXT
│   ├── controller/AdminAppointmentController, AdminMechanicController, etc.
│   ├── service/MechanicService, ServiceBayService, WalkInCustomerService, etc.
│   ├── entity/Mechanic, ServiceBay, WalkInCustomer, JobCard, etc.
│   ├── repository/MechanicRepo, ServiceBayRepo, etc.
│   └── dto/MechanicDto, ServiceBayDto, JobCardDto, etc.
│
├── notification/                    # NOTIFICATION BOUNDED CONTEXT
│   ├── controller/NotificationController.java
│   ├── service/NotificationService.java, AppointmentReminderScheduler.java
│   ├── entity/Notification.java
│   ├── repository/NotificationRepository.java
│   └── dto/NotificationDto.java
│
└── inventory/                       # INVENTORY BOUNDED CONTEXT
    ├── controller/InventoryController.java
    ├── service/InventoryService.java
    ├── entity/InventoryItem.java, StockTransaction.java
    ├── repository/InventoryRepository.java
    └── dto/InventoryItemDto, etc.
```

#### 2.2 Inter-Module Communication via Spring Events

##### [NEW] `src/main/java/com/servio/common/event/AppointmentCreatedEvent.java`
##### [NEW] `src/main/java/com/servio/common/event/PaymentCompletedEvent.java`
##### [NEW] `src/main/java/com/servio/common/event/RepairStatusChangedEvent.java`

Instead of direct service-to-service calls across modules, use Spring `ApplicationEventPublisher`:
- `AppointmentService` publishes `AppointmentCreatedEvent` → `NotificationService` listens and creates notification
- `PayHereService` publishes `PaymentCompletedEvent` → `AppointmentService` updates status
- `RepairJobService` publishes `RepairStatusChangedEvent` → `NotificationService` notifies customer

This decoupling makes future microservice extraction trivial — just replace Spring Events with a message broker (RabbitMQ/Kafka).

---

### Phase 3: Production Readiness (Week 3-4)

#### 3.1 Testing Strategy

##### Unit Tests (JUnit 5 + Mockito)
- [NEW] `src/test/java/com/servio/auth/service/AuthServiceTest.java`
- [NEW] `src/test/java/com/servio/booking/service/AppointmentServiceTest.java`
- [NEW] `src/test/java/com/servio/payment/service/PayHereServiceTest.java`
- [NEW] `src/test/java/com/servio/repair/service/RepairJobServiceTest.java`
- Target: ≥80% branch coverage on all Service classes

##### Integration Tests (Spring Boot Test + Testcontainers)
- [NEW] `src/test/java/com/servio/auth/controller/AuthControllerIT.java`
- [NEW] `src/test/java/com/servio/booking/controller/AppointmentControllerIT.java`
- [NEW] `src/test/java/com/servio/payment/controller/PayHereControllerIT.java`
- Use Testcontainers for PostgreSQL to test with real DB

##### Concurrent Booking Test
- [NEW] `src/test/java/com/servio/booking/ConcurrentBookingIT.java`
- Validate REQ-3.7: 10 simultaneous requests for same slot → only 1 succeeds, rest get 409

#### 3.2 CI/CD Pipeline

##### [NEW] `.github/workflows/ci.yml`
```yaml
# Build → Test → SonarQube → Docker build → Push to registry
# On PR: build + test
# On merge to main: build + test + Docker push + deploy
```

##### [NEW] `.github/workflows/deploy.yml`
- Deploy to AWS ECS / EC2 with Docker Compose

#### 3.3 Rate Limiting

##### [NEW] `src/main/java/com/servio/common/ratelimit/RateLimitConfig.java`
- Bucket4j rate limiting per endpoint group:
  - Auth endpoints: 5 requests/minute per IP (brute force protection)
  - Booking: 10 requests/minute per user
  - General API: 60 requests/minute per user

#### 3.4 Caching

##### [NEW] `src/main/java/com/servio/common/cache/CacheConfig.java`
- Caffeine in-memory cache for:
  - Service catalog (TTL: 5 min) — services don't change frequently
  - Booked slots (TTL: 30 sec) — semi-fresh data acceptable
  - Dashboard stats (TTL: 1 min)

---

### Phase 4: Missing Business Features (Week 4-6)

#### 4.1 Email/SMS Notification Dispatch

##### [NEW] `src/main/java/com/servio/notification/dispatch/EmailDispatcher.java`
##### [NEW] `src/main/java/com/servio/notification/dispatch/SmsDispatcher.java`
- Integrate with a provider (e.g., SendGrid for email, Dialog/Mobitel SMS gateway for Sri Lanka)
- Dispatch on: appointment confirmation, payment success, repair status change, reminders

#### 4.2 WebSocket Real-Time Updates (Phase 2 from SRS)

##### [MODIFY] `WebSocketConfig.java` — Already exists but needs full implementation
##### [NEW] `src/main/java/com/servio/common/websocket/AppointmentWebSocketHandler.java`
- STOMP over SockJS for:
  - Real-time appointment status updates to customers
  - Live job card updates to mechanics
  - Admin dashboard live counters

#### 4.3 Report Generation

##### [NEW] `src/main/java/com/servio/admin/report/ReportService.java`
##### [NEW] `src/main/java/com/servio/admin/report/ReportController.java`
- Export appointments, revenue, service records to CSV/Excel
- Daily/weekly/monthly revenue reports

#### 4.4 Image Upload (Cloud Storage)

##### [NEW] `src/main/java/com/servio/common/storage/CloudStorageService.java`
- Integrate with AWS S3 or Cloudinary (already partially used via `StaffCloudinaryService`)
- Job card before/after photos, repair images

---

## If You Still Want True Microservices (Future Phase)

When you hit **1000+ customers/month** or have a **5+ person dev team**, extract modules into services:

```
┌──────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY                                    │
│              (Spring Cloud Gateway or Kong)                           │
│   - JWT validation   - Rate limiting   - Load balancing              │
│   - Request routing  - Circuit breaker - SSL termination             │
└───────┬──────────┬──────────┬──────────┬──────────┬─────────────────┘
        │          │          │          │          │
   ┌────▼────┐ ┌──▼───┐ ┌───▼───┐ ┌───▼────┐ ┌──▼──────────┐
   │ Auth    │ │Booking│ │Payment│ │ Repair │ │Notification │
   │Service  │ │Service│ │Service│ │Service │ │  Service    │
   │(port    │ │(port  │ │(port  │ │(port   │ │(port 8084) │
   │ 8080)   │ │ 8081) │ │ 8082) │ │ 8083)  │ │             │
   └────┬────┘ └──┬───┘ └───┬───┘ └───┬────┘ └──┬──────────┘
        │         │         │         │          │
        ▼         ▼         ▼         ▼          ▼
   ┌─────────────────────────────────────────────────┐
   │         Message Broker (RabbitMQ / Kafka)        │
   │  Events: AppointmentCreated, PaymentCompleted,   │
   │          RepairStatusChanged, etc.               │
   └─────────────────────────────────────────────────┘
        │         │         │         │          │
   ┌────▼────┐ ┌──▼───┐ ┌───▼───┐ ┌───▼────┐ ┌──▼──────────┐
   │Auth DB  │ │Book  │ │Pay DB │ │Repair  │ │Notif DB     │
   │(users,  │ │DB    │ │(pay-  │ │DB      │ │(notifica-   │
   │profiles)│ │(appt,│ │ments, │ │(repair_│ │tions)       │
   │         │ │vehic)│ │bills) │ │jobs)   │ │             │
   └─────────┘ └──────┘ └───────┘ └────────┘ └─────────────┘

   + Service Discovery (Eureka / Consul)
   + Config Server (Spring Cloud Config)
   + Distributed Tracing (Zipkin / Jaeger)
   + Centralized Logging (ELK Stack)
```

The modular monolith we build in Phase 1-4 makes this extraction straightforward because:
- Each module has its own package with clear boundaries
- Inter-module communication already uses Spring Events (swap to message broker)
- Each module has its own DTOs (no shared entity leakage)

---

## Technology Additions Summary

| Category | Current | Proposed Addition |
|----------|---------|-------------------|
| DB Migrations | Raw SQL files | **Flyway** |
| API Docs | None | **SpringDoc OpenAPI 3** |
| Monitoring | None | **Spring Actuator + Micrometer** |
| Caching | None | **Caffeine (in-memory)** |
| Rate Limiting | None | **Bucket4j** |
| Testing | None | **JUnit 5 + Mockito + Testcontainers** |
| CI/CD | None | **GitHub Actions** |
| Audit Trail | None | **Custom AOP + audit_logs table** |
| Email | None | **Spring Mail (SendGrid)** |
| Cloud Storage | Partial (Cloudinary) | **Cloudinary / AWS S3** |
| Error Handling | Basic | **Custom exception hierarchy** |
| Logging | Basic | **Structured JSON logs + correlation IDs** |

---

## Estimated Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| Phase 1 | Week 1-2 | Foundation: Flyway, exceptions, OpenAPI, audit, monitoring |
| Phase 2 | Week 2-3 | Modular restructuring, Spring Events |
| Phase 3 | Week 3-4 | Tests, CI/CD, rate limiting, caching |
| Phase 4 | Week 4-6 | Email/SMS, WebSocket, reports, cloud storage |
| Phase 5 (Future) | When scale demands | True microservice extraction |

---

## Open Questions

> [!IMPORTANT]
> Please clarify these before we begin implementation:

1. **Deployment target** — Are you deploying to AWS (EC2/ECS), DigitalOcean, or another cloud? This affects CI/CD and infra setup.

2. **Email/SMS provider** — Do you have a preferred provider for Sri Lanka? (e.g., Dialog SMS API, Mobitel, or international like Twilio?)

3. **Domain & SSL** — Do you have a production domain name and SSL certificate plan?

4. **Spring Boot version** — Current is 3.1.5. Shall we upgrade to 3.3.x or 3.4.x for latest security patches?

5. **Budget for external services** — Supabase Pro ($25/mo), SendGrid (free tier), monitoring tools — what's the budget envelope?

6. **Do you agree with the modular monolith approach?** Or do you specifically need true microservices for academic/demonstration purposes?

7. **Phase priority** — Should I start with Phase 1 (foundation hardening) or jump to Phase 2 (code restructuring) first?

---

## Verification Plan

### Automated Tests
- `mvn test` — Unit tests with ≥80% coverage
- `mvn verify` — Integration tests with Testcontainers
- Concurrent booking stress test
- PayHere webhook security test

### Manual Verification
- Flyway migrations run cleanly on fresh database
- OpenAPI documentation accessible at `/swagger-ui.html`
- Actuator health endpoint returns comprehensive status
- Rate limiting blocks excessive requests
- Audit log captures all payment-related mutations
