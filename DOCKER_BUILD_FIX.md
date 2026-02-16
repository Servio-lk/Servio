# Docker Build Fix Guide - Maven Download Failures

## Problem

Your Docker build is failing with:
```
Could not transfer artifact net.bytebuddy:byte-buddy:jar:1.14.9
Premature end of Content-Length delimited message body
```

This means Maven dependency downloads are being interrupted.

## Quick Fixes (Try in Order)

### Fix 1: Use the Fix Script (Recommended)
```bash
cd /Users/chamindu/Documents/GitHub/Servio
./docker-fix.sh
```

This script will:
- Clean all containers and volumes
- Rebuild with the new retry logic
- Handle network interruptions automatically

### Fix 2: Manual Retry with Cleanup
```bash
# Stop everything
docker-compose down -v

# Clean Docker system
docker system prune -af

# Remove corrupted Maven cache volume
docker volume prune -f

# Try building again
docker-compose build --no-cache
```

### Fix 3: Build Backend Separately
```bash
# Stop containers
docker-compose down

# Build only backend with retry
docker-compose build --no-cache backend

# If successful, build frontend
docker-compose build --no-cache frontend

# Start everything
docker-compose up -d
```

### Fix 4: Use Local Maven Build (Fastest for Development)

Instead of Docker, build locally:

```bash
# Backend
cd backend
./mvnw clean package -DskipTests

# Frontend  
cd ../frontend
npm install
npm run build

# Then start with Docker (no build needed)
cd ..
docker-compose up -d
```

## Root Causes

1. **Network Issues**: Unstable internet connection
2. **Docker Hub Rate Limiting**: Too many pulls
3. **Maven Central Issues**: Repository temporarily slow
4. **Docker Cache Corruption**: Cached layers are incomplete

## Prevention

### Use BuildKit Cache Mounts

The updated Dockerfile now uses:
```dockerfile
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline
```

This caches Maven dependencies properly and survives build failures.

### Enable Docker BuildKit

Add to your shell profile:
```bash
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

Or add to `docker-compose.yml`:
```yaml
version: '3.8'

x-build-config:
  DOCKER_BUILDKIT: 1
```

## Alternative: Skip Docker for Now

For admin panel testing, you can skip Docker:

```bash
# Terminal 1: Start PostgreSQL only
docker-compose up -d database

# Terminal 2: Run backend locally
cd backend
./mvnw spring-boot:run

# Terminal 3: Run frontend locally  
cd frontend
npm run dev
```

This is actually **faster for development** and avoids build issues!

## Testing After Fix

```bash
# Check if containers are running
docker-compose ps

# Check backend logs
docker-compose logs backend

# Check if backend is healthy
curl http://localhost:8080/api/health

# Access frontend
open http://localhost:5173
```

## Updated Files

I've already updated:

1. ✅ `backend/Dockerfile` - Added retry logic for Maven
2. ✅ `docker-build.sh` - Improved build script with retries
3. ✅ `docker-fix.sh` - New quick fix script

## Recommended Approach for Admin Panel Testing

**Don't use Docker for initial testing!** It's slower and more complex.

Instead:

```bash
# 1. Apply database migration
psql -U servio_user -d servio_db -f database/admin-migration.sql

# 2. Start backend
cd backend
./mvnw spring-boot:run

# 3. Start frontend (new terminal)
cd frontend
npm run dev

# 4. Test admin panel
open http://localhost:5173/login
```

This will get you up and running in 2 minutes instead of fighting Docker builds!

## Docker is Optional

Docker is great for production, but for development and testing:
- ✅ Local runs are faster
- ✅ Easier to debug
- ✅ No build time
- ✅ Hot reload works better
- ✅ Direct access to logs

**Use Docker later when deploying to production.**

## Need More Help?

If still having issues:

1. Check internet connection
2. Try different network (mobile hotspot)
3. Wait 15 minutes and retry (Maven Central might be slow)
4. Use local development (skip Docker)

---

**Bottom Line**: For testing the admin panel, use local development. Docker can wait!
