# New Features Implementation Guide

## Overview

This guide explains all the new features added to the Servio application:

- Customer & Vehicle Management enhancements
- Appointment Management with mechanics & service bays
- Job Card & Service Workflow system

## Feature 1: Mechanic Management

### What it does

Manage mechanics/technicians working at the service center.

### Backend API Endpoints

**Create Mechanic**

```
POST /api/admin/mechanics
Content-Type: application/json
Authorization: Bearer {token}

{
  "fullName": "John Smith",
  "email": "john@example.com",
  "phone": "+94701234567",
  "specialization": "Engine Repair",
  "experienceYears": 5
}
```

**List Mechanics**

```
GET /api/admin/mechanics
Authorization: Bearer {token}
```

**Get Available Mechanics**

```
GET /api/admin/mechanics/available
Authorization: Bearer {token}
```

**Update Mechanic Status**

```
PATCH /api/admin/mechanics/{id}/status/{status}
Status values: AVAILABLE, BUSY, ON_LEAVE
Authorization: Bearer {token}
```

### Admin Frontend

- Navigate to: **Admin → Mechanics**
- Features:
  - View all mechanics in grid layout
  - Add new mechanic with form
  - Search mechanics by name or specialization
  - View experience years and status
  - Delete mechanics
  - Edit mechanic details (coming soon)

## Feature 2: Service Bay Management

### What it does

Manage physical service bays/stations in your service center.

### Backend API Endpoints

**Create Service Bay**

```
POST /api/admin/service-bays
Content-Type: application/json
Authorization: Bearer {token}

{
  "bayNumber": "Bay 1",
  "description": "General Service Station",
  "type": "GENERAL",
  "capacity": 1
}
```

**List Service Bays**

```
GET /api/admin/service-bays
Authorization: Bearer {token}
```

**Get Available Bays**

```
GET /api/admin/service-bays/available
Authorization: Bearer {token}
```

**Update Bay Status**

```
PATCH /api/admin/service-bays/{id}/status/{status}
Status values: AVAILABLE, IN_USE, MAINTENANCE, CLEANING
Authorization: Bearer {token}
```

### Admin Frontend

- Navigate to: **Admin → Service Bays**
- Features:
  - View all bays in table format
  - Add new service bay
  - Update bay status (dropdown)
  - View bay type and capacity
  - Search by bay number or description
  - Delete bays

### Service Bay Types

- **GENERAL**: General service station
- **PAINT_BOOTH**: For painting and coating
- **WASH_STATION**: For vehicle washing
- **ALIGNMENT_STATION**: For wheel alignment
- **DIAGNOSTIC_STATION**: For diagnostic testing

## Feature 3: Walk-In Customer Management

### What it does

Add and manage customers who walk in without being registered users.

### Backend API Endpoints

**Create Walk-In Customer**

```
POST /api/admin/walk-in-customers
Content-Type: application/json
Authorization: Bearer {token}

{
  "fullName": "Customer Name",
  "phone": "+94701234567",
  "email": "customer@example.com",
  "vehicleMake": "Toyota",
  "vehicleModel": "Camry",
  "vehicleYear": 2022,
  "licensePlate": "ABC123",
  "notes": "Customer notes"
}
```

**List All Walk-In Customers**

```
GET /api/admin/walk-in-customers
Authorization: Bearer {token}
```

**List Unregistered Customers**

```
GET /api/admin/walk-in-customers/unregistered
Authorization: Bearer {token}
```

**Mark as Registered**

```
PATCH /api/admin/walk-in-customers/{id}/register/{userId}
Authorization: Bearer {token}
```

### Admin Frontend

- Navigate to: **Admin → Walk-In Customers**
- Features:
  - Add new walk-in customer
  - View all walk-in customers
  - Search by name or phone
  - View vehicle details
  - Edit customer information
  - Delete customers

## Feature 4: Job Cards System

### What it does

Create detailed job cards for service appointments with task breakdown and progress tracking.

### Backend API Endpoints

**Create Job Card**

```
POST /api/admin/job-cards
Content-Type: application/json
Authorization: Bearer {token}

{
  "appointmentId": 5,
  "mechanicId": 1,
  "serviceBayId": 3,
  "serviceType": "Engine Service",
  "description": "Full engine service and oil change",
  "priority": "NORMAL",
  "estimatedHours": 2.5,
  "estimatedCost": 5000
}
```

**Get Job Card by ID**

```
GET /api/admin/job-cards/{id}
Authorization: Bearer {token}
```

**List Job Cards by Status**

```
GET /api/admin/job-cards/status/{status}
Status values: NEW, IN_PROGRESS, PAUSED, COMPLETED, CANCELLED
Authorization: Bearer {token}
```

**Update Job Card Status**

```
PATCH /api/admin/job-cards/{id}/status/{status}
Authorization: Bearer {token}
```

**Assign Mechanic to Job Card**

```
PUT /api/admin/job-cards/{id}
Content-Type: application/json
Authorization: Bearer {token}

{
  "mechanicId": 2,
  "serviceBayId": 1
}
```

### Admin Frontend

- Navigate to: **Admin → Job Cards**
- Features:
  - View all job cards in table
  - Search by job number, service type, or mechanic
  - Filter by status
  - Update job card status (dropdown)
  - View job card details in modal
  - Priority indicators (LOW, NORMAL, HIGH, URGENT)
  - View assigned mechanic and service bay
  - See estimated and actual hours/costs

### Job Card Statuses

- **NEW**: Newly created, not started
- **IN_PROGRESS**: Currently being worked on
- **PAUSED**: Work paused, can be resumed
- **COMPLETED**: Work finished
- **CANCELLED**: Job cancelled

## Feature 5: Job Tasks Management

### What it does

Break down job cards into individual tasks and assign to technicians.

### Backend API Endpoints

**Create Job Task**

```
POST /api/admin/job-tasks
Content-Type: application/json
Authorization: Bearer {token}

{
  "jobCardId": 1,
  "description": "Change engine oil",
  "instructions": "Use 5L of synthetic oil",
  "mechanicId": 1,
  "estimatedHours": 0.5,
  "sequenceOrder": 1
}
```

**List Tasks for Job Card**

```
GET /api/admin/job-tasks/job-card/{jobCardId}
Authorization: Bearer {token}
```

**Update Task Status**

```
PATCH /api/admin/job-tasks/{id}/status/{status}
Status values: PENDING, IN_PROGRESS, COMPLETED, CANCELLED
Authorization: Bearer {token}
```

### Task Statuses

- **PENDING**: Not yet started
- **IN_PROGRESS**: Currently being worked on
- **COMPLETED**: Task finished
- **CANCELLED**: Task cancelled

## Feature 6: Job Card Notes

### What it does

Add detailed notes to job cards documenting work done, issues found, etc.

### Backend API Endpoints

**Add Note**

```
POST /api/admin/job-card-notes
Content-Type: application/json
Authorization: Bearer {token}

{
  "jobCardId": 1,
  "noteText": "Engine oil low, replaced with synthetic",
  "noteType": "DIAGNOSIS"
}
```

**Get Notes for Job Card**

```
GET /api/admin/job-card-notes/job-card/{jobCardId}
Authorization: Bearer {token}
```

### Note Types

- **GENERAL**: General note
- **DIAGNOSIS**: Diagnostic findings
- **ISSUE_FOUND**: Issues discovered
- **CUSTOMER_NOTE**: Notes for customer
- **WARNING**: Important warnings

## Feature 7: Job Card Photos

### What it does

Attach photos to job cards showing work progress, issues, etc.

### Backend API Endpoints

**Add Photo**

```
POST /api/admin/job-card-photos
Content-Type: application/json
Authorization: Bearer {token}

{
  "jobCardId": 1,
  "photoUrl": "/path/to/photo.jpg",
  "description": "Engine after cleaning",
  "photoType": "AFTER"
}
```

**Get Photos for Job Card**

```
GET /api/admin/job-card-photos/job-card/{jobCardId}
Authorization: Bearer {token}
```

### Photo Types

- **BEFORE**: Before work started
- **DURING**: During work
- **WORK_IN_PROGRESS**: Current work state
- **AFTER**: After work completed
- **ISSUE**: Photos of issues found
- **DIAGNOSTIC**: Diagnostic test photos

## Workflow Example

### Typical Service Flow

1. **Walk-In Customer Arrives**
   - Admin adds customer to system via "Walk-In Customers" page
   - Collects: Name, Phone, Vehicle Details

2. **Create Appointment**
   - Navigate to "Appointments" page
   - Create appointment for walk-in customer
   - Select service type and date

3. **Create Job Card**
   - Once appointment is created
   - Go to "Job Cards" page
   - Create job card for the appointment
   - Assign mechanic from available mechanics
   - Assign service bay

4. **Add Job Tasks**
   - Break down the service into specific tasks
   - Create tasks like "Change Oil", "Filter Replacement", etc.
   - Assign each task to a mechanic

5. **Work Progress**
   - Mechanic starts work, status changes to "IN_PROGRESS"
   - Add notes as work progresses
   - Take photos at each stage
   - Update task statuses as completed

6. **Complete Service**
   - All tasks completed
   - Update job card status to "COMPLETED"
   - Record actual hours and cost
   - Add final notes

7. **Follow-up**
   - Customer can view completed appointment
   - Photos and notes available for reference

## Dashboard View

All new entities integrate with the existing dashboard:

- Job cards in progress show in activity
- Mechanic availability affects scheduling
- Service bay status shows current capacity
- Walk-in customers appear in customer list

## Database Setup

Before using these features:

1. Run the database migration script (see DATABASE_MIGRATION.md)
2. Verify all tables created successfully
3. Create initial mechanics and service bays
4. Test API endpoints with Postman or similar tool

## Testing the Features

### Test Mechanic Creation

```bash
curl -X POST http://localhost:3001/api/admin/mechanics \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "fullName": "Test Mechanic",
    "email": "test@example.com",
    "phone": "+94701234567",
    "specialization": "Engine"
  }'
```

### Test Service Bay Creation

```bash
curl -X POST http://localhost:3001/api/admin/service-bays \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "bayNumber": "Bay 1",
    "description": "Test Bay",
    "type": "GENERAL",
    "capacity": 1
  }'
```

## Troubleshooting

### Tables Not Found Error

- Verify database migration script ran successfully
- Check database connection in application.properties
- Confirm tables exist: `\dt` in psql

### Unauthorized Error

- Ensure user has ADMIN role
- Check JWT token is valid
- Token should be Bearer token in header

### Mechanic/Bay Not Found

- Verify ID exists in database
- Check ID format (should be numeric)
- Confirmed data was created successfully

## Next Steps

1. ✅ Implement backend entities
2. ✅ Create admin frontend pages
3. ✅ Set up database tables
4. ⏳ **Optional**: Staff roles with limited permissions
5. ⏳ **Optional**: Real-time notifications
6. ⏳ **Optional**: Photo upload to cloud storage
7. ⏳ **Optional**: Service scheduling/availability management

## Support

For questions or issues:

1. Check API documentation: `backend/SERVICES_API.md`
2. Review database schema: `DATABASE_MIGRATION.md`
3. Test with provided curl examples
4. Check backend logs for detailed error messages
