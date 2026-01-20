# Admin Panel - Testing Guide

## Pre-Testing Checklist

Before you start testing, ensure:
- ✅ Database migration has been applied (`admin-migration.sql`)
- ✅ Backend is running on port 8080
- ✅ Frontend is running on port 5173
- ✅ Admin user exists in database (admin@servio.com)

---

## Test Suite

### Test 1: Admin Login ✅

**Objective**: Verify admin user can login with correct credentials

**Steps**:
1. Open browser: `http://localhost:5173/login`
2. Enter credentials:
   - Email: `admin@servio.com`
   - Password: `admin123`
3. Click "Login"

**Expected Result**:
- ✅ Redirected to `/home` page
- ✅ No errors in console
- ✅ Token stored in localStorage

**How to Verify**:
```javascript
// Open browser DevTools Console
localStorage.getItem('token')  // Should show JWT token
localStorage.getItem('user')   // Should show user object with "role": "ADMIN"
```

---

### Test 2: Admin Panel Access ✅

**Objective**: Verify admin user can access admin panel

**Steps**:
1. After logging in, navigate to: `http://localhost:5173/admin`
2. Observe the page

**Expected Result**:
- ✅ Admin dashboard loads
- ✅ Dark sidebar with navigation menu visible
- ✅ Dashboard shows 4 stat cards
- ✅ User profile in sidebar shows "Admin User"

**Screenshots to Take**:
- Dashboard overview
- Sidebar navigation

---

### Test 3: Non-Admin Access Blocked ✅

**Objective**: Verify regular users cannot access admin panel

**Steps**:
1. Logout from admin account
2. Create new account or login as regular user
3. Try to access: `http://localhost:5173/admin`

**Expected Result**:
- ✅ Automatically redirected to `/home`
- ✅ Cannot access admin panel
- ✅ Console shows no errors (just redirect)

**API Test**:
```bash
# Try to access admin API without admin role
curl -X GET "http://localhost:8080/api/admin/services" \
  -H "Authorization: Bearer <REGULAR_USER_TOKEN>"
```

**Expected**: `403 Forbidden` response

---

### Test 4: Service Management - View Services ✅

**Objective**: Verify services page loads and displays all services

**Steps**:
1. Login as admin
2. Navigate to `/admin/services`
3. Observe the services table

**Expected Result**:
- ✅ Services table loads with all services
- ✅ Shows both active and inactive services
- ✅ Each row shows: name, category, price, duration, status
- ✅ Status badges are color-coded (green = active, gray = inactive)
- ✅ Search bar is functional

**Database Verification**:
```sql
SELECT name, is_active FROM services ORDER BY name;
```

---

### Test 5: Service Toggle - Core Feature ⭐

**Objective**: Verify toggling service affects customer homepage

**Steps**:
1. Login as admin
2. Go to `/admin/services`
3. Note a service that is currently ACTIVE (e.g., "Oil Change")
4. Click the green "Active" badge to toggle it OFF
5. Wait for success toast notification
6. Open NEW BROWSER TAB (incognito or different browser)
7. Login as regular customer
8. Go to customer homepage
9. Search for the service you toggled off

**Expected Result**:
- ✅ Service status changes to INACTIVE (gray badge)
- ✅ Toast shows "Service deactivated successfully"
- ✅ Service NO LONGER appears on customer homepage
- ✅ Service is NOT in service list for customers

**Verification**:
```sql
-- Check database
SELECT id, name, is_active FROM services WHERE name = 'Oil Change';
-- Should show is_active = false
```

**Reverse Test**:
1. Toggle service back ON in admin panel
2. Refresh customer homepage
3. Service should reappear ✅

**API Test**:
```bash
# Customer endpoint (should exclude inactive)
curl -X GET "http://localhost:8080/api/services"

# Admin endpoint (should include all)
curl -X GET "http://localhost:8080/api/admin/services" \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```

---

### Test 6: Service Search ✅

**Objective**: Verify search functionality works

**Steps**:
1. In admin services page
2. Type "Oil" in search box
3. Observe results

**Expected Result**:
- ✅ Only services matching "Oil" are shown
- ✅ Search is case-insensitive
- ✅ Searches both name and description
- ✅ Clear search shows all services again

---

### Test 7: Offers Management ✅

**Objective**: Verify offers page displays all offers

**Steps**:
1. Navigate to `/admin/offers`
2. Observe the offers grid

**Expected Result**:
- ✅ Offers displayed in card grid layout
- ✅ Each card shows: title, subtitle, discount, validity
- ✅ Status badge shows active/inactive
- ✅ Images displayed if available

**Database Check**:
```sql
SELECT title, discount_value, is_active FROM offers;
```

---

### Test 8: Appointments Management ✅

**Objective**: Verify appointments page and filtering

**Steps**:
1. Navigate to `/admin/appointments`
2. Observe the appointments table
3. Use status filter dropdown
4. Select "PENDING"

**Expected Result**:
- ✅ All appointments load in table
- ✅ Shows customer name, email, service type, date
- ✅ Status badges are color-coded
- ✅ Filter shows only PENDING appointments
- ✅ "All Status" shows everything

**Database Check**:
```sql
SELECT id, status, service_type FROM appointments ORDER BY created_at DESC;
```

---

### Test 9: Customers Management ✅

**Objective**: Verify customers page and search

**Steps**:
1. Navigate to `/admin/customers`
2. Observe the customers table
3. Use search box to search for a name
4. Check statistics cards at bottom

**Expected Result**:
- ✅ All users displayed in table
- ✅ Shows name, email, phone, role, join date
- ✅ Admin users have purple badge
- ✅ Search filters results
- ✅ Statistics show correct counts

**Database Check**:
```sql
SELECT full_name, email, role FROM users;
```

---

### Test 10: Dashboard Statistics ✅

**Objective**: Verify dashboard shows correct statistics

**Steps**:
1. Go to `/admin` (dashboard)
2. Observe the 4 stat cards
3. Click "Manage Services" quick action
4. Click "View Appointments" quick action

**Expected Result**:
- ✅ Total Services count is accurate
- ✅ Active Services count matches active services
- ✅ Offers count is correct
- ✅ Pending Appointments count is accurate
- ✅ Total Customers count matches users
- ✅ Quick actions navigate correctly

**Manual Count Verification**:
```sql
-- Services
SELECT COUNT(*) FROM services;
SELECT COUNT(*) FROM services WHERE is_active = true;

-- Offers
SELECT COUNT(*) FROM offers;

-- Appointments
SELECT COUNT(*) FROM appointments WHERE status = 'PENDING';

-- Customers
SELECT COUNT(*) FROM users;
```

---

### Test 11: Responsive Design ✅

**Objective**: Verify admin panel works on mobile

**Steps**:
1. Open browser DevTools
2. Toggle device toolbar (mobile view)
3. Navigate through admin panel
4. Test sidebar menu

**Expected Result**:
- ✅ Sidebar collapses to hamburger menu
- ✅ Tables scroll horizontally on mobile
- ✅ Cards stack vertically
- ✅ All functionality works
- ✅ Touch-friendly buttons

---

### Test 12: Logout Functionality ✅

**Objective**: Verify logout clears session

**Steps**:
1. In admin panel, click "Logout" button in sidebar
2. Observe result
3. Try to access `/admin` again

**Expected Result**:
- ✅ Redirected to login page
- ✅ localStorage token cleared
- ✅ Cannot access admin panel anymore
- ✅ Must login again

**Verification**:
```javascript
// After logout
localStorage.getItem('token')  // Should be null
localStorage.getItem('user')   // Should be null
```

---

### Test 13: JWT Token Validation ✅

**Objective**: Verify expired/invalid tokens are rejected

**Steps**:
1. Login as admin
2. Copy JWT token from localStorage
3. Modify the token (change a character)
4. Replace in localStorage
5. Try to access admin endpoint

**Expected Result**:
- ✅ Request fails with 401/403
- ✅ User logged out automatically
- ✅ Redirected to login

**API Test**:
```bash
curl -X GET "http://localhost:8080/api/admin/services" \
  -H "Authorization: Bearer invalid_token_here"
```

**Expected**: 401 Unauthorized or 403 Forbidden

---

### Test 14: CORS Validation ✅

**Objective**: Verify CORS is properly configured

**Steps**:
1. Check browser console for CORS errors
2. Verify requests from localhost:5173 work
3. Try from different origin (should fail)

**Expected Result**:
- ✅ No CORS errors in console
- ✅ All API calls succeed from frontend
- ✅ Proper headers in response

**Check Response Headers**:
```
Access-Control-Allow-Origin: http://localhost:5173
Access-Control-Allow-Credentials: true
```

---

### Test 15: Error Handling ✅

**Objective**: Verify proper error messages

**Steps**:
1. Try to toggle service that doesn't exist
2. Try to access customer that doesn't exist
3. Stop backend and try to load services

**Expected Result**:
- ✅ Toast error notification shown
- ✅ User-friendly error messages
- ✅ No crashes
- ✅ Loading states handle failures

---

## Integration Tests

### Full Flow Test: Service Lifecycle

**Scenario**: Admin creates, activates, deactivates, and manages a service

1. **Create Service** (Not implemented yet - manual DB insert)
   ```sql
   INSERT INTO services (category_id, name, description, base_price, is_active)
   VALUES (1, 'Test Service', 'Test Description', 99.99, false);
   ```

2. **View in Admin Panel**
   - Should appear in services list as INACTIVE

3. **Toggle Active**
   - Click status badge
   - Should turn green (ACTIVE)

4. **Verify Customer Side**
   - Login as customer
   - Service should appear on homepage

5. **Toggle Inactive**
   - Back to admin panel
   - Click status badge again
   - Should turn gray (INACTIVE)

6. **Verify Customer Side**
   - Refresh customer page
   - Service should disappear

✅ **Full Lifecycle Works!**

---

## Performance Tests

### Load Test: Dashboard Statistics

**Test**: Measure time to load dashboard with statistics

**Expected Performance**:
- Dashboard loads: < 1 second
- Statistics calculation: < 500ms
- API responses: < 200ms each

**How to Test**:
```javascript
// In browser console
console.time('dashboard');
// Navigate to /admin
// After page loads:
console.timeEnd('dashboard');
```

---

## Security Tests

### Test: SQL Injection Prevention

**Test**: Try SQL injection in search fields

**Steps**:
1. In service search: `' OR '1'='1`
2. In customer search: `'; DROP TABLE users; --`

**Expected Result**:
- ✅ No SQL injection
- ✅ Queries parameterized
- ✅ No database changes

### Test: XSS Prevention

**Test**: Try XSS in service names

**Steps**:
1. Insert service with name: `<script>alert('XSS')</script>`
2. View in admin panel

**Expected Result**:
- ✅ Script not executed
- ✅ Text displayed safely
- ✅ HTML escaped

---

## Bug Report Template

If you find issues, report using this template:

```markdown
**Bug Title**: [Short description]

**Severity**: Critical / High / Medium / Low

**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Behavior**:
What should happen

**Actual Behavior**:
What actually happens

**Screenshots**:
Attach if available

**Browser/Environment**:
- Browser: Chrome 120
- OS: macOS
- Backend: Running
- Database: Connected

**Console Errors**:
Copy any error messages

**Database State**:
Run relevant SQL queries
```

---

## Success Criteria

Your admin panel implementation is successful if:

- ✅ All 15 tests pass
- ✅ Service toggle affects customer homepage
- ✅ Non-admin users blocked from admin routes
- ✅ Dashboard statistics accurate
- ✅ No console errors
- ✅ Responsive on mobile
- ✅ Logout works correctly
- ✅ JWT validation works
- ✅ Search/filter functional
- ✅ Loading states work

---

## Next Steps After Testing

Once all tests pass:

1. **Document any issues found**
2. **Take screenshots for documentation**
3. **Update ADMIN_QUICK_START.md with findings**
4. **Plan Phase 2 features** (Create/Edit modals)
5. **Consider deployment** (Docker, environment variables)

---

## Quick Test Commands

```bash
# Check if backend is running
curl http://localhost:8080/api/health

# Check if admin user exists
psql -U servio_user -d servio_db -c "SELECT email, role FROM users WHERE role='ADMIN';"

# Count services
psql -U servio_user -d servio_db -c "SELECT COUNT(*) as total, SUM(CASE WHEN is_active THEN 1 ELSE 0 END) as active FROM services;"

# View recent appointments
psql -U servio_user -d servio_db -c "SELECT id, status, service_type FROM appointments ORDER BY created_at DESC LIMIT 5;"
```

---

**Happy Testing!** 🎉

Remember: The core feature is **service toggle affecting customer homepage**. Test that thoroughly!

---

*Version: 1.0*
*Last Updated: January 2026*
