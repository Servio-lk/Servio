# Dashboard Backend API Documentation

Complete API reference for the Servio dashboard backend.

## Base URL

```
http://localhost:8080/api
```

## Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

---

## Dashboard Endpoints

### Get Dashboard Statistics

Get overall dashboard statistics including users, appointments, revenue, and ratings.

**Endpoint:** `GET /api/dashboard/stats`

**Response:**
```json
{
  "success": true,
  "message": "Dashboard stats retrieved successfully",
  "data": {
    "totalUsers": 150,
    "totalAppointments": 523,
    "pendingAppointments": 23,
    "completedAppointments": 450,
    "totalRevenue": 45670.50,
    "monthlyRevenue": 5230.00,
    "averageRating": 4.7,
    "totalReviews": 234,
    "activeVehicles": 187
  }
}
```

---

### Get Revenue Chart Data

Get revenue data for chart visualization.

**Endpoint:** `GET /api/dashboard/revenue-chart?months=6`

**Query Parameters:**
- `months` (optional, default: 6) - Number of months to include

**Response:**
```json
{
  "success": true,
  "message": "Revenue chart data retrieved successfully",
  "data": {
    "labels": ["Aug 2025", "Sep 2025", "Oct 2025", "Nov 2025", "Dec 2025", "Jan 2026"],
    "data": [3200.00, 4100.00, 3800.00, 5200.00, 4900.00, 5230.00]
  }
}
```

---

### Get Recent Activities

Get recent system activities (appointments, payments, etc.).

**Endpoint:** `GET /api/dashboard/recent-activities?limit=10`

**Query Parameters:**
- `limit` (optional, default: 10) - Number of activities to return

**Response:**
```json
{
  "success": true,
  "message": "Recent activities retrieved successfully",
  "data": [
    {
      "activityType": "APPOINTMENT",
      "description": "New appointment for Oil Change",
      "userName": "John Doe",
      "timestamp": "2026-01-20T10:30:00"
    },
    {
      "activityType": "PAYMENT",
      "description": "Payment of $195.00 received",
      "userName": "Jane Smith",
      "timestamp": "2026-01-20T09:15:00"
    }
  ]
}
```

---

## Appointment Endpoints

### Create Appointment

Create a new service appointment.

**Endpoint:** `POST /api/appointments`

**Request Body:**
```json
{
  "userId": 1,
  "vehicleId": 1,
  "serviceType": "Oil Change",
  "appointmentDate": "2026-01-25T14:00:00",
  "location": "Service Center A",
  "notes": "Please use synthetic oil",
  "estimatedCost": 75.00
}
```

**Response:**
```json
{
  "success": true,
  "message": "Appointment created successfully",
  "data": {
    "id": 10,
    "userId": 1,
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "vehicleId": 1,
    "vehicleMake": "Toyota",
    "vehicleModel": "Camry",
    "serviceType": "Oil Change",
    "appointmentDate": "2026-01-25T14:00:00",
    "status": "PENDING",
    "location": "Service Center A",
    "notes": "Please use synthetic oil",
    "estimatedCost": 75.00,
    "actualCost": null,
    "createdAt": "2026-01-20T10:30:00",
    "updatedAt": "2026-01-20T10:30:00"
  }
}
```

---

### Get All Appointments

Get all appointments in the system.

**Endpoint:** `GET /api/appointments`

**Response:**
```json
{
  "success": true,
  "message": "Appointments retrieved successfully",
  "data": [
    {
      "id": 1,
      "userId": 1,
      "userName": "John Doe",
      "userEmail": "john@example.com",
      "vehicleId": 1,
      "vehicleMake": "Toyota",
      "vehicleModel": "Camry",
      "serviceType": "Oil Change",
      "appointmentDate": "2026-01-22T10:00:00",
      "status": "CONFIRMED",
      "location": "Service Center A",
      "estimatedCost": 50.00,
      "actualCost": null,
      "createdAt": "2026-01-18T14:30:00",
      "updatedAt": "2026-01-19T09:15:00"
    }
  ]
}
```

---

### Get Recent Appointments

Get the 10 most recent appointments.

**Endpoint:** `GET /api/appointments/recent`

---

### Get Appointments by Status

Filter appointments by status.

**Endpoint:** `GET /api/appointments/status/{status}`

**Path Parameters:**
- `status` - One of: PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED

**Example:** `GET /api/appointments/status/PENDING`

---

### Get Appointment by ID

Get a specific appointment by ID.

**Endpoint:** `GET /api/appointments/{id}`

**Path Parameters:**
- `id` - Appointment ID

**Example:** `GET /api/appointments/1`

---

### Update Appointment Status

Update the status of an appointment.

**Endpoint:** `PATCH /api/appointments/{id}/status?status=CONFIRMED`

**Path Parameters:**
- `id` - Appointment ID

**Query Parameters:**
- `status` - New status (PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED)

**Example:** `PATCH /api/appointments/1/status?status=CONFIRMED`

**Response:**
```json
{
  "success": true,
  "message": "Appointment status updated successfully",
  "data": {
    "id": 1,
    "status": "CONFIRMED",
    ...
  }
}
```

---

### Delete Appointment

Delete an appointment.

**Endpoint:** `DELETE /api/appointments/{id}`

**Path Parameters:**
- `id` - Appointment ID

**Response:**
```json
{
  "success": true,
  "message": "Appointment deleted successfully"
}
```

---

## Status Values

### Appointment Status
- `PENDING` - Appointment requested but not confirmed
- `CONFIRMED` - Appointment confirmed by service provider
- `IN_PROGRESS` - Service currently being performed
- `COMPLETED` - Service finished
- `CANCELLED` - Appointment cancelled

### Payment Status
- `PENDING` - Payment initiated but not completed
- `COMPLETED` - Payment successfully processed
- `FAILED` - Payment failed
- `REFUNDED` - Payment refunded to customer

### Payment Methods
- `CREDIT_CARD`
- `DEBIT_CARD`
- `CASH`
- `UPI`
- `WALLET`

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "message": "Error description",
  "data": null
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

---

## Testing the API

### Using cURL

```bash
# Get dashboard stats
curl http://localhost:8080/api/dashboard/stats

# Create appointment
curl -X POST http://localhost:8080/api/appointments \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "vehicleId": 1,
    "serviceType": "Oil Change",
    "appointmentDate": "2026-01-25T14:00:00",
    "location": "Service Center A",
    "estimatedCost": 75.00
  }'

# Get appointments by status
curl http://localhost:8080/api/appointments/status/PENDING

# Update appointment status
curl -X PATCH "http://localhost:8080/api/appointments/1/status?status=CONFIRMED"
```

### Using Postman

Import the following collection base URL: `http://localhost:8080/api`

Then create requests for each endpoint listed above.

---

## Database Tables Used

- `users` - User accounts
- `vehicles` - User vehicles
- `appointments` - Service appointments
- `payments` - Payment transactions
- `reviews` - Customer reviews
- `notifications` - User notifications
- `service_records` - Historical service records

---

## Next Steps

1. **Run Database Migration:**
   ```bash
   docker-compose up -d
   ```

2. **Build and Run Backend:**
   ```bash
   cd backend
   ./mvnw spring-boot:run
   ```

3. **Test Endpoints:**
   Use the examples above or create a frontend dashboard to consume these APIs.

4. **Add Authentication:**
   Most endpoints should be protected with JWT authentication in production.
