# Servio - Dockerized Application

## 🚀 Quick Start with Docker

### Prerequisites
- Docker Desktop installed and running
- Docker Compose (comes with Docker Desktop)

### Running the Application

1. **Clone the repository** (if not already done)
   ```bash
   git clone <repository-url>
   cd Servio
   ```

2. **Set up environment variables** (optional)
   ```bash
   cp .env.example .env
   # Edit .env and update JWT_SECRET for production
   ```

3. **Build and start all services**
   ```bash
   docker-compose up --build
   ```

   Or run in detached mode:
   ```bash
   docker-compose up --build -d
   ```

4. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:3001
   - Database: localhost:5433 (PostgreSQL)

### Useful Docker Commands

#### View running containers
```bash
docker-compose ps
```

#### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres
```

#### Stop all services
```bash
docker-compose stop
```

#### Stop and remove containers
```bash
docker-compose down
```

#### Stop and remove containers + volumes (⚠️ deletes database data)
```bash
docker-compose down -v
```

#### Rebuild specific service
```bash
docker-compose up --build backend
docker-compose up --build frontend
```

#### Access container shell
```bash
docker-compose exec backend sh
docker-compose exec frontend sh
docker-compose exec postgres psql -U servio_user -d servio_db
```

#### Check service health
```bash
docker-compose ps
curl http://localhost:3001/api/health
```

### Architecture

The application consists of three services:

1. **Frontend** (Port 3000)
   - React + TypeScript + Vite
   - Served by Nginx
   - Production-optimized build

2. **Backend** (Port 3001)
   - Node.js + Express API
   - Health checks enabled
   - Connected to PostgreSQL

3. **Database** (Port 5433)
   - PostgreSQL 16
   - Auto-initialized with schema
   - Persistent data volume

### Development vs Production

#### Development (Local)
- Run services individually with hot reload
- Backend: `cd backend && npm run dev`
- Frontend: `cd frontend && npm run dev`

#### Production (Docker)
- Optimized builds
- Multi-stage Dockerfiles
- Health checks enabled
- Persistent volumes
- Isolated network

### Troubleshooting

#### Port already in use
If ports 3000, 3001, or 5433 are already in use:
1. Stop conflicting services
2. Or modify ports in docker-compose.yml

#### Database connection issues
- Ensure database is healthy: `docker-compose ps`
- Check logs: `docker-compose logs postgres`
- Wait for initialization to complete (~10-20 seconds)

#### Frontend not loading
- Check if backend is healthy
- Verify CORS settings
- Check browser console for errors

#### Clean restart
```bash
docker-compose down -v
docker-compose up --build
```

### Security Notes

⚠️ **IMPORTANT for Production:**
1. Change `JWT_SECRET` in `.env` file
2. Use strong database credentials
3. Enable HTTPS (add reverse proxy like Traefik/Nginx)
4. Set `NODE_ENV=production`
5. Review and update CORS settings
6. Use secrets management (Docker secrets, AWS Secrets Manager, etc.)

### Database Backup

```bash
# Backup
docker-compose exec postgres pg_dump -U servio_user servio_db > backup.sql

# Restore
docker-compose exec -T postgres psql -U servio_user servio_db < backup.sql
```

## 📝 Additional Resources

- Backend README: [backend/README.md](backend/README.md)
- Frontend README: [frontend/README.md](frontend/README.md)
- Database README: [database/README.md](database/README.md)
