# Admin Panel Implementation Guide

## Overview
This document describes the admin panel implementation for Servio, which allows administrators to manage services, offers, appointments, and customers.

## Architecture

### Backend Changes

1. **Role-Based Access Control (RBAC)**
   - Added `Role` enum with values: `CUSTOMER`, `ADMIN`, `STAFF`
   - Updated `User` entity with `role` field (default: `CUSTOMER`)
   - JWT tokens now include user role in claims
   - Spring Security configured with method-level security (`@PreAuthorize`)

2. **Admin Endpoints** (All require `ADMIN` role)
   ```
   GET    /api/admin/services              - Get all services
   POST   /api/admin/services              - Create service
   PUT    /api/admin/services/{id}         - Update service
   PATCH  /api/admin/services/{id}/toggle  - Toggle service active status
   DELETE /api/admin/services/{id}         - Delete service
   
   GET    /api/admin/offers                - Get all offers
   POST   /api/admin/offers                - Create offer
   PUT    /api/admin/offers/{id}           - Update offer
   DELETE /api/admin/offers/{id}           - Delete offer
   
   GET    /api/admin/appointments          - Get all appointments
   GET    /api/admin/appointments?status=X - Filter by status
   PATCH  /api/admin/appointments/{id}     - Update appointment
   
   GET    /api/admin/customers             - Get all customers
   GET    /api/admin/customers?search=X    - Search customers
   ```

3. **New Backend Files**
   - `entity/Role.java` - Role enum
   - `dto/admin/*` - Admin-specific DTOs
   - `service/Admin*Service.java` - Admin service layer
   - `controller/Admin*Controller.java` - Admin controllers
   - `database/admin-migration.sql` - Database migration

### Frontend Changes

1. **Authentication Enhancement**
   - `AuthContext` now includes `isAdmin` flag
   - Added `AdminGuard` component for route protection
   - Login/signup responses include user role

2. **Admin UI Structure**
   ```
   /admin
   ├── /admin              → Dashboard (stats overview)
   ├── /admin/services     → Services management
   ├── /admin/offers       → Offers management
   ├── /admin/appointments → Appointments management
   └── /admin/customers    → Customers management
   ```

3. **New Frontend Files**
   - `components/AdminGuard.tsx` - Admin route protection
   - `components/layouts/AdminLayout.tsx` - Admin layout with sidebar
   - `services/adminApi.ts` - Admin API service
   - `pages/admin/*.tsx` - Admin pages

## Database Migration

Run this SQL to add role support:

```sql
-- Add role column
ALTER TABLE users 
ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER';

-- Add constraint
ALTER TABLE users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('CUSTOMER', 'ADMIN', 'STAFF'));

-- Create admin user (password: admin123)
INSERT INTO users (full_name, email, phone, password_hash, role, created_at, updated_at)
VALUES (
    'Admin User',
    'admin@servio.com',
    '+1234567890',
    '$2a$10$YourBCryptHashHere',
    'ADMIN',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Add index
CREATE INDEX idx_users_role ON users(role);
```

**Note:** You need to generate a proper BCrypt hash for the admin password. Use an online tool or run:
```java
BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
String hash = encoder.encode("admin123");
```

## Setup Instructions

### 1. Apply Database Migration
```bash
cd database
psql -U servio_user -d servio_db -f admin-migration.sql
```

### 2. Rebuild Backend
```bash
cd backend
mvn clean install
```

### 3. Start Backend
```bash
mvn spring-boot:run
```

### 4. Start Frontend
```bash
cd frontend
npm run dev
```

## Usage

### Creating an Admin User

**Option 1: Via Database**
Run the migration SQL with a proper BCrypt hash.

**Option 2: Via Signup + Manual Update**
1. Sign up normally at `/signup`
2. Update the user in database:
```sql
UPDATE users SET role = 'ADMIN' WHERE email = 'your@email.com';
```

### Accessing Admin Panel

1. Login with admin credentials at `/login`
2. Navigate to `/admin`
3. You'll see the admin dashboard with sidebar navigation

### Managing Services

**Toggle Service Status:**
1. Go to `/admin/services`
2. Click the status badge (Active/Inactive) to toggle
3. Inactive services won't appear on customer homepage

**Customer Impact:**
- When admin toggles service to INACTIVE → Service disappears from customer pages
- When admin toggles service to ACTIVE → Service appears on customer pages
- Changes are reflected immediately on next page load

### Managing Offers

1. Go to `/admin/offers`
2. View all offers with validity dates
3. Active offers appear on customer homepage

### Managing Appointments

1. Go to `/admin/appointments`
2. Filter by status (PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED)
3. View customer details and appointment information

### Managing Customers

1. Go to `/admin/customers`
2. Search by name or email
3. View customer roles and join dates

## Key Features

### Real-Time Synchronization
- **Customer pages** query only `isActive=true` services
- **Admin pages** see all services regardless of status
- When admin toggles service status, customers see changes on next page refresh
- No WebSocket implementation yet (can be added for real-time updates)

### Security
- All admin endpoints require `ADMIN` role in JWT
- Spring Security validates token and role on each request
- Non-admin users redirected to homepage if accessing `/admin/*`
- Unauthorized API requests return 403 Forbidden

### UI/UX
- Responsive admin layout with collapsible sidebar
- Mobile-friendly admin panel
- Real-time search and filtering
- Toast notifications for success/error messages
- Loading states for async operations

## Future Enhancements

### Phase 2
- [ ] Service creation/editing modal
- [ ] Offer creation/editing modal
- [ ] Image upload functionality
- [ ] Bulk operations (multi-select)
- [ ] Export data (CSV/PDF)

### Phase 3
- [ ] Staff role with limited permissions
- [ ] Audit logs for admin actions
- [ ] Real-time notifications (WebSocket)
- [ ] Analytics dashboard with charts
- [ ] Email notifications for appointment changes

### Phase 4
- [ ] Advanced search and filters
- [ ] Customer communication (send emails)
- [ ] Appointment calendar view
- [ ] Service scheduling/availability management
- [ ] Revenue reports and analytics

## Troubleshooting

### Admin Can't Login
- Check if user has `role = 'ADMIN'` in database
- Verify JWT includes role claim
- Check browser console for errors

### Services Not Updating on Customer Side
- Verify service `isActive` flag in database
- Check customer page is querying `isActive=true`
- Clear browser cache and refresh

### 403 Forbidden on Admin Endpoints
- Ensure JWT token is valid
- Verify user has `ADMIN` role
- Check Spring Security configuration

### Admin Routes Not Working
- Verify `AdminGuard` is properly configured
- Check React Router routes in `App.tsx`
- Ensure `AdminLayout` is imported correctly

## API Examples

### Toggle Service Status
```bash
curl -X PATCH http://localhost:8080/api/admin/services/1/toggle \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"isActive": false}'
```

### Get Pending Appointments
```bash
curl -X GET "http://localhost:8080/api/admin/appointments?status=PENDING" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Search Customers
```bash
curl -X GET "http://localhost:8080/api/admin/customers?search=john" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Technical Details

### JWT Token Structure
```json
{
  "sub": "123",           // User ID
  "role": "ADMIN",        // User role
  "iat": 1234567890,      // Issued at
  "exp": 1234654290       // Expiration (24h)
}
```

### Service Toggle Flow
```
Admin clicks toggle
    ↓
Frontend calls PATCH /api/admin/services/{id}/toggle
    ↓
Spring Security validates JWT + role
    ↓
AdminServiceController receives request
    ↓
AdminServiceService updates service.isActive
    ↓
Database updates services table
    ↓
Frontend refreshes service list
    ↓
Customer homepage queries only isActive=true
    ↓
Service appears/disappears on customer side
```

## Performance Considerations

- Admin endpoints fetch all data (no pagination yet)
- Consider adding pagination for large datasets
- Database indexes on `role`, `isActive`, `status` fields
- JWT validation on every request (stateless)

## Security Best Practices

✅ Implemented:
- Role-based access control
- JWT token validation
- BCrypt password hashing
- HTTPS ready (via reverse proxy)
- CORS configuration

⚠️ TODO:
- Rate limiting on admin endpoints
- Admin action audit logs
- Session timeout enforcement
- Two-factor authentication (2FA)

---

**Last Updated:** January 2026
**Version:** 1.0
