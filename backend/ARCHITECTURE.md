# Backend Architecture Overview

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Frontend (React)                            │
│                      http://localhost:5173                           │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                        ┌────────▼────────┐
                        │  CORS Validation │
                        └────────┬────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    API Gateway / Web Layer                           │
│                    Spring Boot Application                           │
│                      http://localhost:3001                           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                 Spring Security Filter Chain                 │  │
│  │  ┌─────────────────────────────────────────────────────────┐ │  │
│  │  │  JWT Authentication Filter                              │ │  │
│  │  │  - Extract Bearer token from Authorization header       │ │  │
│  │  │  - Validate JWT signature                               │ │  │
│  │  │  - Extract userId from token claims                     │ │  │
│  │  │  - Set security context                                 │ │  │
│  │  └─────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    REST Controllers                          │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  AuthController                                      │  │  │
│  │  │  - POST   /api/auth/signup                          │  │  │
│  │  │  - POST   /api/auth/login                           │  │  │
│  │  │  - GET    /api/auth/profile (authenticated)         │  │  │
│  │  │  - GET    /api/health                               │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Service Layer                            │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  AuthService                                         │  │  │
│  │  │  - signup(request) → AuthResponse                   │  │  │
│  │  │  - login(request) → AuthResponse                    │  │  │
│  │  │  - getProfile(userId) → UserResponse               │  │  │
│  │  │  - Password validation with BCrypt                  │  │  │
│  │  │  - Token generation with JWT                        │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Data Access Layer                        │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  Spring Data JPA Repositories                        │  │  │
│  │  │  - UserRepository (findByEmail, existsByEmail)       │  │  │
│  │  │  - VehicleRepository (findByUserId)                  │  │  │
│  │  │  - ServiceRecordRepository (findByVehicleId)         │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────┬─────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Database Access Layer                             │
│                     Hibernate ORM / JDBC                             │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Entity Mappings                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐    │  │
│  │  │    User      │  │   Vehicle    │  │ ServiceRecord  │    │  │
│  │  │  @Entity     │  │  @Entity     │  │   @Entity      │    │  │
│  │  │              │  │              │  │                │    │  │
│  │  │ @Table       │  │ @Table       │  │ @Table         │    │  │
│  │  │(name="users")│  │(name=        │  │ (name=         │    │  │
│  │  │              │  │"vehicles")   │  │"service_       │    │  │
│  │  │ id (PK)      │  │              │  │records")       │    │  │
│  │  │ email (UK)   │  │ id (PK)      │  │                │    │  │
│  │  │ full_name    │  │ user_id (FK) │  │ id (PK)        │    │  │
│  │  │ password_hash│  │ make         │  │ vehicle_id (FK)│    │  │
│  │  │ phone        │  │ model        │  │ service_type   │    │  │
│  │  │ timestamps   │  │ timestamps   │  │ timestamps     │    │  │
│  │  └──────────────┘  └──────────────┘  └────────────────┘    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────┬─────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      PostgreSQL Database                            │
│                    servio_db on port 5432                           │
│                                                                      │
│  Tables:                                                             │
│  - users (user accounts & authentication)                           │
│  - vehicles (user vehicles)                                         │
│  - service_records (service history)                                │
│  - Indexes on email, user_id, vehicle_id for performance           │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### 1. Controllers (Entry Point)
**File**: `src/main/java/com/servio/controller/AuthController.java`

**Responsibilities**:
- Accept HTTP requests
- Validate request format
- Delegate to service layer
- Return formatted responses
- Handle HTTP status codes

**Endpoints**:
- `POST /api/auth/signup` → Service.signup()
- `POST /api/auth/login` → Service.login()
- `GET /api/auth/profile` → Service.getProfile()
- `GET /api/health` → Direct response

### 2. Services (Business Logic)
**File**: `src/main/java/com/servio/service/AuthService.java`

**Responsibilities**:
- Implement business logic
- Coordinate between repositories
- Perform validations
- Generate JWT tokens
- Hash passwords

**Methods**:
- `signup(request)`: Register new user
- `login(request)`: Authenticate user
- `getProfile(userId)`: Retrieve user data
- Helper: `mapToUserResponse()`: DTO mapping

### 3. Repositories (Data Access)
**Files**:
- `src/main/java/com/servio/repository/UserRepository.java`
- `src/main/java/com/servio/repository/VehicleRepository.java`
- `src/main/java/com/servio/repository/ServiceRecordRepository.java`

**Responsibilities**:
- Extend Spring Data JPA Repository
- Provide database queries
- Handle transactions
- Manage connection pooling (via HikariCP)

**Methods**:
- `findByEmail()`: Search user by email
- `existsByEmail()`: Check email existence
- `findByUserId()`: Get user's vehicles
- `findByVehicleId()`: Get vehicle's service records

### 4. Entities (Data Models)
**Files**:
- `src/main/java/com/servio/entity/User.java`
- `src/main/java/com/servio/entity/Vehicle.java`
- `src/main/java/com/servio/entity/ServiceRecord.java`

**Responsibilities**:
- Map to database tables via JPA
- Define relationships
- Manage timestamps
- Validate constraints

**Features**:
- `@Entity`: JPA entity mapping
- `@PrePersist/@PreUpdate`: Auto-timestamp
- `@ManyToOne/@OneToMany`: Relationships
- Lombok `@Data`: Getters, setters, constructors

### 5. DTOs (Data Transfer)
**Files**:
- `src/main/java/com/servio/dto/SignupRequest.java`
- `src/main/java/com/servio/dto/LoginRequest.java`
- `src/main/java/com/servio/dto/UserResponse.java`
- `src/main/java/com/servio/dto/AuthResponse.java`
- `src/main/java/com/servio/dto/ApiResponse.java`

**Responsibilities**:
- Define request/response structure
- Validate input data
- Decouple API from entities
- Type-safe communication

### 6. Security (Authentication)
**Files**:
- `src/main/java/com/servio/config/SecurityConfig.java`
- `src/main/java/com/servio/security/JwtAuthenticationFilter.java`
- `src/main/java/com/servio/util/JwtTokenProvider.java`

**Responsibilities**:
- Configure Spring Security
- Validate JWT tokens
- Manage authentication context
- Control endpoint access

**Flow**:
```
Request → JwtAuthenticationFilter
         → Extract token from header
         → Validate signature (JwtTokenProvider)
         → Extract userId from claims
         → Set security context
         → Route to controller
```

### 7. Configuration
**Files**:
- `src/main/java/com/servio/config/SecurityConfig.java`
- `src/main/java/com/servio/config/CorsConfig.java`
- `src/main/resources/application.properties`
- `src/main/resources/application-dev.properties`

**Responsibilities**:
- Configure Spring beans
- Set up security rules
- Enable CORS
- Manage database connections
- External configuration

## Data Flow

### User Signup Flow
```
1. Frontend sends:
   POST /api/auth/signup
   {
     "fullName": "John Doe",
     "email": "john@example.com",
     "phone": "+1234567890",
     "password": "password123"
   }

2. AuthController receives request
   ↓
3. Input validation (@Valid annotations)
   - Check fullName not empty
   - Check email format
   - Check password minimum length (6 chars)
   ↓
4. Call AuthService.signup(request)
   ↓
5. AuthService checks:
   - Email doesn't already exist (UserRepository.existsByEmail)
   ↓
6. Hash password with BCrypt (strength=10)
   ↓
7. Create User entity
   ↓
8. Save to database via UserRepository.save()
   ↓
9. Generate JWT token:
   - Payload: userId
   - Algorithm: HS512
   - Expiration: 24 hours
   ↓
10. Return AuthResponse (201 Created):
    {
      "success": true,
      "message": "User registered successfully",
      "data": {
        "user": {...},
        "token": "eyJhbGc..."
      }
    }
```

### User Login Flow
```
1. Frontend sends:
   POST /api/auth/login
   {
     "email": "john@example.com",
     "password": "password123"
   }

2. AuthController receives request
   ↓
3. Call AuthService.login(request)
   ↓
4. AuthService queries:
   UserRepository.findByEmail(email)
   ↓
5. If user exists:
   - Compare password with hash (BCrypt.matches)
   - If valid:
     - Generate JWT token
     - Return AuthResponse with user + token
   - If invalid:
     - Throw IllegalArgumentException
     ↓
6. Frontend receives token
   ↓
7. Frontend stores token in localStorage
   ↓
8. Future requests include:
   Authorization: Bearer <token>
```

### Protected Endpoint Flow
```
1. Frontend sends:
   GET /api/auth/profile
   Headers: {
     "Authorization": "Bearer eyJhbGc..."
   }

2. Request passes through JwtAuthenticationFilter
   ↓
3. Filter extracts token from header
   ↓
4. JwtTokenProvider.validateToken(token)
   - Verify signature with JWT_SECRET
   - Check expiration
   ↓
5. If valid:
   - Extract userId from token claims
   - Create UsernamePasswordAuthenticationToken
   - Set in SecurityContext
   ↓
6. Request continues to AuthController
   ↓
7. Spring injects Authentication object
   ↓
8. Get userId from authentication.getPrincipal()
   ↓
9. Call AuthService.getProfile(userId)
   ↓
10. UserRepository.findById(userId)
    ↓
11. Return UserResponse
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_email ON users(email);
```

### Vehicles Table
```sql
CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER,
    license_plate VARCHAR(50),
    vin VARCHAR(17),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);
```

### Service Records Table
```sql
CREATE TABLE service_records (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    service_type VARCHAR(100) NOT NULL,
    description TEXT,
    service_date DATE NOT NULL,
    mileage INTEGER,
    cost DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_service_records_vehicle_id ON service_records(vehicle_id);
```

## Technology Stack

### Framework & Runtime
- **Spring Boot 3.1.5**: Web application framework
- **Java 17**: Runtime environment
- **Maven 3.9**: Build automation

### Data Access
- **Spring Data JPA**: ORM abstraction
- **Hibernate**: JPA implementation
- **PostgreSQL Driver**: Database connectivity
- **HikariCP**: Connection pooling

### Security
- **Spring Security**: Authentication & authorization
- **JJWT 0.12.3**: JWT handling
- **BCrypt**: Password hashing

### Utilities
- **Lombok**: Boilerplate reduction
- **Jakarta Bean Validation**: Input validation
- **Spring DevTools**: Hot reload

### Testing & Build
- **JUnit 5**: Unit testing
- **Spring Test**: Integration testing
- **Maven**: Build management

## Performance Characteristics

### Database Performance
- **Connection Pool**: Max 20 connections
- **Lazy Loading**: Relationships loaded on demand
- **Batch Operations**: Hibernate batch mode enabled
- **Indexes**: Email, user_id, vehicle_id indexed

### Memory Usage
- **JVM Base**: ~150-200 MB
- **Running App**: ~300-400 MB under load
- **Heap Size**: Configurable, default 512MB

### Response Times
- **Signup**: ~200-300ms (includes password hashing)
- **Login**: ~150-200ms
- **Profile**: ~50-100ms
- **Health**: ~10-20ms

## Deployment Considerations

### Docker Container
- Image size: ~200-250 MB (JRE alpine)
- Memory limit: 512M recommended
- CPU: 1 core minimum

### Environment Requirements
- PostgreSQL 12+
- Java 17 runtime (in Docker image)
- 2GB available disk space

### Scaling
- Stateless: Can run multiple instances
- Load balancer: Can distribute requests
- Database: Single PostgreSQL instance sufficient for current load
- Sessions: No session storage (JWT-based)

## Security Model

### Authentication
- JWT tokens with 24-hour expiration
- HS512 signature algorithm
- Secret key >= 32 characters (configurable)

### Authorization
- Public endpoints: signup, login, health
- Protected endpoints: profile (authenticated users only)
- Stateless: No server-side session storage

### Data Protection
- Passwords: BCrypt with salt rounds=10
- CORS: Only frontend origin allowed
- HTTPS: Recommended in production (enforced via reverse proxy)

## Extension Points

To add new features:

1. **New Entity**: Create in `entity/` package
2. **New Repository**: Extend JpaRepository in `repository/`
3. **New Service**: Add methods to `service/` or create new service class
4. **New Endpoint**: Add method to `AuthController` or create new controller
5. **New DTOs**: Create request/response classes in `dto/`
6. **Security Rules**: Update `SecurityConfig.java`

## Monitoring & Logging

### Available Logs
- Application logs: `logs/application.log`
- Spring logs: Configured in `application.properties`
- Database logs: Can enable in dev profile

### Health Endpoint
- `GET /api/health`: Returns server and database status

### Future Enhancements
- Spring Boot Actuator for metrics
- ELK stack for centralized logging
- Prometheus for monitoring
