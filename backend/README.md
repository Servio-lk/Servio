# Servio Backend API - Java Spring Boot

The backend API for Servio, a vehicle service management application, built with Spring Boot 3.

## Prerequisites

- Java 17 or higher
- Maven 3.8.1 or higher
- PostgreSQL 12 or higher (for local development)
- Docker & Docker Compose (for containerized deployment)

## Project Structure

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/servio/
│   │   │   ├── config/          # Spring configuration classes
│   │   │   ├── controller/      # REST controllers
│   │   │   ├── dto/             # Data Transfer Objects
│   │   │   ├── entity/          # JPA entities
│   │   │   ├── repository/      # Spring Data JPA repositories
│   │   │   ├── security/        # Security filters and components
│   │   │   ├── service/         # Business logic services
│   │   │   ├── util/            # Utility classes
│   │   │   └── ServioBackendApplication.java  # Main application class
│   │   └── resources/
│   │       └── application.properties  # Application configuration
│   └── test/
├── pom.xml                      # Maven configuration
├── Dockerfile                   # Docker image configuration
└── README.md                    # This file
```

## Development Setup

### 1. Install Dependencies

```bash
mvn clean install
```

### 2. Configure Environment Variables

Create a `.env` file or set the following environment variables:

```properties
DB_HOST=localhost
DB_PORT=5432
DB_NAME=servio_db
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your-secret-key-at-least-32-characters-long
FRONTEND_URL=http://localhost:5173
NODE_ENV=development
```

### 3. Setup PostgreSQL Database

For local development, start PostgreSQL and initialize the database:

```bash
# Using Docker
docker run --name servio-postgres -e POSTGRES_PASSWORD=your_password -p 5432:5432 -d postgres:16-alpine

# Initialize database
psql -U postgres -h localhost -f database/init.sql
```

### 4. Run the Application

```bash
# Development mode with hot reload
mvn spring-boot:run

# Or build and run JAR
mvn clean package
java -jar target/servio-backend-1.0.0.jar
```

The API will be available at `http://localhost:3001`

## API Endpoints

### Authentication

**POST** `/api/auth/signup`
- Register a new user
- Request body:
  ```json
  {
    "fullName": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "password": "secure_password_123"
  }
  ```

**POST** `/api/auth/login`
- Login user
- Request body:
  ```json
  {
    "email": "john@example.com",
    "password": "secure_password_123"
  }
  ```

**GET** `/api/auth/profile`
- Get current user profile (requires JWT token)
- Headers: `Authorization: Bearer <token>`

### Health

**GET** `/api/health`
- Health check endpoint
- No authentication required

## Security

- Passwords are hashed using BCrypt
- JWT (JSON Web Tokens) are used for authentication
- CORS is configured to allow requests from the frontend
- All sensitive endpoints require authentication

## Technologies

- **Spring Boot 3.1.5** - Web framework
- **Spring Data JPA** - Database ORM
- **Spring Security** - Authentication & Authorization
- **PostgreSQL** - Database
- **JWT (JJWT)** - Token-based authentication
- **BCrypt** - Password hashing
- **Lombok** - Reduce boilerplate code
- **Maven** - Dependency management & build tool

## Docker Deployment

### Build the Image

```bash
docker build -t servio-backend:latest .
```

### Run with Docker Compose

```bash
docker-compose up -d
```

The backend will be available at `http://localhost:3001`

## Building for Production

```bash
# Build with Maven
mvn clean package -DskipTests

# The JAR file will be in target/servio-backend-1.0.0.jar
```

## Troubleshooting

### Port Already in Use
Change the port in `application.properties`:
```properties
server.port=3002
```

### Database Connection Failed
Verify database credentials and PostgreSQL is running:
```bash
psql -h localhost -U postgres -d servio_db
```

### JWT Token Invalid
Ensure the JWT_SECRET environment variable is set and is at least 32 characters long.

## Contributing

When adding new endpoints or modifying existing ones:
1. Add DTOs for request/response in `dto/` package
2. Create or update controllers in `controller/` package
3. Implement business logic in `service/` package
4. Use repositories for database access
5. Write tests for new functionality

## License

ISC
