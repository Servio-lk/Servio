# Software Requirements Specification (SRS)

## Servio — Vehicle Maintenance Management and Reservation System with Real-Time Tracking

**Version:** 1.0  
**Date:** April 14, 2026  
**Status:** Final Draft

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [Functionality Requirements](#3-functionality-requirements)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [Other Requirements](#5-other-requirements)
6. [System Architecture](#6-system-architecture)
7. [Appendix A: Glossary](#appendix-a-glossary)
8. [Appendix B: Analysis Models](#appendix-b-analysis-models)
9. [Appendix C: To Be Determined List](#appendix-c-to-be-determined-list)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) document describes the complete functional and non-functional requirements of **Servio** — a Vehicle Maintenance Management and Reservation System with Real-Time Tracking. The document covers the full software ecosystem including:

- A **Customer-facing React Web Application** (SPA), enabling online service discovery, booking, and payment.
- A **Cross-Platform Flutter Mobile Application** (iOS/Android), serving customers, mechanics (workers), and administrators through separate role-based navigation modules.
- A **Spring Boot REST API Backend**, providing a centralized, secure data layer integrating authentication, scheduling, payment processing (PayHere gateway), repair tracking, and notification dispatch.
- A **PostgreSQL (Supabase) Relational Database**, providing persistent storage across all entities.

This document is grounded in the actual source code residing in `/frontend`, `/backend`, `/mobile`, and `/database` directories of the Servio repository. All described features are traced directly to active controller, entity, and UI component implementations.

### 1.2 Document Conventions

- **Bold** text highlights key entities, roles, feature names, and technical terms.
- API paths are written in `monospace`, e.g., `POST /api/appointments`.
- Functional requirements are identified with the prefix **REQ-** (e.g., REQ-1).
- User stories are identified with the prefix **US-** (e.g., US-1).
- Requirement priorities are designated: **High**, **Medium**, or **Low**.
- Higher-level requirements are not assumed to inherit priority to sub-requirements; each requirement carries its own explicitly stated priority.
- Monetary values are expressed in **LKR** (Sri Lankan Rupees), as confirmed by source code.
- "The System" refers to the Servio software platform as a whole.

### 1.3 Intended Audience and Reading Suggestions

| Audience | Relevant Sections |
|---|---|
| **Backend Developers** | §2.1 (Interfaces), §3 (System Features), §6 (Architecture) |
| **Frontend / Mobile Developers** | §2.3 (User Classes), §3 (System Features), §5.3 (User Interfaces) |
| **Testers / QA** | §3 (Functional Requirements), §4 (Non-Functional Requirements) |
| **Project Managers** | §1.4 (Scope), §2.2 (Functions), §2.9 (Apportioning) |
| **Stakeholders / Management** | §1.4, §2.6 (Stakeholders), §2.2 (Product Functions) |
| **Database Administrators** | §3.3 (Logical Database Requirements), §6.2 (Logical Architecture) |

**Reading Suggestion:** Start with §1.4 (Product Scope) and §2.2 (Product Functions) for a high-level overview. Developers should proceed to §3 for detailed functional requirements. Architects should focus on §6.

### 1.4 Product Scope

**Servio** is a comprehensive vehicle maintenance management and reservation platform designed for automotive service centers in Sri Lanka. The product connects vehicle owners with service center operations digitally, replacing manual scheduling with a real-time, multi-channel booking and tracking system.

**Core objectives:**

1. **Customer Convenience**: Allow registered vehicle owners to discover, book, and pay for automotive services online — via web browser or mobile app — without visiting the service center.
2. **Operational Efficiency**: Equip mechanics and service staff with mobile tools to manage their active job queues, update appointment statuses, and log service progress in real time.
3. **Administrative Control**: Provide a rich admin dashboard for managing mechanics, service bays, services, promotional offers, job cards, and appointments from a single interface.
4. **Payment Digitization**: Integrate the **PayHere** payment gateway to support secure card payments alongside traditional cash collection.
5. **Real-Time Transparency**: Keep customers informed about service progress through a notification system and public appointment status pages (accessible via QR code).

**Out of Scope (Phase 1):** Cloud-based image/video upload (AWS S3, Azure), WebSocket-based live push notifications, and advanced analytics dashboards.

### 1.5 References

| Document | Location / Source |
|---|---|
| IEEE Std 830-1998 – SRS Template | IEEE Standards |
| PayHere Payment Gateway API Documentation | https://support.payhere.lk |
| Supabase Documentation | https://supabase.com/docs |
| Spring Boot 3.x Documentation | https://docs.spring.io/spring-boot |
| Flutter 3.x Documentation | https://docs.flutter.dev |
| React + Vite Documentation | https://vitejs.dev |
| `ADMIN_COMPLETE.md`, `IMPLEMENTATION_COMPLETE.md` | `/Servio` root directory |
| `database/init.sql` | `/Servio/database/init.sql` |
| `mobile/pubspec.yaml` | `/Servio/mobile/pubspec.yaml` |

---

## 2. Overall Description

### 2.1 Product Perspective

Servio is a **new, self-contained product** developed for a specific automotive service center, not a derivative or replacement of an existing system. It introduces digital service management where manual, phone-based, and in-person processes previously existed.

The product is organized around three parallel client applications all communicating with one centralized backend API:

```
┌──────────────────────────────────────────────────────────────────┐
│                         SERVIO SYSTEM                            │
│                                                                  │
│   ┌──────────────┐    ┌──────────────┐    ┌───────────────────┐ │
│   │  React Web   │    │Flutter Mobile│    │   Admin Web Panel │ │
│   │     App      │    │     App      │    │  (React, /admin)  │ │
│   └──────┬───────┘    └──────┬───────┘    └────────┬──────────┘ │
│          │                   │                      │            │
│          └───────────────────┴──────────────────────┘            │
│                              │ HTTPS / REST API                  │
│                    ┌─────────▼──────────┐                        │
│                    │  Spring Boot API    │                        │
│                    │    (Port 3001)      │                        │
│                    └─────────┬──────────┘                        │
│                              │                                   │
│                    ┌─────────▼──────────┐                        │
│                    │  Supabase / PostgreSQL│                      │
│                    │  (Cloud Database)   │                        │
│                    └────────────────────┘                        │
│                                                                  │
│   External:  PayHere Payment Gateway (www.payhere.lk)           │
└──────────────────────────────────────────────────────────────────┘
```

#### 2.1.1 System Interfaces

| Interface | Description |
|---|---|
| **Spring Boot REST API** | Central backend server exposing JSON endpoints on port `3001`. All three client applications communicate exclusively via this interface. |
| **Supabase PostgreSQL** | Cloud-hosted relational database. The backend uses JDBC/JPA to persist all entities. Supabase also manages OAuth authentication for mobile app users. |
| **PayHere Payment Gateway** | External Sri Lankan payment processor. The system integrates with PayHere's JS SDK (web checkout popup) and receives server-to-server webhook notifications at `POST /api/payments/payhere/notify`. |
| **Supabase Auth** | Used by the Flutter mobile app for OAuth sign-in. The backend accepts Supabase JWT tokens via the `/api/auth/supabase-login` endpoint. |

#### 2.1.2 Interfaces

The system exposes three distinct user interface paradigms:

1. **Customer/Admin React Web Application**: A responsive Single-Page Application (SPA) built with React + Vite. Uses a shared App Shell (`AppLayout`) with a bottom navigation bar on mobile viewports and a top navigation bar on desktop. Supports both mobile-first and full desktop layouts detected by CSS breakpoints (`lg:` classes). The UI is optimized for Sri Lankan customers with LKR pricing and local time handling.

2. **Flutter Mobile Application**: A native cross-platform app (Android/iOS) using `go_router` for navigation. Displays three distinct layouts based on user role:
   - `/home` → **Customer** main navigation shell (Home, Services, Activity, Account tabs)
   - `/worker` → **Mechanic** dashboard showing their assigned active job queue
   - `/admin` → **Admin** mobile dashboard

3. **Public QR Appointment Status Page**: A publicly accessible URL (`/appointment/:id`) rendered in the web browser, accessible by scanning a QR code shown on the appointment confirmation screen. No authentication required.

#### 2.1.3 Hardware Interfaces

- **Mobile Device Camera**: The Flutter mobile application interacts with the device's native camera hardware for capturing and uploading Before/After and progress service images. This is managed via Flutter's standard image picker plugin.
- **Standard Network Adapters**: All clients require working Wi-Fi or cellular data connectivity to reach the backend API and Supabase database endpoints.
- **No specialized hardware** is used or controlled by the software (no barcode scanners, POS terminals, printers, or IoT devices).

#### 2.1.4 Software Interfaces

| Software | Version | Purpose | Interface Description |
|---|---|---|---|
| **PostgreSQL** (via Supabase) | 15.x | Primary relational data store | JPA/Hibernate ORM via JDBC. Tables defined in `database/init.sql` and subsequent migration scripts. |
| **Supabase Auth** | API v1 | OAuth social login on Flutter mobile | Supabase Flutter SDK (`supabase_flutter ^2.0.0`). JWT tokens exchanged with the backend via `POST /api/auth/supabase-login`. |
| **PayHere** | JS SDK + Webhook API | Online card payment processing | Frontend uses PayHere JS SDK to open a modal checkout. Backend generates secure MD5 hashes. PayHere calls `POST /api/payments/payhere/notify` asynchronously with payment result. |
| **Spring Security + JWT** | Spring Boot 3.x | Backend authentication and authorization | Custom `JwtTokenProvider` issues tokens. `JwtAuthenticationFilter` validates all incoming requests. Roles embedded in JWT claims. |
| **React + Vite** | React 18, Vite 5 | Web SPA framework | Component-based UI. API calls are made via `fetch()` wrapped in a typed `ApiService` class. |
| **Flutter + Riverpod** | Flutter 3.x, Riverpod 3.x | Cross-platform mobile framework | `flutter_riverpod` for state management. `go_router` for navigation. `supabase_flutter` for auth. |

#### 2.1.5 Communications Interfaces

- **Primary Protocol**: HTTPS/HTTP REST. All client-to-server communication uses JSON-formatted request/response payloads.
- **PayHere Webhook**: The PayHere notification endpoint (`POST /api/payments/payhere/notify`) receives `application/x-www-form-urlencoded` data — a non-JSON format required by the external gateway. MD5 signature validation is performed server-side before any data mutations.
- **WebSocket (Planned)**: The `HomePage.tsx` actively subscribes to `/topic/appointments` via `useWebSocket()` hook, indicating a STOMP WebSocket connection to receive real-time appointment updates. This infrastructure exists but the full server-side WebSocket broadcast is a Phase 2 feature.
- **Supabase Realtime**: The Flutter mobile application's use of Supabase as an auth provider leverages Supabase Realtime channels implicitly via the Flutter SDK.

#### 2.1.6 Memory Constraints

The system has no strict memory constraints imposed by the customer environment. The following practical guidelines apply:

- **Backend (Docker container)**: The Spring Boot JVM is configured to run within Docker container resource limits (typically 512MB–1GB RAM). Lazy loading (`FetchType.LAZY`) is applied on all entity relationships to minimize heap usage.
- **Frontend (Browser)**: The React SPA runs within standard browser constraints (modern browsers with 4GB+ available RAM from typical user machines).
- **Mobile App**: The Flutter mobile application targets Android and iOS devices with at least 2GB of RAM. No unusual memory-intensive operations (e.g., video encoding) are performed on-device.

#### 2.1.7 Operations

The following operational modes apply:

1. **Interactive Customer Operations (24/7)**: Customers can browse services, make bookings, and view appointment status at any time, including outside business hours. The booking system prevents double-booking by querying `booked-slots` before presenting available time slots.
2. **Interactive Admin Operations (Business Hours)**: Admins use the web dashboard to manage mechanics, services, offers, job cards, and appointments during business hours. The system does not enforce hour-based access restrictions.
3. **Interactive Worker Operations**: Mechanics use the Flutter mobile app during their working shifts to view and update their assigned job statuses in real time.
4. **Unattended Webhook Processing**: PayHere payment notifications arrive asynchronously via server-to-server POST requests. The backend processes these without user interaction, updating payment and appointment records automatically.
5. **Database Backup**: Data is hosted on Supabase, which provides automated Point-in-Time Recovery (PITR) and daily backups as part of its managed PostgreSQL offering.
6. **Deployment**: The system is containerized with Docker Compose, providing one-command startup: `docker-compose up --build`.

#### 2.1.8 Site Adaptation Requirements

Before deploying Servio, the following site-specific configuration must be completed:

1. **Environment Variables**: A `backend/.env` file must be created from `backend/.env.example` and populated with:
   - Supabase database host, port, username, password, database name
   - Supabase project URL and anonymous key
   - JWT secret key
   - PayHere Merchant ID and Merchant Secret
   - CORS allowed origins list
2. **Frontend Environment**: A `frontend/.env` file must define `VITE_API_URL`, `VITE_SUPABASE_URL`, and `VITE_SUPABASE_ANON_KEY`.
3. **Database Initialization**: The SQL scripts in `/database/` must be executed in sequence: `init.sql` → `admin-migration.sql` → `services-migration.sql` → `repair-progress-migration.sql` → `vehicles-profile-migration.sql` → `dashboard-migration.sql`. This creates all 20+ tables, indexes, and triggers.
4. **Admin User Creation**: An initial admin user must be created by running the admin migration SQL or using the `/admin-setup` web endpoint.
5. **PayHere Merchant Registration**: The service center must register for a PayHere merchant account and provide their credentials for configuration.

---

### 2.2 Product Functions

The following are the major functional clusters of the Servio system:

| # | Function Area | Description |
|---|---|---|
| 1 | **Authentication & Profiles** | User registration, login (email/password + OAuth via Supabase), JWT issuance, profile retrieval |
| 2 | **Service Catalog Management** | Browse, search, and filter available automotive services by category; view service details and pricing options |
| 3 | **Appointment Booking** | Select a service, choose an available date and time slot (with real-time slot conflict detection), select vehicle, choose payment method, and confirm |
| 4 | **Online Payment (PayHere)** | Process card payments via PayHere JS SDK modal; server-side hash generation and asynchronous webhook confirmation |
| 5 | **Appointment Management** | View personal appointment history, cancel appointments, view appointment status by QR-scannable link |
| 6 | **Vehicle Management** | Register, update, and delete personal vehicle profiles (make, model, year, license plate, VIN); link vehicles to appointments |
| 7 | **Promotional Offers** | Display active offers/discounts on the home page and offers list; admin can create and manage offers |
| 8 | **Repair Job Tracking** | Admin creates repair jobs linked to appointments; tracks status from `INITIAL_INSPECTION` through `COMPLETED` with progress percentage updates |
| 9 | **Notification System** | System creates and dispatches in-app notifications (appointment, payment, reminder, promotional) to users with read/unread tracking |
| 10 | **Worker (Mechanic) Mobile Dashboard** | Mechanics view their active appointment queue and update job status from the Flutter app |
| 11 | **Admin Dashboard** | Aggregate statistics (totals for services, appointments, customers); calendar view of appointments; management of all entities |
| 12 | **Service Records** | Historical log of services performed against each vehicle (service type, date, mileage, cost) |
| 13 | **Admin Calendar** | Visual monthly/weekly calendar displaying all appointments by date for scheduling overview |

---

### 2.3 User Classes and Characteristics

#### CUSTOMER (Primary User)
- **Description**: Registered vehicle owners using the web app or mobile app.
- **Frequency**: Regular use for booking and checking appointment status.
- **Technical Expertise**: General public; no technical background assumed.
- **Access Level**: Can manage their own data only (vehicles, appointments, notifications).
- **Key Interactions**: Browse services → Book appointment → Pay → Track repair progress → View service history.
- **Authentication**: Email/password via backend JWT, or OAuth via Supabase (Google/Facebook on mobile).

#### WORKER (Mechanic / Service Technician)
- **Description**: Employed mechanics who use the Flutter mobile app on the service floor.
- **Frequency**: Daily use during working shifts.
- **Technical Expertise**: Low to moderate; trained on the mobile app.
- **Access Level**: Can view all active appointments assigned to them; can update appointment status to `PENDING`, `CONFIRMED`, `IN_PROGRESS`, or `COMPLETED`.
- **Key Interactions**: Open Worker Dashboard → View assigned jobs → Tap "Update Status" → Select new status from a bottom sheet.
- **Authentication**: Supabase OAuth via the Flutter sign-in screen; routed to `/worker` on login.

#### ADMINISTRATOR (System Manager)
- **Description**: Service center owner or manager with full system control.
- **Frequency**: Daily use for operations management.
- **Technical Expertise**: Moderate.
- **Access Level**: Unrestricted. All API endpoints annotated with `@PreAuthorize("hasRole('ADMIN')")` or `@PreAuthorize("hasAuthority('ADMIN')")` are exclusively accessible to this role.
- **Key Interactions**: Dashboard overview → Manage services/offers → View and filter appointments in calendar → Create/assign job cards → Manage mechanics and service bays → Manage walk-in customers.
- **Authentication**: Admin role embedded in JWT; both web and mobile admin dashboards enforce role checks.

---

### 2.4 Operating Environment

| Component | Environment |
|---|---|
| **Backend API** | Java 17+, Spring Boot 3.x, embedded Apache Tomcat on port 3001. Runs on any Linux-based Docker container or macOS/Windows locally. |
| **React Web App** | Node.js 18+, Vite 5+. Serves as a static SPA. Compatible with Chrome, Safari, Firefox, and Edge (latest versions). |
| **Flutter Mobile App** | Dart SDK ^3.9.2, Flutter 3.x. Targets Android (API 21+) and iOS (12+). |
| **Database** | PostgreSQL 15.x hosted on Supabase cloud infrastructure. |
| **Containerization** | Docker 24+, Docker Compose 2.x. Full `docker-compose.yml` provided for one-command deployment of backend + frontend. |

---

### 2.5 Design and Implementation Constraints

1. **Language Requirements**: Backend strictly in Java 17+. Frontend strictly in TypeScript (React). Mobile strictly in Dart/Flutter.
2. **Database**: PostgreSQL is mandated by the use of Supabase. The ORM is Hibernate/JPA via Spring Data JPA.
3. **Authentication Protocol**: JWT Bearer tokens must be used for all protected endpoints. Token validity is 24 hours.
4. **Role Enforcement**: Every admin API endpoint must carry `@PreAuthorize("hasRole('ADMIN')")`. Frontend admin routes are wrapped in `AdminGuard`. Flutter admin routes are guarded by role checks post-login.
5. **PayHere Integration Constraint**: The `merchant_secret` must never leave the backend server. MD5 signature generation and validation happen server-side only.
6. **Webhook Security**: The PayHere `/notify` endpoint must remain publicly accessible (no JWT required), but must verify the `md5sig` hash parameter before processing any data changes.
7. **Slot Conflict Prevention**: The booking system must query the `booked-slots` endpoint before displaying available time slots and must handle race conditions via unique constraints at the database level.
8. **Lazy Loading**: All JPA entity relationships must use `FetchType.LAZY` to avoid N+1 query performance degradation.
9. **CORS**: The backend must configure CORS to allow the specific frontend origins listed in environment variables.
10. **Local Datetime Handling**: Appointment datetimes must be stored and transmitted as local time (not UTC) to prevent timezone offset errors for Sri Lanka Standard Time (UTC+5:30).

---

### 2.6 Stakeholders

| Stakeholder | Role |
|---|---|
| **Service Center Owner** | Primary beneficiary; requires full admin control and business reporting |
| **Service Technicians (Mechanics)** | Operational users; require a simple, fast mobile interface for job status updates |
| **Vehicle Owner / Customer** | End consumer; requires a frictionless booking and payment experience |
| **Development Team** | Responsible for build, deployment, and maintenance |
| **PayHere (External)** | Payment gateway partner; integration must comply with PayHere's API standard |

---

### 2.7 User Documentation

The following documentation is bundled with the repository:

| Document | Location | Purpose |
|---|---|---|
| `RUN_INSTRUCTIONS.md` | Repository root | Developer setup guide for local and Docker deployment |
| `ADMIN_PANEL_GUIDE.md` | Repository root | Admin panel usage guide |
| `ADMIN_TESTING_GUIDE.md` | Repository root | 15 comprehensive admin test cases |
| `NEW_FEATURES_GUIDE.md` | Repository root | Feature documentation and cURL API examples |
| `DATABASE_MIGRATION.md` | Repository root | SQL migration sequence and database setup |
| `FLUTTER_SETUP_GUIDE.md` | `/mobile/` | Mobile app development environment setup |
| `AUTH_TROUBLESHOOTING.md` | `/mobile/` | Authentication debugging guide |

---

### 2.8 Assumptions and Dependencies

**Assumptions:**

- The service center operates in the **Sri Lanka Standard Time** (UTC+5:30) zone.
- The service center uses **LKR (Sri Lankan Rupees)** as its sole currency.
- A stable internet connection is available at installer and customer sites.
- The service center has an active **Supabase** project and **PayHere merchant account**.
- Customer email addresses are unique across the system (enforced by database unique constraint on `users.email`).

**Constraints:**

- The system depends entirely on Supabase for cloud database hosting. Any Supabase downtime directly affects system availability.
- PayHere must be reachable for online payments; if PayHere is unavailable, only cash payments remain functional.
- The Flutter mobile app requires an active internet connection at all times — there is no offline mode.

---

### 2.9 Apportioning of Requirements

**Phase 1 (Currently Implemented):**
- Customer authentication (email/password + Supabase OAuth)
- Service catalog (browse, search, view details)
- Appointment booking and cancellation with time-slot conflict detection
- PayHere card payment integration
- Vehicle profile management
- Notification system (create, read, mark as read)
- Admin dashboard with statistics
- Admin management of services, offers, appointments, customers, mechanics, service bays, job cards, walk-in customers
- Worker mobile dashboard with job status updates
- Repair job, progress, and activity tracking APIs
- Public appointment status page (QR-accessible)
- Admin calendar view

**Phase 2 (Future Versions):**
- Cloud image upload for job card photos (AWS S3 / Azure Blob)
- Full WebSocket-based real-time push notifications to connected clients
- Analytics charts and revenue dashboards
- Mobile in-app download of service invoices/estimates
- Staff role with limited permissions (between CUSTOMER and ADMIN)
- SMS/Email notification dispatch
- Customer-facing repair progress tracking page
- Export appointments and reports to CSV/Excel

---

## 3. Functionality Requirements

### 3.1 Authentication and User Account Management

#### 3.1.1 Description and Priority

**Priority: High**

All user interactions (except public pages) require authenticated sessions. Servio supports two authentication paths: native email/password login via the Spring Boot backend, and OAuth-based login via Supabase (used by the Flutter mobile app). Both paths result in a JWT token that authorizes subsequent API requests.

#### 3.1.2 Stimulus/Response Sequences

- **Registration**: User fills name, email, phone, password → `POST /api/auth/signup` → Backend creates user record with BCrypt-hashed password → Returns JWT token + user object → Frontend stores in `localStorage`.
- **Login (Email/Password)**: User enters credentials → `POST /api/auth/login` → Backend validates password hash → Returns JWT → Frontend stores in `localStorage`.
- **Mobile OAuth Login**: User signs in via Supabase Google/Facebook → Mobile app receives Supabase access token → `POST /api/auth/supabase-login` → Backend validates Supabase token, creates/finds profile → Returns internal JWT → App uses for subsequent API calls.
- **Profile Retrieval**: `GET /api/auth/profile` with `Authorization: Bearer {token}` → Returns current user data.
- **Logout**: Frontend deletes `token` and `user` from `localStorage`; Flutter routes back to `/welcome`.

#### 3.1.3 Functional Requirements

- **REQ-1.1**: The system shall allow customers to register with full name, email, phone number, and password.
- **REQ-1.2**: The system shall enforce unique email addresses across all user accounts.
- **REQ-1.3**: The system shall hash all passwords using BCrypt before storage.
- **REQ-1.4**: The system shall issue signed JWT tokens (24-hour expiry) upon successful authentication.
- **REQ-1.5**: The system shall support OAuth sign-in via Supabase for mobile users.
- **REQ-1.6**: The system shall provide a health check endpoint (`GET /api/auth/health`) accessible without authentication.

#### 3.1.4 User Stories

| ID | User Story |
|---|---|
| **US-1.1** | As a new customer, I want to register with my email and password so that I can create a personal account. |
| **US-1.2** | As a returning customer, I want to log in with my credentials so that I can access my booking history and vehicles. |
| **US-1.3** | As a mobile user, I want to sign in with Google or Facebook via Supabase so that I don't need to create a separate password. |

#### 3.1.5 Use Case: User Registration

| Field | Details |
|---|---|
| **Use Case ID** | UC-1.1 |
| **Use Case Name** | Register New Customer Account |
| **Actors** | Customer (Guest) |
| **Description** | A new visitor registers for a Servio account using their email address and password. |
| **Preconditions** | User is not logged in. Email address is not already registered. |
| **Postconditions** | A new user record exists in the `users` table. A JWT token is issued and stored client-side. |
| **Normal Course** | 1. Customer navigates to `/signup`. 2. Fills in full name, email, phone, password. 3. Submits form. 4. System calls `POST /api/auth/signup`. 5. Backend creates user, hashes password, returns JWT. 6. Frontend stores token, redirects to `/home`. |
| **Alternative Courses** | Customer already has an account → Link to `/login` shown. |
| **Exceptions** | Duplicate email → `400 Bad Request` with "Email already registered" message. |
| **Priority** | High |
| **Frequency of Use** | Once per new customer |

#### 3.1.6 Sequence Diagram

```
Customer Browser          Frontend (App.tsx)       Spring Boot API         PostgreSQL
      │                         │                        │                     │
      │── Fill signup form ─────►│                        │                     │
      │                         │── POST /api/auth/signup►│                     │
      │                         │                        │── INSERT users ─────►│
      │                         │                        │◄─ user record ───────│
      │                         │                        │── BCrypt hash ───────│
      │                         │                        │── Generate JWT ──────│
      │                         │◄── 201 {token, user} ──│                     │
      │                         │── store localStorage ──│                     │
      │◄── Redirect /home ───────│                        │                     │
```

---

### 3.2 Service Catalog and Discovery

#### 3.2.1 Description and Priority

**Priority: High**

Customers browse the available automotive services, which are organized into categories and individual service items. Services are toggled active/inactive by admins, and only active services appear to customers.

#### 3.2.2 Stimulus/Response Sequences

- **Home Page Load**: `GET /api/services/featured` → Returns up to 4 featured active services → Displayed in Home page grid.
- **Service Discovery**: Customer navigates to `/services` → `GET /api/services` → Full list grouped by category displayed.
- **Service Detail**: Customer taps a service → `GET /api/services/{id}` → Service name, description, base price, options (e.g., oil type) displayed.
- **Search**: Customer types in search bar → `GET /api/services/search?q={query}` → Matching services displayed.
- **Active Offers**: `GET /api/services/offers` → Promotional offers shown in home page sidebar and offers section.
- **Admin Toggle**: Admin clicks "Active" badge on a service → `PATCH /api/admin/services/{id}/toggle` → `is_active` flag toggled → Service disappears from / reappears on customer-facing pages.

#### 3.2.3 Functional Requirements

- **REQ-2.1**: The system shall display only services where `is_active = true` to customers.
- **REQ-2.2**: Toggling a service's active status shall take effect immediately on the customer interface with no cache lag.
- **REQ-2.3**: Services shall support configurable price options (e.g., Lube Services: Standard Oil LKR 4,000 / Synthetic Blend LKR 5,500 / Full Synthetic LKR 7,000).
- **REQ-2.4**: The system shall support a text-based service search.
- **REQ-2.5**: Services shall have an associated image URL and category.

#### 3.2.4 User Stories

| ID | User Story |
|---|---|
| **US-2.1** | As a customer, I want to see featured services on my home page so that I can quickly find popular options. |
| **US-2.2** | As a customer, I want to search for a service by name so that I can find what I need quickly. |
| **US-2.3** | As an admin, I want to toggle a service on or off so that I can control which services appear on the customer portal without deleting them. |

#### 3.2.5 Use Case: Toggle Service Visibility

| Field | Details |
|---|---|
| **Use Case ID** | UC-2.1 |
| **Use Case Name** | Toggle Service Active/Inactive |
| **Actors** | Administrator |
| **Description** | Admin enables or disables a service from the admin panel. The change takes effect immediately for customers. |
| **Preconditions** | Admin is logged in. Service exists in the database. |
| **Postconditions** | `is_active` flag on the service is toggled. Customers see the updated service list. |
| **Normal Course** | 1. Admin navigates to `/admin/services`. 2. Clicks the green "Active" badge on a service. 3. Frontend calls `PATCH /api/admin/services/{id}/toggle`. 4. Backend toggles `is_active`. 5. Frontend updates local state. |
| **Priority** | High |

#### 3.2.6 Sequence Diagram

```
Admin Browser           AdminServices.tsx       Spring Boot API         PostgreSQL
      │                        │                       │                     │
      │── Click Active badge──►│                       │                     │
      │                        │─ PATCH /admin/services/{id}/toggle ─────────►│
      │                        │                       │── UPDATE services ──►│
      │                        │                       │◄─ updated service ───│
      │                        │◄── 200 {is_active:false} ───────────────────│
      │◄── Badge turns grey ───│                       │                     │
```

---

### 3.3 Appointment Booking System

#### 3.3.1 Description and Priority

**Priority: High**

The booking flow is the primary value delivery mechanism of Servio. It allows customers to select a service, choose date and time, specify their vehicle and payment method, and create an appointment record.

#### 3.3.2 Stimulus/Response Sequences

1. Customer lands on `/services/:id` (ServiceDetailPage) → Selects oil type or service option → Clicks "Book now".
2. Redirected to `/book/:id` (BookingPage) with service options encoded in query params.
3. **Date Selection**: Customer selects one of 7 upcoming dates (starting tomorrow).
4. **Time Slot Validation**: On each date change → `GET /api/appointments/booked-slots?date={YYYY-MM-DD}` → Already-booked slots are grayed out and un-selectable.
5. Customer selects an available time slot.
6. Customer proceeds to Checkout step → Selects vehicle (from saved vehicles or typed), confirms phone, selects payment method.
7. **Booking Confirmation**: `POST /api/appointments` → Returns appointment record with ID.
8. If Cash: navigate to `/confirmed/{id}`.
9. If PayHere Card: `POST /api/payments/payhere/initiate` → Opens PayHere JS SDK modal → On success, navigate to `/confirmed/{id}`; on dismiss/error, `POST /api/appointments/{id}/cancel`.

#### 3.3.3 Functional Requirements

- **REQ-3.1**: The system shall prevent customers from selecting an already-booked time slot.
- **REQ-3.2**: The booking form shall display 7 upcoming available dates starting from tomorrow.
- **REQ-3.3**: Each 30-minute time slot from 9:00 AM to 6:00 PM shall be individually bookable.
- **REQ-3.4**: Customers shall be able to link a saved vehicle to their appointment.
- **REQ-3.5**: The system shall support both Cash and PayHere card payment methods at booking time.
- **REQ-3.6**: If a PayHere payment is dismissed or fails, the appointment shall be automatically cancelled to release the time slot.
- **REQ-3.7**: The appointment creation endpoint shall detect duplicate bookings for the same slot and return HTTP 409 Conflict.

#### 3.3.4 User Stories

| ID | User Story |
|---|---|
| **US-3.1** | As a customer, I want to see which time slots are already booked so that I can choose an available time. |
| **US-3.2** | As a customer, I want to pay by card online so that I don't need to carry cash to my appointment. |
| **US-3.3** | As a customer, I want to select my registered vehicle at checkout so that the service center knows which vehicle to work on. |

#### 3.3.5 Use Case: Book an Appointment

| Field | Details |
|---|---|
| **Use Case ID** | UC-3.1 |
| **Use Case Name** | Book a Service Appointment |
| **Actors** | Customer |
| **Description** | A logged-in customer selects a service, date, and time slot and confirms a booking with their preferred payment method. |
| **Preconditions** | Customer is authenticated. Service is active. Selected date/time is available. |
| **Postconditions** | An `appointments` record is created with status `PENDING`. Customer is redirected to a confirmation page. |
| **Normal Course** | 1. Customer selects a service. 2. Navigates to BookingPage. 3. Selects date. System fetches booked slots. 4. Selects available time. 5. Proceeds to Checkout. 6. Selects vehicle and payment method. 7. Clicks "Confirm Booking" / "Pay Now". 8. System creates appointment. 9. Customer sees confirmation page with QR code. |
| **Exceptions** | `409 Conflict` if slot was concurrently booked by another user → Customer shown error, prompted to select another time. PayHere error → Appointment cancelled, slot released. |
| **Priority** | High |
| **Frequency of Use** | Multiple times daily |

#### 3.3.6 Sequence Diagram (PayHere Payment Path)

```
Customer Browser          BookingPage.tsx        Spring Boot API      PayHere Gateway
      │                        │                       │                     │
      │── Click "Pay Now" ────►│                       │                     │
      │                        │── POST /appointments ►│                     │
      │                        │◄── 201 {id}  ─────────│                     │
      │                        │── POST /payments/payhere/initiate ──────────►│
      │                        │◄── {hash, orderId, ...} ───────────────────  │
      │                        │── payhere.startPayment() ──────────────────  │
      │◄── PayHere Modal opens─│                       │                     │
      │── Complete payment ────│                       │◄── POST /notify ────│
      │                        │                       │── Update payment ───►│ (DB)
      │◄── onCompleted() ──────│                       │                     │
      │◄── Redirect /confirmed ─│                      │                     │
```

---

### 3.4 Vehicle Management

#### 3.4.1 Description and Priority

**Priority: High**

Customers maintain a garage of registered vehicles in their profile. These vehicles can be associated with appointments, reducing checkout friction and providing service history traceability.

#### 3.4.2 Stimulus/Response Sequences

- **View Vehicles**: `GET /api/vehicles/my` (JWT required) → List of customer's vehicles displayed in Account page.
- **Add Vehicle**: Customer fills make, model, year, license plate, optional VIN → `POST /api/vehicles/my` → Saved and displayed.
- **Update Vehicle**: `PUT /api/vehicles/{id}` → Updated.
- **Delete Vehicle**: `DELETE /api/vehicles/{id}` → Removed.
- **Vehicle Statistics**: `GET /api/vehicles/{id}/stats` → Returns service count, total spend for that vehicle.
- **At Booking**: VehicleSelector component displays saved vehicles → Customer selects one or types a vehicle name manually.

#### 3.4.3 Functional Requirements

- **REQ-4.1**: Each vehicle shall store make, model, year, license plate, and optionally VIN.
- **REQ-4.2**: A vehicle shall be linked to the authenticated user via JWT-based ownership.
- **REQ-4.3**: The system shall return per-vehicle statistics (total appointments, total spend).
- **REQ-4.4**: Service records (date, type, mileage, cost) shall be retrievable per vehicle.

#### 3.4.4 User Stories

| ID | User Story |
|---|---|
| **US-4.1** | As a customer, I want to add my car to my profile so that I can quickly select it when booking a service. |
| **US-4.2** | As a customer, I want to see my vehicle's service history so that I can track its maintenance over time. |

---

### 3.5 Payment Processing (PayHere Integration)

#### 3.5.1 Description and Priority

**Priority: High**

Servio integrates the PayHere payment gateway for secure online card payments. The system supports both Cash (offline) and Card (PayHere) payment methods chosen at checkout.

#### 3.5.2 Stimulus/Response Sequences

- **Initiation**: Frontend calls `POST /api/payments/payhere/initiate` with `{appointmentId, currency, serviceId}` → Backend generates all required PayHere form fields including MD5 hash (using merchant_secret) → Returns to frontend.
- **Checkout Modal**: Frontend opens the PayHere JS SDK modal using the returned fields. The `merchant_secret` never leaves the server.
- **Webhook**: PayHere's servers call `POST /api/payments/payhere/notify` with form-encoded payment result → Backend validates `md5sig` → On success, creates a `payments` record and updates appointment status.
- **Dismissal/Error**: Frontend `onDismissed()` / `onError()` callbacks cancel the appointment via `POST /api/appointments/{id}/cancel`.

#### 3.5.3 Functional Requirements

- **REQ-5.1**: The PayHere merchant secret shall never be transmitted to or calculated by the frontend.
- **REQ-5.2**: The system shall verify the `md5sig` parameter of every PayHere webhook before processing.
- **REQ-5.3**: Invalid or tampered webhook signatures shall be silently rejected with HTTP 400.
- **REQ-5.4**: Successful payments shall automatically create a `payments` record and update the linked appointment status.
- **REQ-5.5**: A dismissed or failed PayHere session shall trigger automatic appointment cancellation to release the booked time slot.

#### 3.5.4 User Stories

| ID | User Story |
|---|---|
| **US-5.1** | As a customer, I want to pay by card using PayHere so that I can book and pay in one step without visiting the shop. |
| **US-5.2** | As a customer, if I close the payment window, I want my time slot to be automatically released so others can book it. |

---

### 3.6 Admin Dashboard and Management

#### 3.6.1 Description and Priority

**Priority: High**

The Admin Panel (`/admin/*`) provides the service center manager with full CRUD control over all system entities. It is accessible only to users with the `ADMIN` role.

#### 3.6.2 Stimulus/Response Sequences

All admin actions follow the pattern: Admin navigates to the relevant module → Frontend calls appropriate `GET` endpoint to load data → Admin performs CRUD action → Frontend calls `POST/PUT/PATCH/DELETE` endpoint.

**Dashboard**: `GET /api/admin/services` + `GET /api/admin/appointments` + `GET /api/admin/customers` count queries → Statistics cards displayed.

**Calendar**: Admin opens `/admin/calendar` (AdminCalendar.tsx) → Appointment dates fetched and rendered on a monthly grid.

#### 3.6.3 Functional Requirements

- **REQ-6.1**: All `/api/admin/*` endpoints shall require `ADMIN` role.
- **REQ-6.2**: The admin dashboard shall display total counts of services, offers, appointments, and customers.
- **REQ-6.3**: Admin shall be able to toggle service visibility with immediate effect on the customer portal.
- **REQ-6.4**: Admin shall be able to manage (create, view, update, delete) mechanics, service bays, and walk-in customers.
- **REQ-6.5**: Admin shall be able to view and filter appointments by status (PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED).
- **REQ-6.6**: Admin shall be able to view appointments on a calendar by date.
- **REQ-6.7**: Admin shall be able to create job cards linking appointments to mechanics and service bays.

#### 3.6.4 User Stories

| ID | User Story |
|---|---|
| **US-6.1** | As an admin, I want to see all today's appointments on a calendar so that I can plan the day's workload. |
| **US-6.2** | As an admin, I want to manage my mechanics' profiles so that I can track their availability and specializations. |
| **US-6.3** | As an admin, I want to handle walk-in customers who haven't pre-booked so that their service is properly tracked. |

---

### 3.7 Job Card and Repair Tracking System

#### 3.7.1 Description and Priority

**Priority: High**

The Job Card system is the operational core of the service center. It converts an appointment into an active work order, linking it to a mechanic, service bay, and vehicle. The Repair Job subsystem provides a granular, timestamped status progression for each vehicle undergoing service.

#### 3.7.2 Stimulus/Response Sequences

- **Create Job Card**: Admin creates a job card from an appointment → Assigns mechanic and service bay → `POST /api/admin/job-cards` → Job card created with status `NEW`.
- **Add Tasks**: Admin breaks job into sequential tasks → `POST /api/admin/job-tasks` → Tasks tracked independently.
- **Add Notes**: Mechanic/admin adds diagnostic notes → `POST /api/admin/job-card-notes` (types: GENERAL, DIAGNOSIS, ISSUE_FOUND, CUSTOMER_NOTE, WARNING).
- **Attach Photos**: `POST /api/admin/job-card-photos` → Photo URL stored (types: BEFORE, DURING, AFTER, ISSUE, DIAGNOSTIC).
- **Repair Job Status**: `PATCH /api/repairs/{id}/status` → Status transitions: `INITIAL_INSPECTION → QUOTE_PROVIDED → QUOTE_APPROVED → IN_PROGRESS → AWAITING_PARTS → COMPLETED`.
- **Progress Update**: `POST /api/repairs/progress` with `repairJobId`, `status`, `progressPercentage`, `description` → Progress snapshot updated.

#### 3.7.3 Functional Requirements

- **REQ-7.1**: A job card shall be created from an existing appointment.
- **REQ-7.2**: A job card shall be assignable to a mechanic and a service bay.
- **REQ-7.3**: Job cards shall support sequential tasks with individual status tracking.
- **REQ-7.4**: Job cards shall support text notes with type categorization.
- **REQ-7.5**: Job cards shall support photo attachments with type categorization.
- **REQ-7.6**: Repair jobs shall support priority levels: LOW, NORMAL, HIGH, URGENT.
- **REQ-7.7**: Repair progress shall track a completion percentage (0–100%) alongside status.
- **REQ-7.8**: The system shall maintain a repair activity log (type: STATUS_CHANGE, NOTE, PARTS_UPDATE, ESTIMATE, ASSIGNMENT, SYSTEM).

#### 3.7.4 User Stories

| ID | User Story |
|---|---|
| **US-7.1** | As an admin, I want to create a job card for each appointment so that the mechanic has a formal work order. |
| **US-7.2** | As a mechanic, I want to attach before/after photos to the job card so that we have a visual record of the repair. |
| **US-7.3** | As an admin, I want to track repair parts (cost, supplier, delivery status) on the job card so that the invoice is accurate. |

---

### 3.8 Worker (Mechanic) Mobile Dashboard

#### 3.8.1 Description and Priority

**Priority: High**

Mechanics use the Flutter mobile application's Worker Dashboard to view and manage their active job queue without needing access to the admin web panel.

#### 3.8.2 Stimulus/Response Sequences

1. Mechanic opens the Servio mobile app → Signs in via Supabase.
2. System routes to `/worker` (WorkerDashboardScreen).
3. `activeAppointmentsProvider` fetches active appointments from the Supabase / backend.
4. Each job card displays: Job number, service type, vehicle, scheduled date and time, current status badge.
5. Mechanic taps "Update Status" → Bottom sheet displays: PENDING, CONFIRMED, IN_PROGRESS, COMPLETED.
6. Mechanic selects new status → `workerRepository.updateAppointmentStatus(id, status)` called → Provider invalidated → List refreshes.
7. Pull-to-refresh available.

#### 3.8.3 Functional Requirements

- **REQ-8.1**: The worker dashboard shall display only active (non-cancelled, non-completed) appointments.
- **REQ-8.2**: Mechanics shall be able to update appointment status via a bottom sheet picker.
- **REQ-8.3**: The list shall support pull-to-refresh.
- **REQ-8.4**: Empty state shall be shown with an appropriate message when no active jobs exist.

#### 3.8.4 User Stories

| ID | User Story |
|---|---|
| **US-8.1** | As a mechanic, I want to see my active jobs on my phone so that I know what to work on next without going to the front desk. |
| **US-8.2** | As a mechanic, I want to update a job's status from my phone so that the admin and customer are immediately informed. |

---

### 3.9 Notification System

#### 3.9.1 Description and Priority

**Priority: Medium**

An in-app notification system delivers alerts to users about their appointments, payments, and promotional offers. Notifications are displayed via a bell icon in the web navigation bar.

#### 3.9.2 Functional Requirements

- **REQ-9.1**: The system shall store notifications per user with types: APPOINTMENT, PAYMENT, REMINDER, PROMOTIONAL.
- **REQ-9.2**: Users shall be able to retrieve all notifications and filter unread ones.
- **REQ-9.3**: Users shall be able to mark individual or all notifications as read.
- **REQ-9.4**: The unread notification count shall be displayed on the notification bell icon.
- **REQ-9.5**: Old notifications (older than 30 days by default) can be bulk-deleted.

#### 3.9.3 User Stories

| ID | User Story |
|---|---|
| **US-9.1** | As a customer, I want to receive a notification when my appointment is confirmed so that I have immediate assurance. |
| **US-9.2** | As a customer, I want to see my unread notification count on the bell icon so that I don't miss important updates. |

---

### 3.10 Appointment Activity and Status Tracking

#### 3.10.1 Description and Priority

**Priority: Medium**

Customers can view all their past and upcoming appointments through the Activity Page. A public status page (accessed via QR code from the confirmation screen) shows real-time appointment status without requiring login.

#### 3.10.2 Functional Requirements

- **REQ-10.1**: `GET /api/appointments/my` shall return all appointments for the authenticated user, ordered by date.
- **REQ-10.2**: `GET /api/appointments/{id}` shall be publicly accessible for the QR-scan status page.
- **REQ-10.3**: Customers shall be able to cancel their own appointments via `POST /api/appointments/{id}/cancel` (ownership enforced).
- **REQ-10.4**: The confirmation page shall display a QR code linking to the public appointment status page.

---

### 3.11 Logical Database Requirements

The Servio PostgreSQL database is initialized via `database/init.sql` and extended by several migration scripts. All tables include `created_at` and `updated_at` timestamp columns managed by database triggers.

#### Core Tables

| Table | Key Columns | Relationships |
|---|---|---|
| `users` | `id, full_name, email (UNIQUE), phone, password_hash, role` | Parent to vehicles, appointments, payments, notifications |
| `profiles` | `id, supabase_uuid, email, full_name` | Supabase OAuth users profile |
| `vehicles` | `id, user_id, make, model, year, license_plate, vin` | Belongs to `users`; parent to `service_records`, `repair_jobs` |
| `appointments` | `id, user_id, vehicle_id, service_type, appointment_date, status` | Belongs to `users`, `vehicles`; parent to `payments`, `repair_jobs`, `job_cards` |
| `payments` | `id, appointment_id, user_id, amount, payment_method, payment_status, transaction_id` | Belongs to `appointments`, `users` |
| `service_records` | `id, vehicle_id, service_type, service_date, mileage, cost` | Belongs to `vehicles` |
| `notifications` | `id, user_id, title, message, type, is_read` | Belongs to `users` |
| `reviews` | `id, user_id, appointment_id, rating (1-5), comment` | Belongs to `users`, `appointments` |

#### Repair Tracking Tables

| Table | Key Columns | Notes |
|---|---|---|
| `repair_jobs` | `id, appointment_id, vehicle_id, user_id, title, status, priority, estimated_cost, parts_cost, labor_cost` | Status: INITIAL_INSPECTION → COMPLETED |
| `repair_progress_updates` | `id, repair_job_id, status, progress_percentage (0-100), description, technician_notes` | Multiple updates per repair job |
| `repair_progress` | `id, repair_job_id (UNIQUE), current_status, progress_percentage` | Single current-state snapshot per job |
| `repair_activities` | `id, repair_job_id, activity_type, description, performed_by_user_id` | Types: STATUS_CHANGE, NOTE, PARTS_UPDATE, ESTIMATE, ASSIGNMENT, SYSTEM |
| `repair_parts` | `id, repair_job_id, part_name, unit_cost, quantity, total_cost, status` | Parts status: PENDING, ORDERED, RECEIVED, INSTALLED |
| `repair_images` | `id, repair_job_id, image_url, image_type` | Types: DAMAGE, DURING_REPAIR, COMPLETED, INVOICE |
| `repair_estimates` | `id, repair_job_id, estimate_number (UNIQUE), estimated_total_cost, validity_days` | Status: PENDING, APPROVED, REJECTED, EXPIRED |
| `repair_history` | `id, vehicle_id, repair_job_id, repair_date, mileage_at_repair, cost` | Long-term repair archive per vehicle |

#### Admin Operations Tables (from migrations)

| Table | Purpose |
|---|---|
| `mechanics` | Mechanic profiles: specialization, status (AVAILABLE/BUSY/ON_LEAVE) |
| `service_bays` | Service bay allocation: type, status (AVAILABLE/IN_USE/MAINTENANCE/CLEANING) |
| `walk_in_customers` | Unregistered walk-in client records with optional vehicle info |
| `job_cards` | Formal work order linked to appointment, mechanic, bay |
| `job_tasks` | Subtasks within a job card |
| `job_card_notes` | Text notes on job cards (GENERAL, DIAGNOSIS, ISSUE_FOUND, etc.) |
| `job_card_photos` | Photo attachments on job cards (BEFORE, DURING, AFTER, etc.) |

#### Integrity Constraints

- `users.email` — UNIQUE constraint
- `service_bays.bay_number` — UNIQUE constraint
- `repair_estimates.estimate_number` — UNIQUE constraint
- `payments.transaction_id` — UNIQUE constraint
- `repair_progress.repair_job_id` — UNIQUE (one snapshot per job)
- `reviews.rating` — CHECK: 1 ≤ rating ≤ 5
- `repair_progress_updates.progress_percentage` — CHECK: 0 ≤ value ≤ 100
- All foreign keys enforce `ON DELETE CASCADE` or `ON DELETE SET NULL` as appropriate

---

## 4. Non-Functional Requirements

### 4.1 Performance Requirements

- **API Response Time**: Standard API endpoints shall respond within **500ms** under normal load. Booking creation with payment initiation may take up to **2 seconds**.
- **Slot Availability**: The `booked-slots` query shall execute in under **200ms** to avoid degrading the booking UX.
- **Database Query Optimization**: All frequently queried columns are indexed (e.g., `idx_appointments_status`, `idx_repair_jobs_assigned_technician`, `idx_notifications_is_read`). JPA lazy loading prevents N+1 problems.
- **Concurrent Bookings**: The system must handle concurrent booking requests for the same slot without data corruption, enforced by the `409 Conflict` response on the create appointment endpoint.

### 4.2 Safety Requirements

- **Slot Release on Payment Failure**: If a PayHere payment fails or is dismissed, the linked appointment must be automatically cancelled within the same user session to prevent a "phantom booking" from occupying a time slot indefinitely.
- **Referential Integrity**: `ON DELETE CASCADE` rules prevent orphaned repair progress records, job tasks, and notes when their parent job card is deleted.
- **Estimate Validity**: Repair estimates carry a `validity_days` field (default 7 days), after which they automatically transition to `EXPIRED` status. Approvals must be within the validity window.

### 4.3 Security Requirements

- **Authentication**: All protected endpoints validate the JWT `Authorization: Bearer {token}` header on every request via `JwtAuthenticationFilter`.
- **Authorization**: Admin role enforced with `@PreAuthorize("hasRole('ADMIN')")`. Customer authentication enforced with `@PreAuthorize("isAuthenticated()")`. Ownership of appointments (cancel) verified against JWT subject.
- **Password Security**: BCrypt with a cost factor of 10 is used for all user password storage.
- **PayHere Security**: MD5 signature (`md5sig`) validated on every webhook. Invalid signatures rejected silently (HTTP 400). `merchant_secret` stored only in backend environment variables.
- **SQL Injection Prevention**: All database queries use JPA parameterized queries via Spring Data repositories. No raw string concatenation in SQL.
- **CORS**: Backend configures Cross-Origin Resource Sharing to allow only specific frontend origins.
- **Route Guards**: Frontend uses `AdminGuard` for React admin routes and `AuthGuard` for protected customer routes. Flutter `go_router` maps roles to specific route paths.

### 4.4 Software Quality Attributes

Specify any additional quality characteristics for the product that will be important to either the customers or the developers. Some to consider are: adaptability, availability, correctness, flexibility, interoperability, maintainability, portability, reliability, reusability, robustness, testability, and usability. Write these to be specific, quantitative, and verifiable when possible. At the least, clarify the relative preferences for various attributes, such as ease of use over ease of learning.

| ID | Characteristic | H/M/L |
|---|---|---|
| 1 | Correctness | H |
| 2 | Efficiency | M |
| 3 | Flexibility | L |
| 4 | Integrity/Security | H |
| 5 | Interoperability | M |
| 6 | Maintainability | H |
| 7 | Portability | M |
| 8 | Reliability | H |
| 9 | Reusability | L |
| 10 | Testability | M |
| 11 | Usability | H |
| 12 | Availability | M |

---

#### 4.4.1 Correctness — **Priority: High**

**Justification:**  
Correctness is the highest-priority quality attribute because the system handles financial transactions (PayHere card payments in LKR), real-time slot booking, and role-based data access. Any deviation from specified behavior has direct business and financial consequences. Specifically: (a) the MD5 `md5sig` webhook signature verification (REQ-5.2) must be computed and validated without error on every PayHere notification; (b) the `booked-slots` conflict detection (REQ-3.1, REQ-3.7) must accurately reflect confirmed slot occupancy so that no two appointments occupy the same 30-minute window; (c) role authorization (`hasRole('ADMIN')`, `isAuthenticated()`) must be correctly applied across all 18 REST controllers with zero bypass surface.

**Measurable Metrics:**
- 100% of `POST /api/appointments` requests for an already-booked slot must return HTTP `409 Conflict` — verified by automated integration test suite with concurrent request simulation.
- MD5 signature verification must correctly reject 100% of tampered PayHere webhook payloads — verified by security test harness sending mutated `md5sig` values.
- 0 unauthorized data access incidents (admin endpoints returning data to non-ADMIN JWT holders) — verified by role-based penetration test against all `/api/admin/*` routes.
- Appointment datetime stored in the database must exactly match the local SLST time shown to the user — verified by regression test asserting no UTC offset shift (REQ §2.5.10).

---

#### 4.4.2 Efficiency — **Priority: Medium**

**Justification:**  
Efficiency is critical for user experience but not mission-critical for correctness or security. The booking page calls `GET /api/appointments/booked-slots` on every date change, making this a hot path that directly affects perceived responsiveness. The system uses JPA `FetchType.LAZY` on all entity relationships to prevent N+1 query problems, and indexes are defined on all high-frequency filter columns (`idx_appointments_status`, `idx_repair_jobs_assigned_technician`, `idx_notifications_is_read`). The Docker container runtime limits the JVM heap, so memory efficiency in query design is also relevant.

**Measurable Metrics:**
- `GET /api/appointments/booked-slots` must respond in ≤ 200 ms (p95) under normal single-user load — verified by load-testing tool (e.g., k6 or Apache JMeter).
- Standard CRUD API endpoints (services, vehicles, notifications) must respond in ≤ 500 ms (p95) under normal load.
- `POST /api/appointments` + `POST /api/payments/payhere/initiate` combined chain must complete in ≤ 2,000 ms (p95).
- Backend Docker container memory footprint must stay ≤ 768 MB resident set size under normal operational load.
- No database query shall perform a full-table scan on a table exceeding 1,000 rows — verified using PostgreSQL `EXPLAIN ANALYZE` on all repository methods.

---

#### 4.4.3 Flexibility — **Priority: Low**

**Justification:**  
Flexibility is lower priority because the system is purpose-built for a single service center. However, some data-driven flexibility is already implemented: service options (e.g., oil type sub-variants with independent pricing), service active/inactive toggling without code changes, and promotional offer creation. Adding a new service type or changing pricing requires only a database insert — no code deployment. Expanding the time slot schedule or currency would require code modification, as these are hardcoded in `BookingPage.tsx`.

**Measurable Metrics:**
- Adding a new service category or service item via admin panel must require 0 code deployments — verified by DBA inserting a record and confirming it appears on the customer portal within 1 page refresh.
- Toggling a service's `is_active` flag must be reflected on the customer-facing services list within 1 HTTP request cycle (no caching delay) — verified by automated UI test.
- *Assumption*: Changing operational hours (currently hardcoded as 9 AM–6 PM, 30-minute slots in `BookingPage.tsx`) requires a code change and redeployment; this is an accepted limitation of Phase 1.

---

#### 4.4.4 Integrity / Security — **Priority: High**

**Justification:**  
Security is a primary design constraint (§2.5) across all three tiers. The system processes personal data (name, phone, email, vehicle details), financial transactions (LKR payments), and sensitive role-based operations (admin panel). Multiple threat vectors are explicitly mitigated: JWT token validation on every protected request, BCrypt (cost factor 10) password hashing, MD5 webhook signature verification for PayHere, parameterized JPA queries preventing SQL injection, CORS allowlist restricting frontend origins, and route guards on both web (`AdminGuard`, `AuthGuard`) and mobile (`go_router` role routing) clients.

**Measurable Metrics:**
- 0% of admin API endpoints (`/api/admin/*`) accessible without a valid JWT bearing the `ADMIN` role — verified by automated security test suite executing requests with no token, expired tokens, and CUSTOMER-role tokens.
- BCrypt work factor must be ≥ 10 — verifiable by code review of `AuthService`.
- 100% of PayHere webhook calls with invalid `md5sig` must be rejected with HTTP `400` without any database mutation — verified by negative test suite.
- `merchant_secret` must not appear in any client-facing HTTP response body or log output — verified by static analysis and manual log audit.
- All SQL operations must use prepared statements (zero raw string SQL concatenation in any `@Repository`) — verified by static code analysis.
- JWT tokens must expire after exactly 24 hours — verified by test asserting `401 Unauthorized` on token replay after expiry.

---

#### 4.4.5 Interoperability — **Priority: Medium**

**Justification:**  
Servio must interoperate with two external systems that it does not control: Supabase (for OAuth authentication and hosted PostgreSQL) and PayHere (for payment processing). The backend exposes a standard JSON REST API that all three client applications consume identically, ensuring protocol uniformity. The PayHere webhook uses `application/x-www-form-urlencoded` (non-JSON) — an externally mandated format that the backend's `PayHereController` handles specifically. Supabase JWT tokens issued by the OAuth flow must be accepted and exchanged for internal backend JWTs via `/api/auth/supabase-login`, bridging the two authentication systems seamlessly.

**Measurable Metrics:**
- 100% of Supabase OAuth-authenticated mobile users must successfully exchange their Supabase JWT for an internal JWT via `POST /api/auth/supabase-login` without manual intervention — verified by end-to-end OAuth test flow.
- The PayHere webhook processor must correctly parse `application/x-www-form-urlencoded` payloads for 100% of incoming notifications and update the corresponding `payments` record — verified by mocked PayHere webhook integration test.
- All API request/response bodies must conform to `application/json` (RFC 7159) — verified by contract testing all 18 controllers.
- The React SPA and Flutter mobile app must be able to call the same backend endpoint for any shared data operation (e.g., `GET /api/services`) without endpoint duplication — verified by API contract review.

---

#### 4.4.6 Maintainability — **Priority: High**

**Justification:**  
Maintainability is high priority because the codebase is expected to grow into Phase 2 (WebSocket broadcast, S3 image upload, analytics, STAFF role) and the primary development team may rotate. The backend follows a strict 5-layer architecture (Controller → Service → Repository → DTO → Entity) with zero cross-layer leakage. Each of the 18 `@RestController` classes handles only request/response mapping; business logic resides exclusively in Service classes. The TypeScript-typed `ApiService` class in the frontend provides a single point of API contract maintenance. Flutter's Riverpod providers are scoped per feature directory in a feature-first package structure.

**Measurable Metrics:**
- Cyclomatic complexity of any single Service method must not exceed 10 — verifiable by static analysis (e.g., SonarQube or Checkstyle).
- All 18 REST controllers must have zero business logic (no direct repository calls, no conditional branching on entity data) — verified by code review checklist.
- Adding a new CRUD entity (e.g., a new `ServiceBayType`) must require changes to ≤ 5 files (Entity, DTO, Repository, Service, Controller) — verified by tracking changes in the next feature PR.
- All TypeScript API types must be centrally defined in `api.ts`; no inline `any` type annotations in page components — verified by TypeScript strict mode compilation.

---

#### 4.4.7 Portability — **Priority: Medium**

**Justification:**  
The system is designed to run on any environment supporting Docker 24+ and Docker Compose 2.x. The single `docker-compose up --build` command starts the full stack (Spring Boot backend + nginx-served React SPA). The Flutter mobile app targets both Android (API 21+) and iOS (12+) from a single Dart codebase. The backend has no OS-specific dependencies; it runs on Linux, macOS, and Windows via the JVM. PostgreSQL hosting is externalized to Supabase, removing infrastructure management from the deployment concern.

**Measurable Metrics:**
- `docker-compose up --build` must bring the full system to a healthy, API-responding state within 5 minutes on a machine with a clean Docker cache and a 50 Mbps internet connection — verified by CI pipeline timed run.
- The Flutter mobile APK must build and install successfully on Android API 21 (Lollipop) and above — verified by automated build matrix on Android API 21, 28, and 34.
- The Flutter mobile IPA must be buildable for iOS 12+ without platform-specific conditionals in the Dart layer — verified by Xcode build against iOS 12 simulator.
- The Spring Boot JAR must start and pass the `/api/auth/health` check on JRE 17, 21, and 22 — verified by CI matrix build.

---

#### 4.4.8 Reliability — **Priority: High**

**Justification:**  
Reliability is high priority because the system handles time-sensitive booking operations with financial implications. Unreliable behavior — such as a phantom booking (slot occupied by a failed payment), a double-booking race condition, or a lost PayHere notification — has direct impact on the service center's revenue and customer trust. The system addresses reliability through: database-level UNIQUE constraints on `transaction_id` and `repair_progress.repair_job_id`; `ON DELETE CASCADE` referential integrity rules; automatic appointment cancellation on payment failure (REQ-5.5); `updated_at` triggers on all 20+ tables; and error handling (`try-catch`) on all controller methods with well-defined error responses.

**Measurable Metrics:**
- The system must produce 0 double-booked appointments for the same time slot under concurrent load of 10 simultaneous booking requests for the same slot — verified by concurrent load test.
- Automatic appointment cancellation must trigger within 1 HTTP round-trip of a PayHere `onDismissed` or `onError` callback — verified by frontend integration test.
- Mean Time Between Failures (MTBF) for the backend API must be ≥ 720 hours (30 days) of continuous operation — tracked via uptime monitoring.
- Database referential integrity: 0 orphaned `repair_progress_updates` records after any `repair_jobs` delete — verified by database constraint test.
- `updated_at` column must reflect the actual mutation time within ±1 second for all 20+ tables — verified by trigger audit test.

---

#### 4.4.9 Reusability — **Priority: Low**

**Justification:**  
Reusability is a low priority because Servio is a purpose-built system for a single service center with no explicit requirement for component packaging or export. However, internal reusability is practiced: the `ApiService` TypeScript class is shared across all 12 page components and admin panels via a singleton instance; Flutter Riverpod providers (`activeAppointmentsProvider`, `workerRepositoryProvider`) are shared between screens; and the `AppLayout` component wraps all customer-facing pages with shared navigation chrome. The `VehicleSelector` component is reused across both `BookingPage.tsx` (mobile and desktop variants) and the Account page.

**Measurable Metrics:**
- The `ApiService` class must serve as the sole HTTP communication layer for all React pages — 0 direct `fetch()` calls outside of `api.ts` or `apiFetch.ts` — verified by static grep search.
- Shared Flutter Riverpod providers must be consumed by ≥ 2 screens each — verified by code review.
- `AppLayout` component must wrap 100% of customer-facing page components (HomePage, ServicesPage, ActivityPage, AccountPage) — verified by component audit.
- *Assumption:* No cross-project library packaging is planned in Phase 1; reusability is internal-only.

---

#### 4.4.10 Testability — **Priority: Medium**

**Justification:**  
The layered MVC + Service + Repository architecture makes the backend highly suited for unit testing each layer in isolation (mock the repository in Service tests; mock the service in Controller tests). The TypeScript `ApiService` class can be mocked in React component tests. Riverpod's provider overriding mechanism supports dependency injection in Flutter widget tests. However, no formal test suite currently exists in the repository (TBD), making this a medium-priority attribute targeted for Phase 2 enforcement.

**Measurable Metrics:**
- Unit test coverage for all `@Service` classes must reach ≥ 80% branch coverage — verified by JaCoCo coverage report in CI.
- All 18 `@RestController` classes must have at least one integration test per HTTP method (e.g., `MockMvc` test) — verified by test inventory audit.
- The React `ApiService` class must be mockable in Jest/Vitest without network calls — verified by running component test suite with mock `apiService`.
- The Flutter `workerRepositoryProvider` must be overridable in widget tests using `ProviderContainer` — verified by widget test execution.
- CI pipeline must execute all backend tests and fail the build on any test regression — verified by GitHub Actions / CI configuration review.

---

#### 4.4.11 Usability — **Priority: High**

**Justification:**  
Usability is high priority because the primary user class (customers) consists of general public with no assumed technical background. The booking flow is multi-step (service selection → date pick → time slot → checkout → payment) and must be learnable without any training. The web app is responsive, supporting both mobile (bottom nav, step progress bar) and desktop (sidebar summary panel, 3-column grid) layouts. Grayed-out booked slots provide immediate visual feedback that prevents user error. Toast notifications acknowledge all actions. Status badges are color-coded consistently across all views. The Flutter app uses the familiar `Instrument Sans` typeface with adequate sizing for service floor conditions.

**Measurable Metrics:**
- A first-time user must be able to complete a full appointment booking (service → date → time → checkout → confirm) in ≤ 5 minutes without assistance — verified by usability test with 5 participants unfamiliar with the system.
- All interactive elements (buttons, slots, badges) must meet WCAG 2.1 AA color contrast ratio of ≥ 4.5:1 — verified by accessibility audit tool (e.g., Lighthouse or axe).
- Booked time slots must be visually distinguished (gray + strikethrough) from available slots without relying on color alone — verified by color-blind simulation test.
- The mobile web UI must achieve a Lighthouse performance score of ≥ 85 on a simulated 4G network — verified by automated Lighthouse CI run.
- Error messages must be displayed within 500 ms of a failed action and must include actionable text (not just error codes) — verified by UX test script.

---

#### 4.4.12 Availability — **Priority: Medium**

**Justification:**  
Customer booking is available 24/7 (§2.1.7) and customers may attempt to book at any hour, including outside business hours. However, Servio is deployed for a single service center, and brief planned maintenance windows are acceptable (unlike an e-commerce platform). Availability depends heavily on Supabase's managed PostgreSQL SLA and the hosting infrastructure's uptime. Supabase Pro tier provides 99.9% uptime SLA and automated PITR backups. The backend is containerized with Docker Compose, enabling fast restart on failure.

**Measurable Metrics:**
- System uptime must be ≥ 99.5% monthly (allowing ≤ 3.6 hours of downtime per month) — tracked by an uptime monitoring tool (e.g., UptimeRobot, Better Uptime).
- `GET /api/auth/health` must return HTTP 200 within 1 second at all times during operation — used as the health check probe by the monitoring system.
- After any container restart or crash, the backend must be back to a healthy state (health endpoint returning 200) within 60 seconds — verified by Docker restart test.
- Database Point-in-Time Recovery (PITR) must be possible to within a 1-hour window — provided by Supabase Pro tier configuration.
- Planned maintenance must be schedulable outside 6:00 AM–10:00 PM SLST (peak booking hours) — operational policy enforced by deployment runbook.

---

*Definitions of the quality characteristics not defined in the paragraphs above follow.*

- **Correctness** — Extent to which the program satisfies its specifications and fulfills the user's mission objectives.
- **Efficiency** — Amount of computing resources and code required to perform a function.
- **Flexibility** — Effort needed to modify an operational program.
- **Interoperability** — Effort needed to couple one system with another.
- **Reliability** — Extent to which a program performs with required precision over time.
- **Reusability** — Extent to which a component can be reused in another application.
- **Testability** — Effort needed to test a program to ensure it performs as intended.
- **Usability** — Effort required to learn, operate, prepare input, and interpret output.

### 4.5 Business Rules

1. Only services marked `is_active = true` shall appear on the customer home page and services list.
2. Mechanics with status `ON_LEAVE` shall not be assignable to new job cards.
3. Time slots are 30-minute intervals from 9:00 AM to 6:00 PM. A maximum of one appointment is permitted per time slot.
4. PayHere payment sessions must be initiated server-side; hash generation must occur on the backend.
5. Walk-in customers may be elevated to registered user accounts via `PATCH /api/admin/walk-in-customers/{id}/register/{userId}`.
6. Repair estimates have a default validity of 7 days and expire automatically thereafter.
7. Admin users can access `/admin/*` routes; non-admin authenticated users are redirected to the customer home page.
8. Appointment cancellation via `POST /api/appointments/{id}/cancel` verifies ownership — users cannot cancel other users' appointments.

---

## 5. Other Requirements

### 5.1 Online User Documentation and Help System Requirements

No in-app help system or tooltip-based guidance is currently implemented. Documentation is provided exclusively as Markdown files bundled in the project repository. These are intended for developers and administrators.

**TBD**: In-app contextual help modals and a user-facing FAQ page are planned for Phase 2.

### 5.2 Purchased Components

- **Supabase** (Free/Pro tier): Used for cloud PostgreSQL hosting and OAuth authentication. Subscription to a paid Supabase plan required for production use.
- **PayHere Merchant Account**: Requires registration at payhere.lk. Transaction fees apply per the payment processor's pricing model.
- **Google Fonts**: `Instrument Sans` font used across the Flutter mobile app. Served via the `google_fonts` Flutter package (open source, free).

No proprietary SDKs or commercial licensed software beyond the above are used.

### 5.3 Interfaces

#### 5.3.1 User Interfaces

**Web Application (React)**

- Responsive SPA with mobile-first design using CSS breakpoints.
- Brand color: `#ff5d2e` (Servio Orange). Background: white/light neutral. Accent warm tones (`#ffe7df`).
- Bottom navigation bar on mobile; top navigation bar on desktop.
- Notifications displayed via a bell icon (`NotificationBell.tsx`) with unread count badge.
- Forms use standard HTML inputs styled with Tailwind-variant CSS classes.
- Toast notifications for all actions (success/error) via the `sonner` library.

**Admin Web Panel (React, `/admin/*`)**

- Sidebar navigation layout (`AdminAppLayout.tsx`) with links to: Dashboard, Services, Offers, Appointments, Customers, Calendar, Mechanics, Service Bays, Walk-In Customers, Job Cards.
- Card-based statistics at the top of the Dashboard.
- Data tables with search, filter (by status dropdown), and pagination-ready design.
- Status badges color-coded: Active = green, Inactive = grey, In Progress = blue, Completed = green, Cancelled = red.

**Flutter Mobile App**

- Welcome screen with sign-in options (email/password, Google, Facebook via Supabase).
- Customer home: Tab Bar with 4 tabs: Home, Services, Activity, Account.
- Worker home: Single pane dashboard with scrollable job card list.
- Admin home: Admin-specific dashboard screen.
- Bottom sheet modals for status updates; full-screen flows for booking and checkout.
- QR code displayed on the appointment confirmed screen using `qr_flutter ^4.1.0`.

#### 5.3.2 Hardware Interfaces

The only hardware interface is the device camera accessed on the Flutter mobile app via the native image picker, used for uploading diagnostic and repair photos to job cards. No other hardware peripherals are supported or required.

#### 5.3.3 Software Interfaces

| Interface | Direction | Description |
|---|---|---|
| `POST /api/auth/signup` | Client→Server | Register new user |
| `POST /api/auth/login` | Client→Server | Authenticate user, receive JWT |
| `POST /api/auth/supabase-login` | Client→Server | Exchange Supabase token for internal JWT |
| `GET /api/services` | Client→Server | Fetch all active services |
| `GET /api/services/featured` | Client→Server | Fetch featured services for home page |
| `POST /api/appointments` | Client→Server | Create appointment booking |
| `GET /api/appointments/booked-slots?date=` | Client→Server | Fetch already-booked times for a date |
| `POST /api/appointments/{id}/cancel` | Client→Server | Cancel own appointment (ownership verified) |
| `POST /api/payments/payhere/initiate` | Client→Server | Get PayHere checkout form data with hash |
| `POST /api/payments/payhere/notify` | PayHere→Server | Asynchronous payment result webhook |
| `GET /api/vehicles/my` | Client→Server | Get authenticated user's vehicles |
| `GET /api/notifications/user/{id}/unread/count` | Client→Server | Get unread notification count |
| `GET /api/repairs/{id}` | Client→Server | Get repair job detail |
| `POST /api/repairs/progress` | Client→Server | Add a repair progress update |
| All `/api/admin/*` | Admin Client→Server | Protected admin management endpoints |

#### 5.3.4 Communications Interfaces

- **Primary**: HTTPS/HTTP REST with JSON request/response bodies.
- **PayHere Webhook**: `application/x-www-form-urlencoded` incoming from PayHere servers to `POST /api/payments/payhere/notify`.
- **CORS**: Enforced; frontend origins must be whitelisted in backend configuration.
- **JWT**: Bearer tokens transmitted in `Authorization` HTTP header.
- **WebSocket (Partial)**: Frontend `HomePage.tsx` subscribes to `/topic/appointments` via STOMP. Full server-side broadcast is a Phase 2 item.

### 5.4 Licensing Requirements

No specific licensing requirements are mandated by the service center customer. All open-source dependencies are used under their respective licenses (MIT, Apache 2.0). The PayHere integration is subject to PayHere's Merchant Terms of Service.

### 5.5 Legal, Copyright and Other Notices

- The Servio platform is proprietary software owned by the development team and the service center operator.
- Integration with PayHere must comply with Sri Lanka's Payment Systems Act and PayHere's anti-fraud policies.
- Customer personal data (name, phone, email, vehicle details) must be handled in compliance with applicable Sri Lankan data protection regulations.
- BCrypt password hashing meets current industry standards for password storage security.

### 5.6 Applicable Standards

- **REST API Design**: Follows REST architectural constraints with appropriate HTTP method usage (GET, POST, PUT, PATCH, DELETE).
- **JSON**: All API payloads conform to RFC 7159 (JSON standard).
- **JWT**: Tokens conform to RFC 7519 (JSON Web Tokens).
- **BCrypt**: Password hashing follows the Blowfish-based cryptographic scheme standard.
- **HTTP Status Codes**: RFC 7231 standard codes used (200, 201, 400, 401, 403, 404, 409, 500).
- **PayHere API**: Complies with PayHere's Official Checkout API specification (https://support.payhere.lk).

---

## 6. System Architecture

### 6.0 Architecture Diagram

The diagram below illustrates the complete, end-to-end logical organization of the Servio system across all four tiers, their internal components, and their inter-tier communication protocols.

![Servio System Architecture](/Users/chamindu/.gemini/antigravity/brain/16bb192a-c593-43d2-b6fb-3cde1a607a5c/servio_architecture_1776188790321.png)

---

### 6.1 Logical Organization and Architectural Rationale

Servio is organized as a **Four-Tier, Multi-Client Architecture** with a centralized REST API at its core. This organizational model was chosen deliberately to address the system's three distinct user roles (Customer, Worker, Admin), three distinct delivery channels (browser, mobile app, admin panel), and two external service dependencies (Supabase, PayHere), while maintaining a single authoritative source of business logic and data.

The four tiers from top to bottom are:

---

#### TIER 1: Client Layer — Three Parallel Frontends

**What it contains:**
- **React Web SPA** (`TypeScript + Vite`, port 80/5173): Serves both the customer-facing booking portal and, when a user holds the `ADMIN` JWT role, the full admin management panel on `/admin/*` routes. The same React bundle handles both personas; route-level `AdminGuard` and `AuthGuard` components enforce access separation in the browser.
- **Flutter Mobile App** (`Dart 3.9 / Flutter 3.x`, iOS + Android): A native cross-platform application for all three user roles — each role is routed to a completely different navigation shell (`/home`, `/worker`, `/admin`) by `go_router` immediately after login.
- **Admin Web Panel** (role-gated `/admin/*` subset of the React SPA): Same bundle as the customer web app, but the sidebar layout, admin statistics cards, and admin-only entity management screens are only visible to tokens bearing the `ADMIN` claim.

**Architectural reasoning:**
- Separating customer web from admin web into distinct *route namespaces within the same SPA* avoids maintaining two separate frontend codebases — the build artifact, CDN cache, and CORS configuration are unified. Role enforcement happens at the React route and API layers, not at the deployment layer.
- A dedicated **native Flutter app** (rather than a Progressive Web App) was chosen for workers and customers on mobile because: (a) it gives mechanics a native-feeling job queue UI on the service floor without network-bar hassle; (b) it enables QR code generation (`qr_flutter`) and camera access (`image_picker`) as first-class native capabilities; (c) Supabase OAuth social login (Google/Facebook) integrates far more smoothly via the `supabase_flutter` SDK on native mobile than in a browser PWA context.

---

#### TIER 2: API Gateway Layer — Spring Boot Centralized Backend

**What it contains:**
- **Spring Boot REST API** running on port `3001`, implemented in Java 17+.
- 18 `@RestController` classes organized around domain bounded contexts: `AuthController`, `AppointmentController`, `VehicleController`, `RepairJobController`, `RepairProgressController`, `NotificationController`, `ServiceController`, `ServiceRecordController`, `PayHereController`, and 7 admin controllers (`AdminController`, `AdminJobCardController`, `AdminMechanicController`, `AdminServiceBayController`, `AdminWalkInController`, `AdminServiceController`, `AdminOfferController`).
- A **JWT Security Filter Chain** (`JwtAuthenticationFilter` + `SecurityConfig`) sits in front of all requests, validating `Authorization: Bearer {token}` headers and injecting the authenticated principal and roles into Spring's `SecurityContext`.
- All business logic is isolated in Service classes (one per controller); controller classes only perform request parsing and response mapping.

**Architectural reasoning:**
- A **single, centralized API** was chosen over microservices because the system is a single-venue service center application with modest scale requirements. Microservices would add deployment complexity (service discovery, inter-service auth, distributed tracing) that provides no benefit at this scale.
- The **centralized API as the sole data gateway** means neither the React SPA nor the Flutter app ever connects directly to the database. All data access is mediated through the API, enforcing business rules (slot conflict detection, PayHere hash generation, ownership verification on cancellation) in one place, regardless of which client is calling.
- The **layered MVC + Service + Repository pattern** (5 distinct layers) enforces the single-responsibility principle: controllers do not contain business logic, services do not contain SQL, repositories do not contain HTTP concerns. This makes each layer independently testable and independently evolvable.

---

#### TIER 3: Data Layer — Supabase PostgreSQL + Supabase Auth

**What it contains:**
- **Supabase PostgreSQL 15** (cloud-hosted): The single relational database for all persistent entities — 20+ tables covering users, vehicles, appointments, payments, repair jobs, notifications, job cards, mechanics, service bays, and walk-in customers. All timestamp management is handled by database triggers (`updated_at`). Referential integrity is maintained via `ON DELETE CASCADE` and `ON DELETE SET NULL` foreign key rules. Frequently queried columns are indexed.
- **Supabase Auth / OAuth** (cloud-hosted): Manages OAuth social login for Flutter mobile users (Google, Facebook). Issues Supabase-signed JWTs that the Flutter app then exchanges for internal backend JWTs via `POST /api/auth/supabase-login`. This bridges the Supabase identity into the Servio `profiles` table.

**Why split into two sub-components within Tier 3?**
- Supabase Auth and the PostgreSQL database are logically separate services (even though both run on Supabase infrastructure). The Flutter app communicates with Supabase Auth *directly* via the SDK during login; it communicates with PostgreSQL only *indirectly* through the Spring Boot API. The React web app bypasses Supabase Auth entirely, using Spring Boot's own email/password login (`POST /api/auth/login`). This separation is explicit in the architecture to avoid the misconception that all clients talk to the database or auth service directly.

**Architectural reasoning for choosing Supabase:**
- Supabase provides managed PostgreSQL with Point-in-Time Recovery (PITR), daily backups, row-level security, and realtime capabilities — eliminating the need for the development team to operate database infrastructure.
- Supabase's OAuth flow is production-ready for mobile (Google/Facebook sign-in) without building a custom OAuth integration.
- The "profile" dual-identity model (native `users` table for web + `profiles` table for Supabase OAuth users) allows both login methods to coexist and eventually be unified.

---

#### TIER 4: External Integration — PayHere Payment Gateway

**What it contains:**
- **PayHere** (payhere.lk): Sri Lanka's primary card payment gateway, used for processing online card payments at appointment checkout.
- Two integration points: (a) the **PayHere JS SDK** loaded in the React web app's `index.html`, which opens an in-page payment modal when `window.payhere.startPayment()` is called — keeping the user on the Servio site throughout the payment flow; and (b) a **server-to-server asynchronous webhook** where PayHere's backend POSTs the payment result to `POST /api/payments/payhere/notify` after the transaction is processed.

**Architectural reasoning:**
- The PayHere integration uses a **split-brain security model**: the frontend initiates the checkout flow (opens the modal), but the authoritative payment confirmation arrives via the backend webhook — not from the frontend. This prevents a malicious user from spoofing a payment success by manipulating JS callbacks.
- The `merchant_secret` (used to generate and verify the MD5 `md5sig` signature) **never leaves the backend server**. Hash generation and verification happen exclusively in `PayHereController`. This is a hard architectural constraint (§2.5, REQ-5.1).
- Placing PayHere at Tier 4 (below the data layer in the diagram) represents the direction of authoritative data flow: PayHere → Backend → Database, not the reverse. The backend is the single writer of payment records.
- If a user dismisses or encounters an error in the PayHere modal, the frontend's `onDismissed()` / `onError()` callbacks immediately call `POST /api/appointments/{id}/cancel` to release the booked time slot — preventing phantom bookings from blocking other customers.

---

#### Security Overlay — Cross-Cutting Concern Across All Tiers

Security is not localized to a single tier but is applied as a **cross-cutting concern** across all four layers, as shown in the right-hand column of the architecture diagram:

| Security Control | Applied At | Mechanism |
|---|---|---|
| **JWT Filter Chain** | Tier 2 (API) | `JwtAuthenticationFilter` validates every incoming request before reaching any controller |
| **BCrypt Passwords** | Tier 2 (API) + Tier 3 (DB) | Passwords hashed with BCrypt cost-10 before storage; never stored or transmitted in plaintext |
| **RBAC Roles** | Tier 1 (Frontend Guards) + Tier 2 (API annotations) | `@PreAuthorize("hasRole('ADMIN')")` on every admin endpoint; `AdminGuard` on React routes; `go_router` role routing in Flutter |
| **MD5 Webhook Signature** | Tier 4→Tier 2 | `md5sig` validated in `PayHereController` before any database writes |
| **CORS Allowlist** | Tier 2 (API) | Only explicitly allowlisted frontend origins may call the API |
| **Route Guards** | Tier 1 (Clients) | React `AuthGuard` / `AdminGuard`; Flutter `go_router` post-login role routing |

---

### 6.2 Logical Architecture

The architectural pattern within each tier is described below.

#### 6.2.1 Backend — Layered MVC + Service + Repository

The Servio backend follows a strict 5-layer pattern. No layer may depend on a layer above it; no layer may skip a layer below it:

```
HTTP Request
     │
     ▼
┌────────────────────────────────────────────────────────────┐
│  CONTROLLER LAYER  (18 @RestController classes)            │
│  • Parse HTTP input, call Service, build ApiResponse<T>    │
│  • Enforce @PreAuthorize security annotations              │
│  • No business logic; no direct DB access                  │
└─────────────────────────────┬──────────────────────────────┘
                              │ calls
┌─────────────────────────────▼──────────────────────────────┐
│  SERVICE LAYER  (18 @Service classes)                      │
│  • Business logic: validation, state transitions           │
│  • MD5 hash generation, slot conflict checks               │
│  • DTO ↔ Entity conversion                                 │
│  • No HTTP objects; no raw SQL                             │
└─────────────────────────────┬──────────────────────────────┘
                              │ calls
┌─────────────────────────────▼──────────────────────────────┐
│  REPOSITORY LAYER  (Spring Data JPA Repositories)          │
│  • findBy* / save / delete via JPA                         │
│  • Custom @Query JPQL for filtered lookups                 │
│  • No business logic; returns raw Entities                 │
└─────────────────────────────┬──────────────────────────────┘
                              │ maps to
┌─────────────────────────────▼──────────────────────────────┐
│  ENTITY LAYER  (32 @Entity classes)                        │
│  • JPA domain models; FetchType.LAZY on all relations      │
│  • @PrePersist / @PreUpdate lifecycle hooks                │
│  • Integrity constraints (UNIQUE, CHECK) declared here     │
└─────────────────────────────┬──────────────────────────────┘
                              │ persisted to
┌─────────────────────────────▼──────────────────────────────┐
│  DATA STORE  (Supabase PostgreSQL 15)                      │
│  • 20+ tables; indexes; triggers for updated_at            │
│  • ON DELETE CASCADE / SET NULL referential integrity      │
└────────────────────────────────────────────────────────────┘

  DTO LAYER (Request/Response DTOs) — cross-cuts Controllers
  and Services; decouples API schema from entity schema
```

#### 6.2.2 React Web Frontend — Component + Context + Service

| Layer | Key Files | Responsibility |
|---|---|---|
| **Pages** | 12 customer pages + 10 `/admin/*` pages | Route-level UI composition; one page per URL route |
| **Components** | `ServiceCard`, `OfferCard`, `VehicleSelector`, `NotificationBell`, `AdminGuard`, `AuthGuard` | Reusable, stateless UI widgets; route guard HOCs |
| **Contexts** | `AuthContext` | Global auth state (user object, JWT token, isAdmin flag) shared across all pages |
| **Services** | `ApiService` class (singleton in `api.ts`), `adminApi`, `supabaseAuth` | Typed wrappers around `fetch()`; single point of API contract definition for all pages |
| **Hooks** | `useWebSocket`, `useAuth` | Cross-cutting concerns (WebSocket subscription, auth state access) |

#### 6.2.3 Flutter Mobile App — Feature-First + Riverpod

| Feature Folder | Screens / Providers | Responsibility |
|---|---|---|
| `features/auth` | Sign In, Sign Up, Welcome screens | Supabase authentication flows (email/OTP/Google/Facebook) |
| `features/home` | Home screen | Service discovery and promotional announcements |
| `features/bookings` | Activity, Checkout, Confirmation | Appointment booking and status viewing |
| `features/services` | Service listing and detail screens | Browse and filter service catalog |
| `features/worker` | Worker Dashboard, `workerRepository`, `activeAppointmentsProvider` | Mechanic job queue management and status updates |
| `features/admin` | Admin Dashboard | Administrative mobile overview |
| `features/profile` | Account screen | User profile and vehicle management |
| `shared` | `MainNavigationScreen` | Bottom tab bar shell shared by all customer screens |
| `core` | `SupabaseService`, `AppConfig` | Shared Supabase client initialization and app-wide config |

---

### 6.3 Component Architecture

| Component | Technology | Deployment Unit |
|---|---|---|
| **Backend API** | Spring Boot JAR (`mvn clean package`) | Docker container or standalone JVM process |
| **Web Frontend** | React SPA bundle (`npm run build`) | Docker container (nginx) or static file server |
| **Mobile App** | Flutter APK (Android) / IPA (iOS) | Native app install via app store or sideload |
| **Database** | PostgreSQL 15 | Managed by Supabase (cloud) |
| **PayHere** | External SaaS | No deployment required; API key configuration only |

**Component dependency graph (all data flows route through the API):**

```
Flutter Mobile ──────────────────────────────────┐
React Web SPA ───────────────────────────────────┼─► Spring Boot API ─► Supabase PostgreSQL
React Admin Panel (same SPA, /admin routes) ─────┘          │
                                                             ├─► Supabase Auth (token validation)
                                                             └─► PayHere (external, webhook-based)
```

**Key design decision:** Both the React SPA and the Flutter app call the **same backend API endpoints** for shared operations (e.g., `GET /api/services`, `POST /api/appointments`). There are no client-specific API forks. This ensures business rules are evaluated centrally and consistently regardless of which client surface a user is operating from.

---

### 6.4 Physical Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        USER DEVICES                                    │
│  ┌──────────────────────────┐      ┌─────────────────────────────────┐ │
│  │   Customer / Admin       │      │  Mechanic Device (iPhone/Android)│ │
│  │  (Desktop/Mobile Browser)│      │  → Flutter Mobile App           │ │
│  └───────────┬──────────────┘      └────────────────┬────────────────┘ │
└──────────────┼──────────────────────────────────────┼──────────────────┘
               │ HTTPS                                 │ HTTPS (Supabase SDK)
┌──────────────▼──────────────────────────────────────▼──────────────────┐
│                     CLOUD SERVER / VPS                                  │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  Docker Compose Environment                                     │    │
│  │  ┌──────────────────────┐   ┌────────────────────────────┐     │    │
│  │  │ Frontend Container   │   │  Backend Container          │     │    │
│  │  │ (nginx serving       │   │  (Spring Boot JVM           │     │    │
│  │  │  React SPA on :80)   │   │   on port 3001)             │     │    │
│  │  └──────────────────────┘   └──────────────┬─────────────┘     │    │
│  └───────────────────────────────────────────┼───────────────────┘    │
└──────────────────────────────────────────────┼─────────────────────────┘
                                                │ JDBC over TLS
┌───────────────────────────────────────────────▼────────────────────────┐
│                        SUPABASE CLOUD                                   │
│          Managed PostgreSQL + Auth + Realtime + Storage                 │
│               (Hosted on AWS / multiple regions)                        │
└─────────────────────────────────────────────────────────────────────────┘

  External:  payhere.lk  ──►  POST /api/payments/payhere/notify
```

**Physical deployment notes:**
- The React SPA and Spring Boot API are co-deployed inside a single Docker Compose stack, reducing networking complexity between the two during production deployment.
- The database is fully externalized to Supabase cloud — the production server has no PostgreSQL process. This reduces ops burden and provides enterprise-grade backup/recovery out-of-the-box.
- The Flutter mobile app is distributed as a native binary (APK/IPA) — it does not run inside Docker and communicates with the same backend API URL over HTTPS from the device's cellular or Wi-Fi network.
- PayHere's webhook arrives inbound to the server from the internet; the backend's `/api/payments/payhere/notify` endpoint must therefore be publicly reachable (no JWT guard) while still being authenticated via MD5 signature verification.

---

---

## Appendix A: Glossary

| Term | Definition |
|---|---|
| **SRS** | Software Requirements Specification |
| **SPA** | Single-Page Application |
| **JWT** | JSON Web Token — a compact, URL-safe means of representing claims between parties |
| **RBAC** | Role-Based Access Control |
| **BCrypt** | Password hashing algorithm based on the Blowfish cipher |
| **PayHere** | A Sri Lankan payment gateway provider (www.payhere.lk) |
| **Supabase** | An open-source Firebase alternative providing hosted PostgreSQL, authentication, and realtime features |
| **JPA** | Java Persistence API — the standard ORM specification used by Hibernate in Spring |
| **LKR** | Sri Lankan Rupee — the currency used by Servio |
| **Job Card** | A formal work order created for a vehicle service job |
| **Walk-in Customer** | A customer who visits the service center without a pre-registered account |
| **Service Bay** | A physical work station within the service center (e.g., General, Wash Station, Alignment) |
| **Mechanic / Worker / Technician** | A service center staff member who performs vehicle repairs |
| **ADMIN** | The highest privilege role in the system — service center manager |
| **md5sig** | The MD5 signature field in PayHere's webhook notification, used to verify authenticity |
| **STOMP** | Simple Text Oriented Messaging Protocol — used for WebSocket message routing |
| **Flutter** | Google's UI toolkit for building natively compiled apps from a single Dart codebase |
| **Riverpod** | A reactive state management library for Flutter/Dart |
| **go_router** | A declarative routing package for Flutter |
| **Vite** | A build tool and dev server for modern web projects |
| **ORM** | Object-Relational Mapping — maps Java objects to database tables |
| **PITR** | Point-in-Time Recovery — Supabase database backup mechanism |

---

## Appendix B: Analysis Models

### Entity-Relationship Overview

```
users ──< vehicles ──< service_records
  │              │
  │              └──< repair_history
  │
  └──< appointments ──< payments
           │       └──< repair_jobs ──< repair_progress_updates
           │                     └──< repair_parts
           │                     └──< repair_images
           │                     └──< repair_estimates
           │                     └─── repair_progress (1:1)
           │                     └──< repair_activities
           │
           └──< job_cards ──< job_tasks
                         └──< job_card_notes
                         └──< job_card_photos

mechanics ──< job_cards
service_bays ──< job_cards
walk_in_customers ──< job_cards

users ──< notifications
users ──< reviews
```

### Role Access Matrix

| Feature | CUSTOMER | WORKER | ADMIN |
|---|---|---|---|
| Browse services | ✅ | ✅ | ✅ |
| Book appointment | ✅ | ❌ | ✅ |
| Pay online (PayHere) | ✅ | ❌ | ❌ |
| View own appointments | ✅ | ❌ | ✅ (all) |
| Cancel own appointment | ✅ | ❌ | ✅ (any) |
| View/manage vehicles | ✅ | ❌ | ✅ |
| Worker dashboard | ❌ | ✅ | ❌ |
| Admin dashboard | ❌ | ❌ | ✅ |
| Manage services/offers | ❌ | ❌ | ✅ |
| Manage mechanics/bays | ❌ | ❌ | ✅ |
| Create job cards | ❌ | ❌ | ✅ |
| Update job/appointment status | ❌ | ✅ | ✅ |
| View notifications | ✅ | ❌ | ✅ |

---

## Appendix C: To Be Determined List

| TBD # | Item | Owner | Target Resolution |
|---|---|---|---|
| TBD-1 | Full server-side WebSocket broadcast for real-time appointment updates (frontend `useWebSocket` hook implemented, server broadcast TBD) | Backend Team | Phase 2 |
| TBD-2 | Cloud storage integration (AWS S3 / Azure Blob) for job card photo uploads | Infrastructure Team | Phase 2 |
| TBD-3 | Customer-facing repair progress tracking page showing percentage completion | Frontend Team | Phase 2 |
| TBD-4 | SMS / Email notification dispatch for appointment confirmations | Backend Team | Phase 2 |
| TBD-5 | STAFF role definition and permission scope (between CUSTOMER and ADMIN) | All Teams | Phase 2 |
| TBD-6 | Analytics dashboard (revenue charts, service popularity, mechanic efficiency) | Frontend / Backend | Phase 2 |
| TBD-7 | PayHere webhook production URL configuration and SSL certificate setup | DevOps | Pre-launch |
| TBD-8 | In-app help system / contextual tooltips for customer onboarding | Frontend Team | Phase 2 |
| TBD-9 | Mobile offline mode for mechanics to view jobs without connectivity | Mobile Team | Phase 3 |
| TBD-10 | Customer-initiated review/rating submission UI | Frontend Team | Phase 2 |
