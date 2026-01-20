# Quick Start Guide - Java Backend

## Prerequisites Check

Verify you have the required tools installed:

```bash
# Check Java version (need 17+)
java -version

# Check Maven version (need 3.8+)
mvn --version

# Check PostgreSQL (need 12+)
psql --version

# Or use Docker for PostgreSQL
docker --version
```

## Option 1: Docker Compose (Simplest)

This starts everything: PostgreSQL, Java backend, and frontend.

```bash
# From root directory of Servio
docker-compose up --build

# Wait for all services to be healthy
# Backend: http://localhost:3001
# Frontend: http://localhost
# API Health: http://localhost:3001/api/health
```

Stop everything:
```bash
docker-compose down
```

## Option 2: Local Development (Detailed Control)

### Step 1: Start PostgreSQL

Using Docker:
```bash
docker run --name servio-postgres \
  -e POSTGRES_USER=servio_user \
  -e POSTGRES_PASSWORD=servio_password \
  -e POSTGRES_DB=servio_db \
  -p 5432:5432 \
  -d postgres:16-alpine

# Initialize database
psql -h localhost -U servio_user -d servio_db -f database/init.sql
# Password: servio_password
```

Or using local PostgreSQL:
```bash
# Create database
createdb -U postgres servio_db

# Initialize schema
psql -U postgres -d servio_db -f database/init.sql
```

### Step 2: Build the Backend

```bash
cd backend

# Install dependencies and build
mvn clean install

# This may take a few minutes on first run
```

### Step 3: Run the Backend

```bash
# From backend directory

# Development mode with hot reload
mvn spring-boot:run

# Or build and run as JAR
mvn clean package
java -jar target/servio-backend-1.0.0.jar
```

The backend will start on `http://localhost:3001`

### Step 4: Verify It's Running

```bash
# Check health endpoint
curl http://localhost:3001/api/health

# Expected response:
# {
#   "success": true,
#   "message": "Server is running",
#   "data": {
#     "status": "Server is running",
#     "database": "Connected",
#     "timestamp": "2024-12-18T10:30:00"
#   }
# }
```

### Step 5: Start Frontend

In a new terminal:
```bash
cd frontend
npm install
npm run dev

# Frontend runs on http://localhost:5173
```

## Testing the API

### Test Signup
```bash
curl -X POST http://localhost:3001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "password": "password123"
  }'
```

Expected response (201 Created):
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 1,
      "fullName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "createdAt": "2024-12-18T10:30:00"
    },
    "token": "eyJhbGciOiJIUzUxMiJ9..."
  }
}
```

### Test Login
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Get User Profile (Protected)
```bash
# Use the token from login response
TOKEN="eyJhbGciOiJIUzUxMiJ9..."

curl -X GET http://localhost:3001/api/auth/profile \
  -H "Authorization: Bearer $TOKEN"
```

## Troubleshooting

### Port 3001 Already in Use
```bash
# Change port in backend/src/main/resources/application.properties
server.port=3002
```

### Build Fails
```bash
# Clear Maven cache
mvn clean
rm -rf ~/.m2/repository/com/servio/

# Rebuild
mvn clean install -U
```

### Cannot Connect to PostgreSQL
```bash
# Verify PostgreSQL is running
psql -h localhost -U postgres -c "SELECT version();"

# Or check Docker container
docker ps | grep postgres

# If not running:
docker start servio-postgres
```

### JWT Token Issues
```bash
# Ensure JWT_SECRET is set and long enough (32+ chars)
export JWT_SECRET="my-very-long-secret-key-that-is-at-least-32-characters"
```

### Frontend Can't Reach Backend
```bash
# Check CORS is enabled for frontend URL
# Edit: backend/src/main/resources/application.properties
# Change: cors.allowed-origins=http://localhost:5173

# Or via environment variable
export FRONTEND_URL=http://localhost:5173
```

## Project Structure

```
backend/
├── src/main/
│   ├── java/com/servio/
│   │   ├── config/          # Spring configuration
│   │   ├── controller/      # REST controllers
│   │   ├── dto/             # Data transfer objects
│   │   ├── entity/          # Database entities
│   │   ├── repository/      # Database access
│   │   ├── security/        # JWT & security
│   │   ├── service/         # Business logic
│   │   └── util/            # Utilities
│   └── resources/
│       ├── application.properties
│       └── application-dev.properties
├── pom.xml                  # Maven configuration
├── Dockerfile               # Docker image
└── README.md               # Full documentation
```

## Key Files

- **pom.xml**: All dependencies (Spring Boot, JWT, PostgreSQL, etc.)
- **src/main/java/com/servio/config/**: Configuration classes
- **src/main/java/com/servio/controller/**: REST endpoints
- **src/main/java/com/servio/service/**: Business logic
- **src/main/resources/application.properties**: Configuration
- **Dockerfile**: Production image definition

## Next Steps

1. ✅ Backend is running
2. ✅ API endpoints are working
3. Start the frontend: `cd frontend && npm run dev`
4. Test at `http://localhost:5173`

## Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Security](https://spring.io/projects/spring-security)
- [Spring Data JPA](https://spring.io/projects/spring-data-jpa)
- [Project README](/backend/README.md)
- [Migration Details](/backend/MIGRATION.md)

## Environment Variables

```
# Required for Database
DB_HOST=localhost              # PostgreSQL host
DB_PORT=5432                   # PostgreSQL port
DB_NAME=servio_db              # Database name
DB_USER=servio_user            # Database user
DB_PASSWORD=servio_password    # Database password

# Required for JWT
JWT_SECRET=your-32-char-secret # Must be 32+ characters

# Optional
FRONTEND_URL=http://localhost:5173  # Frontend URL for CORS
NODE_ENV=development                # Environment (dev/prod)
```

## Support

For detailed information, see:
- [Backend README](./backend/README.md)
- [Migration Guide](./backend/MIGRATION.md)
