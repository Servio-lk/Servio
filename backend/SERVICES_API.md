# Complete API Reference - Priority 1 Services

Extended API documentation for Vehicles, Payments, Service Records, and Notifications.

---

## Vehicle Management API

### Create Vehicle
**Endpoint:** `POST /api/vehicles`

**Request:**
```json
{
  "userId": 1,
  "make": "Toyota",
  "model": "Camry",
  "year": 2020,
  "licensePlate": "ABC123",
  "vin": "1HGBH41JXMN109186"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Vehicle created successfully",
  "data": {
    "id": 1,
    "userId": 1,
    "userName": "John Doe",
    "make": "Toyota",
    "model": "Camry",
    "year": 2020,
    "licensePlate": "ABC123",
    "vin": "1HGBH41JXMN109186",
    "createdAt": "2026-01-20T10:30:00",
    "updatedAt": "2026-01-20T10:30:00"
  }
}
```

### Get All Vehicles
**Endpoint:** `GET /api/vehicles`

### Get User Vehicles
**Endpoint:** `GET /api/vehicles/user/{userId}`

### Get Vehicle by ID
**Endpoint:** `GET /api/vehicles/{id}`

### Get Vehicle Statistics
**Endpoint:** `GET /api/vehicles/{id}/stats`

**Response:**
```json
{
  "success": true,
  "message": "Vehicle statistics retrieved successfully",
  "data": {
    "vehicleId": 1,
    "vehicleInfo": "Toyota Camry 2020",
    "totalServices": 5,
    "totalCost": 450.00,
    "lastMileage": 35000
  }
}
```

### Update Vehicle
**Endpoint:** `PUT /api/vehicles/{id}`

**Request:**
```json
{
  "make": "Toyota",
  "model": "Camry",
  "year": 2021,
  "licensePlate": "ABC124"
}
```

### Delete Vehicle
**Endpoint:** `DELETE /api/vehicles/{id}`

---

## Payment Management API

### Create Payment
**Endpoint:** `POST /api/payments`

**Request:**
```json
{
  "userId": 1,
  "appointmentId": 5,
  "amount": 195.00,
  "paymentMethod": "CREDIT_CARD"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment initiated successfully",
  "data": {
    "id": 10,
    "userId": 1,
    "userName": "John Doe",
    "appointmentId": 5,
    "amount": 195.00,
    "paymentMethod": "CREDIT_CARD",
    "paymentStatus": "PENDING",
    "transactionId": "TXN12345678",
    "paymentDate": null,
    "createdAt": "2026-01-20T10:30:00",
    "updatedAt": "2026-01-20T10:30:00"
  }
}
```

### Process Payment
**Endpoint:** `POST /api/payments/{id}/process`

Processes a pending payment and marks it as COMPLETED.

### Refund Payment
**Endpoint:** `POST /api/payments/{id}/refund`

Refunds a completed payment.

### Get All Payments
**Endpoint:** `GET /api/payments`

### Get User Payments
**Endpoint:** `GET /api/payments/user/{userId}`

### Get Payments by Status
**Endpoint:** `GET /api/payments/status/{status}`

**Status values:** PENDING, COMPLETED, FAILED, REFUNDED

### Get Payment by ID
**Endpoint:** `GET /api/payments/{id}`

### Get Payment Statistics
**Endpoint:** `GET /api/payments/user/{userId}/stats`

**Response:**
```json
{
  "success": true,
  "message": "Payment statistics retrieved successfully",
  "data": {
    "userId": 1,
    "totalPayments": 10,
    "totalAmount": 1250.00,
    "pendingPayments": 2,
    "completedPayments": 8
  }
}
```

### Get Revenue by Period
**Endpoint:** `GET /api/payments/revenue?startDate=2026-01-01T00:00:00&endDate=2026-01-31T23:59:59`

**Response:**
```json
{
  "success": true,
  "message": "Revenue retrieved successfully",
  "data": 5230.00
}
```

---

## Service Record Management API

### Create Service Record
**Endpoint:** `POST /api/service-records`

**Request:**
```json
{
  "vehicleId": 1,
  "serviceType": "Oil Change",
  "description": "Regular oil change with synthetic oil",
  "serviceDate": "2026-01-15",
  "mileage": 35000,
  "cost": 75.00
}
```

**Response:**
```json
{
  "success": true,
  "message": "Service record created successfully",
  "data": {
    "id": 10,
    "vehicleId": 1,
    "vehicleMake": "Toyota",
    "vehicleModel": "Camry",
    "serviceType": "Oil Change",
    "description": "Regular oil change with synthetic oil",
    "serviceDate": "2026-01-15",
    "mileage": 35000,
    "cost": 75.00,
    "createdAt": "2026-01-20T10:30:00",
    "updatedAt": "2026-01-20T10:30:00"
  }
}
```

### Get All Service Records
**Endpoint:** `GET /api/service-records`

### Get Vehicle Service Records
**Endpoint:** `GET /api/service-records/vehicle/{vehicleId}`

### Get Recent Service Records
**Endpoint:** `GET /api/service-records/recent?limit=10`

### Get Service Record by ID
**Endpoint:** `GET /api/service-records/{id}`

### Get Vehicle Service History
**Endpoint:** `GET /api/service-records/vehicle/{vehicleId}/history`

**Response:**
```json
{
  "success": true,
  "message": "Vehicle service history retrieved successfully",
  "data": {
    "vehicleId": 1,
    "vehicleInfo": "Toyota Camry",
    "totalServices": 5,
    "totalCost": 450.00,
    "lastServiceDate": "2026-01-15",
    "lastMileage": 35000,
    "serviceRecords": [
      {
        "id": 10,
        "vehicleId": 1,
        "vehicleMake": "Toyota",
        "vehicleModel": "Camry",
        "serviceType": "Oil Change",
        "description": "Regular oil change",
        "serviceDate": "2026-01-15",
        "mileage": 35000,
        "cost": 75.00,
        "createdAt": "2026-01-20T10:30:00",
        "updatedAt": "2026-01-20T10:30:00"
      }
    ]
  }
}
```

### Get Maintenance Reminders
**Endpoint:** `GET /api/service-records/vehicle/{vehicleId}/reminders`

**Response:**
```json
{
  "success": true,
  "message": "Maintenance reminders retrieved successfully",
  "data": [
    {
      "serviceType": "Oil Change",
      "description": "Oil change due - last service was 6 months ago",
      "dueDate": "2026-07-15",
      "priority": "MEDIUM"
    },
    {
      "serviceType": "Annual Service",
      "description": "Annual service due",
      "dueDate": "2027-01-15",
      "priority": "HIGH"
    }
  ]
}
```

### Update Service Record
**Endpoint:** `PUT /api/service-records/{id}`

### Delete Service Record
**Endpoint:** `DELETE /api/service-records/{id}`

---

## Notification Management API

### Create Notification
**Endpoint:** `POST /api/notifications`

**Request:**
```json
{
  "userId": 1,
  "title": "Appointment Reminder",
  "message": "Your appointment is tomorrow at 10:00 AM",
  "type": "REMINDER"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Notification created successfully",
  "data": {
    "id": 10,
    "userId": 1,
    "userName": "John Doe",
    "title": "Appointment Reminder",
    "message": "Your appointment is tomorrow at 10:00 AM",
    "type": "REMINDER",
    "isRead": false,
    "createdAt": "2026-01-20T10:30:00"
  }
}
```

### Get User Notifications
**Endpoint:** `GET /api/notifications/user/{userId}`

Returns all notifications for a user, ordered by date (newest first).

### Get Unread Notifications
**Endpoint:** `GET /api/notifications/user/{userId}/unread`

Returns only unread notifications for a user.

### Get Unread Count
**Endpoint:** `GET /api/notifications/user/{userId}/unread/count`

**Response:**
```json
{
  "success": true,
  "message": "Unread count retrieved successfully",
  "data": 5
}
```

### Get Notification by ID
**Endpoint:** `GET /api/notifications/{id}`

### Mark as Read
**Endpoint:** `PATCH /api/notifications/{id}/read`

Marks a single notification as read.

### Mark All as Read
**Endpoint:** `PATCH /api/notifications/user/{userId}/read-all`

Marks all notifications for a user as read.

### Delete Notification
**Endpoint:** `DELETE /api/notifications/{id}`

### Delete Old Notifications
**Endpoint:** `DELETE /api/notifications/user/{userId}/old?daysOld=30`

Deletes notifications older than the specified number of days (default: 30).

---

## Notification Types

- `APPOINTMENT` - Appointment-related notifications
- `PAYMENT` - Payment confirmations and receipts
- `REMINDER` - Service reminders and alerts
- `PROMOTIONAL` - Marketing and promotional messages

---

## Payment Methods

- `CREDIT_CARD`
- `DEBIT_CARD`
- `CASH`
- `UPI`
- `WALLET`

---

## Complete API Summary

### Dashboard (3 endpoints)
- GET /api/dashboard/stats
- GET /api/dashboard/revenue-chart
- GET /api/dashboard/recent-activities

### Appointments (7 endpoints)
- POST /api/appointments
- GET /api/appointments
- GET /api/appointments/recent
- GET /api/appointments/status/{status}
- GET /api/appointments/{id}
- PATCH /api/appointments/{id}/status
- DELETE /api/appointments/{id}

### Vehicles (7 endpoints)
- POST /api/vehicles
- GET /api/vehicles
- GET /api/vehicles/user/{userId}
- GET /api/vehicles/{id}
- GET /api/vehicles/{id}/stats
- PUT /api/vehicles/{id}
- DELETE /api/vehicles/{id}

### Payments (9 endpoints)
- POST /api/payments
- POST /api/payments/{id}/process
- POST /api/payments/{id}/refund
- GET /api/payments
- GET /api/payments/user/{userId}
- GET /api/payments/status/{status}
- GET /api/payments/{id}
- GET /api/payments/user/{userId}/stats
- GET /api/payments/revenue

### Service Records (9 endpoints)
- POST /api/service-records
- GET /api/service-records
- GET /api/service-records/vehicle/{vehicleId}
- GET /api/service-records/recent
- GET /api/service-records/{id}
- GET /api/service-records/vehicle/{vehicleId}/history
- GET /api/service-records/vehicle/{vehicleId}/reminders
- PUT /api/service-records/{id}
- DELETE /api/service-records/{id}

### Notifications (9 endpoints)
- POST /api/notifications
- GET /api/notifications/user/{userId}
- GET /api/notifications/user/{userId}/unread
- GET /api/notifications/user/{userId}/unread/count
- GET /api/notifications/{id}
- PATCH /api/notifications/{id}/read
- PATCH /api/notifications/user/{userId}/read-all
- DELETE /api/notifications/{id}
- DELETE /api/notifications/user/{userId}/old

---

## Total: 44 REST API Endpoints

All endpoints return consistent JSON responses with:
- `success` (boolean)
- `message` (string)
- `data` (object/array/null)
