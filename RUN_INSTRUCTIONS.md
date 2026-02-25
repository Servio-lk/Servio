# Servio — Run Instructions

## Prerequisites

| Tool | Version |
|---|---|
| Docker & Docker Compose | Latest |
| Java | 17+ |
| Maven | 3.8+ |
| Node.js & npm | 18+ |

> The database is hosted on **Supabase** — no local database setup is required.

---

## Setup: Environment Variables

Before running with either option, configure the backend environment:

```bash
cp backend/.env.example backend/.env
```

Open `backend/.env` and fill in your Supabase credentials (DB host, user, password, Supabase URL, anon key, JWT secret, etc.).

---

## Option 1: Docker Compose (Recommended)

Runs the **backend** and **frontend** in containers. No local Java or Node.js install needed.

**1. Build and start all services:**
```bash
docker-compose up --build
```

**2. Access the application:**
| Service | URL |
|---|---|
| Frontend | http://localhost |
| Backend API | http://localhost:3001 |

**3. Stop the application:**
```bash
docker-compose down
```

> **Note:** The frontend Supabase vars (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`) are passed in from `backend/.env` via Docker Compose. Make sure they are set.

---

## Option 2: Run Locally (Without Docker)

Use this if you want to develop and hot-reload without containers.

### Backend (Spring Boot / Java)

**1. Navigate to the backend directory:**
```bash
cd backend
```

**2. Ensure `backend/.env` is configured** (see Setup above).

**3. Run the application:**
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn spring-boot:run
```

> The app reads `backend/.env` automatically via `spring-dotenv` — no manual env export needed.

The backend API will be available at: **http://localhost:3001**

---

### Frontend (React / Vite)

**1. Navigate to the frontend directory:**
```bash
cd frontend
```

**2. Install dependencies** (first time only):
```bash
npm install
```

**3. Start the development server:**
```bash
npm run dev
```

The frontend will be available at: **http://localhost:5173**

---

## Backend Quick Reference

### Start the backend (recommended — uses `run-backend.sh`)
```bash
./run-backend.sh
```

### Start the backend manually (from the repo root)
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn -f backend/pom.xml spring-boot:run
```

### Kill whatever is already on port 3001, then start
```bash
lsof -ti :3001 | xargs kill -9 2>/dev/null; ./run-backend.sh
```

### Check what's running on port 3001
```bash
lsof -i :3001
```

### Kill the process on port 3001 without restarting
```bash
lsof -ti :3001 | xargs kill -9 2>/dev/null
```

### Clean build (use when you make Java dependency changes)
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn -f backend/pom.xml clean package -DskipTests
```

### Run tests
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn -f backend/pom.xml test
```
