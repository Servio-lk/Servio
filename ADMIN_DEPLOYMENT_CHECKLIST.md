# Admin Panel - Deployment Checklist

## Pre-Deployment Checklist

### Database Setup ✅
- [ ] PostgreSQL database is running
- [ ] Database `servio_db` exists
- [ ] User `servio_user` has proper permissions
- [ ] Migration script executed: `admin-migration.sql`
- [ ] Admin user created in database
- [ ] Verify admin user role:
  ```sql
  SELECT email, role FROM users WHERE role = 'ADMIN';
  ```

### Backend Setup ✅
- [ ] Java 17 installed
- [ ] Maven installed (or use `./mvnw`)
- [ ] `application.properties` configured:
  - Database URL correct
  - JWT secret set (min 32 chars)
  - JWT expiration configured
- [ ] Backend builds without errors:
  ```bash
  cd backend
  ./mvnw clean install
  ```
- [ ] All admin controllers created
- [ ] All admin services created
- [ ] Security configuration updated

### Frontend Setup ✅
- [ ] Node.js 18+ installed
- [ ] Dependencies installed:
  ```bash
  cd frontend
  npm install
  ```
- [ ] Admin pages created
- [ ] Admin routes configured in `App.tsx`
- [ ] AdminGuard component created
- [ ] AuthContext updated with `isAdmin`
- [ ] Frontend builds without errors:
  ```bash
  npm run build
  ```

---

## Development Deployment

### Step 1: Start Database
```bash
# If using Docker
docker start servio-postgres

# Or check if running
psql -U servio_user -d servio_db -c "SELECT 1;"
```

### Step 2: Apply Migration
```bash
cd /Users/chamindu/Documents/GitHub/Servio/database
psql -U servio_user -d servio_db -f admin-migration.sql
```

**Verify**:
```sql
-- Check role column exists
\d users

-- Check admin user exists
SELECT * FROM users WHERE role = 'ADMIN';
```

### Step 3: Start Backend
```bash
cd /Users/chamindu/Documents/GitHub/Servio/backend
./mvnw spring-boot:run
```

**Wait for**:
```
Started ServioBackendApplication in X.XXX seconds
```

**Verify**:
```bash
curl http://localhost:8080/api/health
# Should return: {"status":"UP","timestamp":"..."}
```

### Step 4: Start Frontend
```bash
cd /Users/chamindu/Documents/GitHub/Servio/frontend
npm run dev
```

**Wait for**:
```
  ➜  Local:   http://localhost:5173/
  ➜  Network: http://192.168.x.x:5173/
```

### Step 5: Test Admin Access
1. Open browser: `http://localhost:5173/login`
2. Login: `admin@servio.com` / `admin123`
3. Navigate to: `http://localhost:5173/admin`
4. Verify dashboard loads ✅

---

## Production Deployment (Docker)

### Prerequisites
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] Environment variables configured

### Step 1: Update docker-compose.yml

Add environment variables for admin:
```yaml
backend:
  environment:
    - JWT_SECRET=${JWT_SECRET:-your-secret-key-min-32-chars-here}
    - JWT_EXPIRATION=86400000  # 24 hours
```

### Step 2: Build Images
```bash
cd /Users/chamindu/Documents/GitHub/Servio
docker-compose build
```

### Step 3: Start Services
```bash
docker-compose up -d
```

### Step 4: Apply Migration
```bash
docker-compose exec database psql -U servio_user -d servio_db -f /docker-entrypoint-initdb.d/admin-migration.sql
```

Or copy migration file:
```bash
docker cp database/admin-migration.sql servio-database:/tmp/
docker-compose exec database psql -U servio_user -d servio_db -f /tmp/admin-migration.sql
```

### Step 5: Verify Deployment
```bash
# Check all containers running
docker-compose ps

# Check backend logs
docker-compose logs backend

# Check frontend is accessible
curl http://localhost:5173

# Check backend health
curl http://localhost:8080/api/health
```

---

## Environment Variables

### Backend (.env or application.properties)
```properties
# Database
SPRING_DATASOURCE_URL=jdbc:postgresql://database:5432/servio_db
SPRING_DATASOURCE_USERNAME=servio_user
SPRING_DATASOURCE_PASSWORD=your_password

# JWT Configuration
JWT_SECRET=your-very-secure-secret-key-minimum-32-characters-long
JWT_EXPIRATION=86400000

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://your-domain.com

# Server
SERVER_PORT=8080
```

### Frontend (.env)
```bash
VITE_API_URL=http://localhost:8080/api
```

---

## Security Hardening (Production)

### Change Default Admin Password
```sql
-- Generate new password hash (use PasswordHashGenerator.java)
-- Then update:
UPDATE users 
SET password_hash = '$2a$10$NEW_HASH_HERE'
WHERE email = 'admin@servio.com';
```

### Remove Test Admin (Optional)
```sql
-- If you want to use a different email
DELETE FROM users WHERE email = 'admin@servio.com';

-- Then promote existing user to admin
UPDATE users SET role = 'ADMIN' WHERE email = 'your@email.com';
```

### Configure HTTPS
Update nginx.conf (frontend):
```nginx
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    # ... rest of config
}
```

### Set Strong JWT Secret
```bash
# Generate secure random string
openssl rand -base64 48
```

Use this as `JWT_SECRET` in production.

---

## Post-Deployment Verification

### Functional Tests
- [ ] Can access frontend at configured URL
- [ ] Can login as admin user
- [ ] Can access `/admin` route
- [ ] Dashboard loads with statistics
- [ ] Services page displays all services
- [ ] Can toggle service status
- [ ] Toggle affects customer homepage ⭐
- [ ] Offers page loads
- [ ] Appointments page loads with filter
- [ ] Customers page loads with search
- [ ] Non-admin users blocked from admin routes
- [ ] Logout works correctly

### API Tests
```bash
# Login as admin
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@servio.com","password":"admin123"}'
# Copy token from response

# Test admin endpoint
curl -X GET http://localhost:8080/api/admin/services \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
# Should return all services

# Test toggle endpoint
curl -X PATCH http://localhost:8080/api/admin/services/1/toggle \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"isActive":false}'
# Should update service status
```

### Performance Tests
```bash
# Test response time
time curl http://localhost:8080/api/health

# Test under load (optional)
ab -n 1000 -c 10 http://localhost:8080/api/health
```

### Security Tests
- [ ] Cannot access admin routes without token
- [ ] Cannot access admin routes with customer token
- [ ] Invalid JWT returns 401/403
- [ ] CORS only allows configured origins
- [ ] Password hashing works (check database)

---

## Monitoring Setup (Optional)

### Application Logs
```bash
# Backend logs
docker-compose logs -f backend | grep ERROR

# Frontend logs
docker-compose logs -f frontend

# Database logs
docker-compose logs -f database
```

### Health Checks
```bash
# Backend health
curl http://localhost:8080/api/health

# Database health
docker-compose exec database pg_isready -U servio_user
```

### Metrics (Future Enhancement)
- Add Spring Boot Actuator
- Configure Prometheus
- Set up Grafana dashboards

---

## Rollback Plan

If deployment fails:

### Quick Rollback
```bash
# Stop containers
docker-compose down

# Restore previous version
git checkout previous-tag
docker-compose up -d
```

### Database Rollback
```sql
-- If role column causes issues, remove it
ALTER TABLE users DROP COLUMN IF EXISTS role;

-- Remove admin-specific data if needed
-- (Be careful with this!)
```

---

## Common Deployment Issues

### Issue 1: Admin User Can't Login
**Symptom**: 401 error on login

**Fix**:
```sql
-- Check if admin user exists with correct role
SELECT id, email, role FROM users WHERE email = 'admin@servio.com';

-- If role is wrong
UPDATE users SET role = 'ADMIN' WHERE email = 'admin@servio.com';

-- If password is wrong, regenerate hash and update
```

### Issue 2: 403 Forbidden on Admin Endpoints
**Symptom**: JWT token valid but access denied

**Fix**:
- Check JWT includes role claim
- Verify Spring Security configuration
- Check `@PreAuthorize("hasAuthority('ADMIN')")` annotations

### Issue 3: CORS Errors
**Symptom**: Browser blocks requests

**Fix**:
```java
// In CorsConfig.java or SecurityConfig.java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(Arrays.asList("http://localhost:5173"));
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setAllowCredentials(true);
    // ... rest of config
}
```

### Issue 4: Database Connection Failed
**Symptom**: Backend can't connect to database

**Fix**:
```bash
# Check database is running
docker-compose ps database

# Check connection string
# Verify username/password in application.properties

# Test connection manually
psql -h localhost -p 5432 -U servio_user -d servio_db
```

### Issue 5: Frontend Can't Reach Backend
**Symptom**: API calls fail from frontend

**Fix**:
```javascript
// Check API URL in frontend
// In adminApi.ts and api.ts
const API_BASE_URL = 'http://localhost:8080/api';

// Or use environment variable
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';
```

---

## Performance Optimization

### Backend Optimizations
```properties
# In application.properties

# Connection pool
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5

# JPA
spring.jpa.hibernate.ddl-auto=validate  # Don't auto-create in prod
spring.jpa.show-sql=false  # Disable SQL logging

# Caching (future enhancement)
spring.cache.type=caffeine
```

### Frontend Optimizations
```bash
# Build optimized production bundle
npm run build

# Result in dist/ folder
# Serve with nginx or CDN
```

### Database Optimizations
```sql
-- Ensure indexes exist
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_services_active ON services(is_active);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);

-- Analyze tables
ANALYZE users;
ANALYZE services;
ANALYZE appointments;
```

---

## Backup Strategy

### Database Backup
```bash
# Backup before deployment
docker-compose exec database pg_dump -U servio_user servio_db > backup_$(date +%Y%m%d).sql

# Restore if needed
docker-compose exec -T database psql -U servio_user servio_db < backup_20260120.sql
```

### Code Backup
```bash
# Tag release
git tag -a v1.0-admin-panel -m "Admin panel implementation"
git push origin v1.0-admin-panel

# Create backup branch
git checkout -b backup/pre-admin-deployment
git push origin backup/pre-admin-deployment
```

---

## Success Metrics

Track these after deployment:

- [ ] Admin panel uptime: > 99%
- [ ] Average response time: < 500ms
- [ ] No unauthorized access attempts
- [ ] Zero data breaches
- [ ] Admin user satisfaction
- [ ] Service toggle feature usage
- [ ] Customer impact (services hidden/shown)

---

## Final Checklist Before Going Live

- [ ] All tests pass (see ADMIN_TESTING_GUIDE.md)
- [ ] Admin password changed from default
- [ ] JWT secret is strong and unique
- [ ] HTTPS configured (if production)
- [ ] CORS properly configured
- [ ] Database backed up
- [ ] Code tagged in git
- [ ] Documentation reviewed
- [ ] Team trained on admin panel
- [ ] Rollback plan ready
- [ ] Monitoring in place

---

## Deployment Complete! 🎉

Once all checks pass:

1. **Announce to team**: Admin panel is live
2. **Train admins**: Show them the interface
3. **Monitor**: Watch logs for first 24 hours
4. **Collect feedback**: From admin users
5. **Plan Phase 2**: Based on feedback

---

**Your admin panel is now production-ready!**

Access it at: `http://your-domain.com/admin`

Login with your admin credentials and start managing services!

---

*Deployment Version: 1.0*
*Last Updated: January 2026*
