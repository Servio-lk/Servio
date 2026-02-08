
Based on the project files, here are the instructions to run the application:

### Prerequisites
- Docker
- Java 17 or higher
- Maven 3.8.1 or higher
- Node.js and npm (for frontend local development)

---

### Option 1: Using Docker Compose (Recommended)

This is the easiest way to get the entire application running (database, backend, and frontend).

1. **Build and start all services:**
   Open a terminal in the root directory of the project and run:
   ```bash
   docker-compose up --build
   ```

2. **Access the application:**
   - The **frontend** will be available at: http://localhost
   - The **backend** API will be running on: http://localhost:8082
   - The **PostgreSQL database** will be accessible on port: 5433

3. **To stop the application:**
   Press `Ctrl + C` in the terminal where docker-compose is running, and then run:
   ```bash
   docker-compose down
   ```

---

### Option 2: Running Services Locally

Use this option if you want to run the frontend and backend services on your local machine without Docker containers (you can still use Docker for the database).

**1. Start the Database (using Docker):**
   ```bash
   docker-compose up -d postgres
   ```
   This will start only the PostgreSQL database container.

**2. Run the Backend (Java/Spring Boot):**
   - **Navigate to the backend directory:**
     ```bash
     cd backend
     ```
   - **Set Environment Variables:** You need to configure the database connection and JWT secret. On Windows (Command Prompt), you would use `set` instead of `export`.
     ```bash
     set DB_HOST=localhost
     set DB_PORT=5433
     set DB_NAME=servio_db
     set DB_USER=servio_user
     set DB_PASSWORD=servio_password
     set JWT_SECRET=your-secret-key-that-is-long-and-secure
     set FRONTEND_URL=http://localhost:5173
     ```
   - **Run the application using Maven:**
     ```bash
     mvn spring-boot:run
     ```
   The backend will start on http://localhost:8080 (if you run it locally without docker). Note that the docker-compose is configured to run the backend on 8082.

**3. Run the Frontend (React/Vite):**
   - **Navigate to the frontend directory:**
     ```bash
     cd frontend
     ```
   - **Install dependencies:**
     ```bash
     npm install
     ```
   - **Start the development server:**
     ```bash
     npm run dev
     ```
   The frontend will start on http://localhost:5173.
