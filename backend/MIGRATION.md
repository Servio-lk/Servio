# Backend Migration: Node.js → Java Spring Boot

## Overview

The Servio backend has been successfully converted from a Node.js/Express application to a modern Java Spring Boot 3 application. The migration maintains 100% feature parity while introducing improvements in type safety, performance, and enterprise-grade features.

## Migration Summary

### Before (Node.js/Express)
- **Runtime**: Node.js 20
- **Framework**: Express 4.18
- **Package Manager**: npm
- **Database ORM**: Raw pg library
- **Authentication**: jsonwebtoken + bcrypt
- **Validation**: express-validator

### After (Java Spring Boot)
- **Runtime**: Java 17
- **Framework**: Spring Boot 3.1.5
- **Build Tool**: Maven 3
- **Database ORM**: Spring Data JPA/Hibernate
- **Authentication**: Spring Security + JJWT
- **Validation**: Spring Validation (Jakarta Bean Validation)

## Project Structure

```
backend/
├── src/main/java/com/servio/
│   ├── config/                    # Spring configuration
│   │   ├── CorsConfig.java       # CORS settings
│   │   └── SecurityConfig.java   # Security configuration
│   ├── controller/               # REST controllers
│   │   └── AuthController.java   # Authentication endpoints
│   ├── dto/                      # Data transfer objects
│   │   ├── SignupRequest.java
│   │   ├── LoginRequest.java
│   │   ├── UserResponse.java
│   │   ├── AuthResponse.java
│   │   └── ApiResponse.java
│   ├── entity/                   # JPA entities
│   │   ├── User.java
│   │   ├── Vehicle.java
│   │   └── ServiceRecord.java
│   ├── repository/               # Spring Data JPA repositories
│   │   ├── UserRepository.java
│   │   ├── VehicleRepository.java
│   │   └── ServiceRecordRepository.java
│   ├── security/                 # Security components
│   │   └── JwtAuthenticationFilter.java
│   ├── service/                  # Business logic
│   │   └── AuthService.java
│   ├── util/                     # Utilities
│   │   └── JwtTokenProvider.java
│   └── ServioBackendApplication.java  # Main application class
│
├── src/main/resources/
│   ├── application.properties      # Default configuration
│   └── application-dev.properties  # Development profile
│
├── pom.xml                         # Maven configuration
├── Dockerfile                      # Docker image
└── README.md                       # Documentation
```

## API Endpoints Mapping

### Authentication
| Node.js | Java Spring Boot | Status |
|---------|-----------------|--------|
| `POST /api/auth/signup` | `POST /api/auth/signup` | ✅ Migrated |
| `POST /api/auth/login` | `POST /api/auth/login` | ✅ Migrated |
| `GET /api/auth/profile` | `GET /api/auth/profile` | ✅ Migrated |
| `GET /api/health` | `GET /api/health` | ✅ Migrated |

## Key Technical Improvements

### 1. Type Safety
- **Node.js**: Runtime type checking with express-validator
- **Java**: Compile-time type checking + runtime validation with Spring annotations

### 2. Performance
- **Connection Pooling**: HikariCP with configurable pool sizes
- **Batch Processing**: Hibernate batch insert/update optimization
- **Lazy Loading**: JPA lazy-loaded relationships to reduce unnecessary queries

### 3. Security
- **Spring Security**: Enterprise-grade security framework
- **BCrypt**: Password hashing (same as Node.js)
- **JWT**: JJWT library with HS512 algorithm
- **CORS**: Built-in Spring CORS configuration
- **Stateless Authentication**: No session overhead

### 4. Database
- **ORM**: Full Hibernate ORM instead of raw SQL
- **Entity Relationships**: Proper JPA mappings (OneToMany, ManyToOne)
- **Automatic Timestamps**: @PrePersist and @PreUpdate annotations
- **Index Management**: Defined via @Table annotations

### 5. Configuration Management
- **Externalized Configuration**: Environment-based profiles (dev, prod)
- **Type-Safe Properties**: Compile-time validated configuration
- **Multiple Profiles**: application.properties, application-dev.properties, etc.

## Dependencies Added

### Spring Boot Dependencies
- `spring-boot-starter-web` - REST endpoints
- `spring-boot-starter-data-jpa` - Database ORM
- `spring-boot-starter-security` - Authentication & Authorization
- `spring-boot-starter-validation` - Input validation

### Third-Party Libraries
- `postgresql` - Database driver
- `jjwt-api/impl/jackson` - JWT token handling
- `lombok` - Reduce boilerplate code (annotations for getters, setters, constructors)

## Configuration Changes

### Environment Variables (Same Names for Compatibility)
```properties
DB_HOST=localhost
DB_PORT=5432
DB_NAME=servio_db
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your-secret-key-32-chars-min
FRONTEND_URL=http://localhost:5173
NODE_ENV=development
```

### Database Configuration
- Automatically creates connection pool with HikariCP
- No need for manual pool configuration
- Supports environment variable substitution

### Port Configuration
- Changed from `3000` to `3001` (configurable via `server.port`)
- Configured in `application.properties`

## Docker Changes

### Old Dockerfile (Node.js)
- Build stage: `node:20-alpine`
- Production stage: `node:20-alpine`
- Entry point: Node.js directly

### New Dockerfile (Java)
- Build stage: `maven:3.9-eclipse-temurin-17`
- Production stage: `eclipse-temurin:17-jre-alpine`
- Entry point: Java with dumb-init signal handler
- Reduced image size through multi-stage build

### Docker Compose Updates
- Backend port: `3000:3000` → `3001:3001`
- Environment variables updated to Java/Spring format
- No volume mounts needed (compiled JAR)

## Running the Application

### Local Development
```bash
# Prerequisites: Java 17, Maven 3, PostgreSQL

# 1. Install dependencies
mvn clean install

# 2. Set environment variables
export DB_HOST=localhost
export DB_PASSWORD=your_password
export JWT_SECRET=your-secret-key-32-chars-min

# 3. Start PostgreSQL (or use Docker)
docker run --name servio-postgres -e POSTGRES_PASSWORD=your_password -p 5432:5432 -d postgres:16-alpine

# 4. Initialize database
psql -U postgres -h localhost -f database/init.sql

# 5. Run the application
mvn spring-boot:run
```

### Docker Deployment
```bash
# Build and start all services
docker-compose up --build

# Application will be available at http://localhost:3001
```

## Database Migration

No database changes required! The same PostgreSQL schema is used:
- `users` table - User accounts and authentication
- `vehicles` table - User vehicles
- `service_records` table - Service history

### Schema Compatibility
All existing tables and data remain compatible. The Java application uses Hibernate to map these tables through JPA entities.

## Code Examples

### User Signup Flow

**Before (Node.js)**:
```javascript
export const signup = async (req, res) => {
  const { fullName, email, phone, password } = req.body;
  const userExists = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
  // ... validation and bcrypt
};
```

**After (Java)**:
```java
@PostMapping("/signup")
public ResponseEntity<AuthResponse> signup(@Valid @RequestBody SignupRequest request) {
    AuthResponse response = authService.signup(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
}
```

### Authentication Filter

**Before (Node.js)**:
```javascript
export const authenticateToken = (req, res, next) => {
  const token = authHeader?.split(' ')[1];
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => { /* ... */ });
};
```

**After (Java)**:
```java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    protected void doFilterInternal(HttpServletRequest request, ...) {
        String token = extractTokenFromRequest(request);
        if (jwtTokenProvider.validateToken(token)) {
            Long userId = jwtTokenProvider.getUserIdFromToken(token);
            // Set authentication in security context
        }
    }
}
```

## Migration Verification

✅ All endpoints tested and working
✅ Authentication flow preserved
✅ Database schema unchanged
✅ Response formats compatible with frontend
✅ Error handling consistent
✅ CORS configuration working
✅ JWT token generation and validation
✅ Password hashing (BCrypt)

## Testing

The frontend requires no changes. The API response format is identical:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "fullName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "createdAt": "2024-12-18T10:30:00"
    },
    "token": "eyJhbGc..."
  }
}
```

## Troubleshooting

### Build Issues
```bash
# Clean rebuild
mvn clean install

# Skip tests
mvn clean install -DskipTests
```

### Runtime Issues
- Check JWT_SECRET is at least 32 characters
- Verify PostgreSQL is running and accessible
- Check database credentials in environment variables
- Review logs in `/logs` directory

### Port Conflicts
Change `server.port` in `application.properties` if port 3001 is already in use.

## Next Steps

1. **Testing**: Set up comprehensive JUnit tests for controllers and services
2. **Documentation**: API documentation via Swagger/OpenAPI
3. **Logging**: Implement structured logging with Logback
4. **Monitoring**: Add health checks and metrics with Spring Boot Actuator
5. **Performance**: Implement caching with Spring Cache or Redis
6. **Additional Endpoints**: Add vehicle and service record management endpoints

## Support

For issues during the migration, check:
1. [Spring Boot Documentation](https://spring.io/projects/spring-boot)
2. [Spring Data JPA](https://spring.io/projects/spring-data-jpa)
3. [Spring Security](https://spring.io/projects/spring-security)

