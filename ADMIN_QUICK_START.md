# Admin Panel Implementation - Quick Start

## ✅ What Was Implemented

### Backend (Java/Spring Boot)
- ✅ Role-based authentication (CUSTOMER, ADMIN, STAFF)
- ✅ JWT tokens with role claims
- ✅ Admin API endpoints for services, offers, appointments, customers
- ✅ Method-level security with @PreAuthorize
- ✅ Admin service layer with CRUD operations
- ✅ Database migration script for role column

### Frontend (React/TypeScript)
- ✅ Admin panel UI with sidebar navigation
- ✅ Admin dashboard with statistics
- ✅ Services management (list, search, toggle active status)
- ✅ Offers management (list, view details)
- ✅ Appointments management (list, filter by status)
- ✅ Customers management (list, search)
- ✅ Admin route guards
- ✅ Role-based UI rendering

## 🚀 Getting Started

### Step 1: Apply Database Migration

```bash
cd /Users/chamindu/Documents/GitHub/Servio/database
psql -U servio_user -d servio_db -f admin-migration.sql
```

This will:
- Add `role` column to users table
- Create an admin user (admin@servio.com / admin123)
- Add necessary indexes

### Step 2: Build & Start Backend

```bash
cd /Users/chamindu/Documents/GitHub/Servio/backend
./mvnw clean install
./mvnw spring-boot:run
```

Backend will start on `http://localhost:8080`

### Step 3: Start Frontend

```bash
cd /Users/chamindu/Documents/GitHub/Servio/frontend
npm install  # Only if new dependencies were added
npm run dev
```

Frontend will start on `http://localhost:5173`

### Step 4: Access Admin Panel

1. Go to `http://localhost:5173/login`
2. Login with:
   - **Email**: admin@servio.com
   - **Password**: admin123
3. After login, navigate to `http://localhost:5173/admin`
4. You'll see the admin dashboard!

## 📋 Key Features

### Service Management
- **View all services** (active and inactive)
- **Toggle service status** with one click
- When toggled OFF → Service disappears from customer homepage
- When toggled ON → Service appears on customer homepage
- Search services by name or description

### Offers Management
- **View all promotional offers**
- See validity dates and discount details
- Identify active vs inactive offers

### Appointments Management
- **View all customer appointments**
- Filter by status (PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED)
- See customer details, service type, date/time
- Track costs (estimated vs actual)

### Customers Management
- **View all registered users**
- Search by name or email
- See user roles (CUSTOMER, ADMIN, STAFF)
- View registration dates

## 🔐 Security

- All `/api/admin/*` endpoints require `ADMIN` role
- JWT tokens include user role
- Frontend routes protected by `AdminGuard`
- Non-admin users redirected to homepage

## 📁 New Files Created

### Backend
```
backend/src/main/java/com/servio/
├── entity/
│   └── Role.java
├── dto/admin/
│   ├── ServiceRequest.java
│   ├── OfferRequest.java
│   ├── AppointmentUpdateRequest.java
│   └── ServiceToggleRequest.java
├── service/
│   ├── AdminServiceService.java
│   ├── AdminOfferService.java
│   ├── AdminAppointmentService.java
│   └── AdminCustomerService.java
├── controller/
│   ├── AdminServiceController.java
│   ├── AdminOfferController.java
│   ├── AdminAppointmentController.java
│   └── AdminCustomerController.java
└── util/
    └── PasswordHashGenerator.java

database/
└── admin-migration.sql
```

### Frontend
```
frontend/src/
├── components/
│   ├── AdminGuard.tsx
│   └── layouts/
│       └── AdminLayout.tsx
├── pages/admin/
│   ├── Dashboard.tsx
│   ├── Services.tsx
│   ├── Offers.tsx
│   ├── Appointments.tsx
│   └── Customers.tsx
└── services/
    └── adminApi.ts
```

### Documentation
```
ADMIN_PANEL_GUIDE.md
ADMIN_QUICK_START.md (this file)
```

## 🎯 How Service Toggle Works

```
Customer Visit → Homepage loads services
                 ↓
      Query: SELECT * FROM services WHERE is_active = true
                 ↓
      Shows only ACTIVE services to customer
                 
Admin Panel → Toggles service OFF
                 ↓
      PATCH /api/admin/services/{id}/toggle
      { "isActive": false }
                 ↓
      Database: UPDATE services SET is_active = false
                 ↓
Customer Refresh → Service no longer appears
```

## 🧪 Testing the Implementation

### Test 1: Service Toggle
1. Login as admin
2. Go to `/admin/services`
3. Note a service that's active
4. Click its status badge to toggle OFF
5. Open new tab, go to customer homepage
6. Verify service no longer appears
7. Go back to admin, toggle ON
8. Refresh customer page
9. Verify service reappears ✅

### Test 2: Admin Access Control
1. Logout
2. Create a new account (regular user)
3. Try to access `/admin`
4. Verify you're redirected to homepage ✅
5. Try calling `/api/admin/services` directly
6. Verify you get 403 Forbidden ✅

### Test 3: Appointments Filter
1. Login as admin
2. Go to `/admin/appointments`
3. Use status filter dropdown
4. Select "PENDING"
5. Verify only pending appointments show ✅

## 🐛 Troubleshooting

### Issue: Can't login as admin
**Solution**: Check database
```sql
SELECT id, email, role FROM users WHERE email = 'admin@servio.com';
```
Should show role = 'ADMIN'

### Issue: 403 Forbidden on admin endpoints
**Solution**: 
1. Check JWT token includes role claim
2. Open browser DevTools → Application → LocalStorage
3. Check 'user' object has `"role": "ADMIN"`

### Issue: Services not updating on customer side
**Solution**:
1. Check `isActive` column in database
2. Hard refresh customer page (Ctrl+Shift+R)
3. Check browser console for errors

### Issue: Admin pages showing blank
**Solution**:
1. Check browser console for errors
2. Verify backend is running on port 8080
3. Check CORS configuration allows frontend origin

## 📝 Next Steps

### Immediate TODOs
- [ ] Test the complete flow end-to-end
- [ ] Create/Edit service modals (not yet implemented)
- [ ] Create/Edit offer modals (not yet implemented)
- [ ] Appointment detail view with status update
- [ ] Add pagination for large datasets

### Future Enhancements
- [ ] Image upload for services/offers
- [ ] Bulk operations (select multiple, bulk toggle)
- [ ] Export data (CSV/Excel)
- [ ] Real-time notifications (WebSocket)
- [ ] Analytics dashboard with charts
- [ ] Email notifications
- [ ] Audit logs for admin actions

## 💡 Tips

1. **Development**: Use `admin@servio.com / admin123` for testing
2. **Production**: Change admin password and remove from migration
3. **Multiple Admins**: Manually update user role in database
4. **Staff Role**: Currently unused, can be implemented for limited access
5. **Service Icons**: Currently URL-based, consider implementing upload

## 📞 Support

If you encounter issues:
1. Check `ADMIN_PANEL_GUIDE.md` for detailed documentation
2. Verify all migration scripts ran successfully
3. Check backend logs for errors
4. Inspect browser console for frontend errors

---

**Status**: ✅ Ready to Test
**Version**: 1.0
**Date**: January 2026
