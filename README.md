# Servio

> **Vehicle Maintenance Management & Reservation Platform with Real-Time Tracking**

Servio is an enterprise-grade digital platform designed for automotive service centers. It unifies customer service discovery, appointment scheduling, real-time vehicle repair tracking, electronic billing (PayHere gateway), workshop operations, and mechanic task management across web and mobile surfaces.

---

## 🏗️ Architecture Overview

The system is built as an **authoritative modular monolith** backend with unified multi-client support:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CLIENT APPLICATIONS                              │
│  ┌──────────────────────────────┐        ┌───────────────────────────────┐  │
│  │   React 19 Web SPA (Vite)    │        │    Flutter Mobile Workspace   │  │
│  │  • Customer Portal           │        │  • customer_app (Vehicle user)│  │
│  │  • /admin/* (Lazy Loaded)    │        │  • mechanic_app (Technicians) │  │
│  └──────────────┬───────────────┘        └──────────────┬────────────────┘  │
└─────────────────┼───────────────────────────────────────┼───────────────────┘
                  │                                       │
                  │  HTTPS REST + STOMP WebSocket         │
                  └───────────────────┬───────────────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────────┐
│                    SPRING BOOT 3.3.4 AUTHORITATIVE BACKEND                   │
│                                                                             │
│  ┌─────────────────── BOUNDED CONTEXT MODULES ───────────────────────────┐  │
│  │  • auth          (Supabase JWT validation, RBAC, User/Profile UUIDs)  │  │
│  │  • booking       (Pessimistic row locking, partial unique slot index) │  │
│  │  • payment       (PayHere MD5 hash verification, invoicing, billing)  │  │
│  │  • repair        (Job cards, progress timeline, repair chat)          │  │
│  │  • admin         (Mechanics, service bays, walk-in customers)         │  │
│  │  • catalog       (Service packages, tiered pricing, promotional items)│  │
│  │  • notification  (Decoupled @Async transactional event listeners)     │  │
│  │  • agent         (Google Gemini AI assistant with persistent history) │  │
│  │  • common        (AOP audit logging, Bucket4j rate limiting, Actuator)│  │
│  └──────────────────────────────────┬────────────────────────────────────┘  │
│                                     │                                       │
│                       JPA / Hibernate / Flyway                              │
└─────────────────────────────────────┼───────────────────────────────────────┘
                                      │ JDBC over TLS
                                      ▼
                      ┌──────────────────────────────┐
                      │    PostgreSQL (Supabase)     │
                      │    Flyway Migrations V1..V20 │
                      └──────────────────────────────┘
```

---

## 📁 Repository Structure

```
Servio/
├── .github/
│   └── workflows/
│       ├── ci.yml                 # PR Continuous Integration (Backend, Frontend, Mobile)
│       └── deploy.yml             # AWS S3/CloudFront & ECR/EC2 Deployment Pipeline
├── backend/                       # Spring Boot 3.3.4 REST API & WebSocket Backend
│   ├── src/
│   │   ├── main/java/com/servio/  # Modular monolith domain packages
│   │   ├── main/resources/        # application.properties & Flyway migrations (V1..V20)
│   │   └── test/                  # 117 JUnit 5 + Mockito + Testcontainers tests
│   ├── pom.xml
│   └── Dockerfile
├── frontend/                      # Unified React 19 + TypeScript + Vite SPA
│   ├── src/
│   │   ├── components/            # UI components & route guards (AdminGuard, AuthGuard)
│   │   ├── pages/                 # Responsive customer views & lazy-loaded /admin views
│   │   └── services/              # Typed REST client & Supabase auth wrapper
│   ├── package.json
│   └── Dockerfile
├── mobile/                        # Flutter Workspace (Riverpod, Melos, Shared Core)
│   ├── apps/
│   │   ├── customer_app/          # Mobile app for vehicle owners
│   │   └── mechanic_app/          # Mobile app for workshop mechanics/supervisors
│   ├── packages/
│   │   └── shared_core/           # Domain models, ApiClient, theme, and shared widgets
│   ├── pubspec.yaml
│   └── melos.yaml
├── database/                      # Historical SQL migrations and seed datasets
│   └── seeds/                     # Catalog service and option CSV seed files
├── docs/                          # Architecture specs and operational guides
│   ├── AWS_HOSTING_GUIDE.md       # AWS deployment manual (EC2, S3, CloudFront, ECR)
│   ├── servio_srs.md              # IEEE 830 Software Requirements Specification
│   ├── implementation_plan.md     # Architecture completion roadmap
│   ├── services_reference.md      # Automotive service catalog data dictionary
│   └── infrastructure/            # S3 / CloudFront bucket security policies
├── e2e_tests/                     # Master 4-Tier requirement-driven test harness
│   └── run_e2e.sh
├── scripts/                       # Developer convenience shell scripts
│   ├── run-backend.sh             # Launch backend locally with Java 17 & env loader
│   ├── run-frontend.sh            # Launch Vite frontend locally
│   ├── docker-build.sh            # Build Docker containers with error retries
│   ├── docker-fix.sh              # Reset and rebuild Docker cache
│   └── setup-local.sh             # Check local dev environment prerequisites
├── docker-compose.yml             # Full-stack local orchestration (Backend + Frontend)
├── docker-compose.prod.yml        # Production EC2 orchestration (Backend only)
├── .env.example                   # Environment variable template
└── README.md                      # Project documentation portal
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| **Java** | 17 LTS (or 21 LTS) | Backend development (`[17, 22)` enforced by Maven) |
| **Maven** | 3.9+ | Backend build management |
| **Node.js & npm** | 20+ / npm 10+ | Frontend web development |
| **Flutter SDK** | 3.24+ | Mobile application development |
| **Docker & Compose** | Latest | Containerized execution |

> [!IMPORTANT]
> **Java Version Requirement**: The backend requires **JDK 17** or **JDK 21**. If your system default Java is newer (e.g. Java 22 or 25), use `./scripts/run-backend.sh` (which automatically discovers and configures Java 17) or explicitly set `JAVA_HOME` before running `mvn`.

### 1. Environment Configuration

Copy the sample environment file to `.env`:

```bash
cp .env.example .env
```

Open `.env` and configure your database and third-party service credentials:
- **Supabase**: `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_JWT_SECRET`
- **PayHere**: `PAYHERE_MERCHANT_ID`, `PAYHERE_MERCHANT_SECRET`, `PAYHERE_SANDBOX`
- **Cloudinary**: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- **Gemini AI**: `GEMINI_API_KEY`, `GEMINI_MODEL`

---

### 2. Running with Docker Compose (Fastest)

To run the complete full-stack environment (Spring Boot backend + Nginx-hosted React frontend):

```bash
docker-compose up --build
```

- **Frontend Web Portal**: [http://localhost](http://localhost) (Customer portal and `/admin` panel)
- **Backend API**: [http://localhost:3001](http://localhost:3001)
- **Swagger / OpenAPI Documentation**: [http://localhost:3001/swagger-ui.html](http://localhost:3001/swagger-ui.html)
- **Actuator Health Check**: [http://localhost:3001/actuator/health](http://localhost:3001/actuator/health)

To stop all containers:
```bash
docker-compose down
```

---

### 3. Running Locally (Development Mode)

#### Backend (Spring Boot)
Recommended method (automatically detects JDK 17 and loads `.env`):
```bash
./scripts/run-backend.sh
```

Or manually running with Maven (ensure JDK 17/21 and `.env` variables are active):
```bash
# macOS: point to JDK 17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
cd backend && mvn spring-boot:run
```

#### Frontend (React / Vite)
```bash
./scripts/run-frontend.sh
# Or directly:
cd frontend && npm install && npm run dev
```
Accessible at [http://localhost:5173](http://localhost:5173).

#### Mobile Apps (Flutter)
```bash
# Customer App
cd mobile/apps/customer_app
flutter pub get
flutter run

# Mechanic App
cd mobile/apps/mechanic_app
flutter pub get
flutter run
```

---

## 🧪 Testing & Verification

The project enforces high-fidelity automated verification across every layer:

### Backend Unit & Integration Tests (117 Tests)
Includes pessimistic concurrency locking tests (20 simultaneous threads attempting to book the same slot):
```bash
cd backend && mvn clean test
```

### Web Frontend Lint & Build
```bash
cd frontend && npm run lint && npm run build
```

### Mobile Analysis & Tests (26 Tests)
```bash
cd mobile/packages/shared_core && flutter test
cd ../../apps/customer_app && flutter test
cd ../mechanic_app && flutter test
```

### Master 4-Tier End-to-End Test Suite (68 Tests)
Executes feature coverage, boundary & concurrency, cross-feature flows, and real-world scenarios:
```bash
./e2e_tests/run_e2e.sh
```

---

## 🔒 Security & Best Practices

- **Zero Direct PostgREST Queries**: Mobile apps route 100% of data modifications through the Spring Boot API, guaranteeing business rules and audit logs are evaluated centrally.
- **Pessimistic Concurrency Locking**: Appointment slot allocations are guarded by database-level partial unique indexes (`uq_appointment_active_slot`) and `@Lock(LockModeType.PESSIMISTIC_WRITE)`.
- **Brute-Force Rate Limiting**: Bucket4j filter protects `/api/auth/**` against automated credential stuffing.
- **Asynchronous Event Isolation**: Background notifications and dispatches execute with `@Async` decoupled from HTTP transactions.
- **No Tracked Secrets**: All sensitive keys, tokens, and credentials are strictly externalized to `.env` and ignored by version control.

---

## 🛠️ Troubleshooting & FAQs

### 1. `Unsupported Java version. Use JDK 17 or JDK 21 for backend builds.`
- **Cause**: The active Java version in your current shell session is outside `[17, 22)` (e.g., Java 25 or Java 11).
- **Fix**: Run the launch script directly (`./scripts/run-backend.sh`), which automatically searches and configures an installed JDK 17. Alternatively, set `JAVA_HOME` explicitly:
  ```bash
  # macOS
  export JAVA_HOME=$(/usr/libexec/java_home -v 17)
  ```

### 2. `FlywayValidateException: Migration checksum mismatch for migration version X`
- **Cause**: An already-applied Flyway migration file in `src/main/resources/db/migration/` was modified locally, altering its CRC32 checksum.
- **Fix**: Avoid modifying migration scripts once they have run against a persistent database. New database changes should always be placed into a new sequential migration script (e.g. `V21__...`).

### 3. Database Connection Issues
- **Cause**: Missing or incorrect database credentials in `.env`.
- **Fix**: Verify `backend/.env` or the root `.env` contains valid Supabase database credentials (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSLMODE=require`).

---

## 📖 Key Documentation

- [Software Requirements Specification (SRS)](docs/servio_srs.md)
- [AWS Production Hosting Guide](docs/AWS_HOSTING_GUIDE.md)
- [Service Catalog Reference](docs/services_reference.md)
- [Architecture Implementation Plan](docs/implementation_plan.md)

