# Database Setup Scripts

This directory contains SQL scripts to initialize and manage the Servio database.

## Files

- **init.sql**: Main initialization script that creates all tables and sample data
- **dashboard-migration.sql**: Migration script for dashboard-related tables (if needed separately)

## Database Schema

### Core Tables

1. **users**: User accounts and authentication
2. **vehicles**: User vehicles information
3. **service_records**: Historical service records for vehicles

### Dashboard Tables

4. **appointments**: Service bookings and appointments
5. **payments**: Payment transactions and history
6. **reviews**: Customer reviews and ratings
7. **notifications**: User notifications

## Quick Setup

### Using Docker Compose (Recommended)

The database is automatically initialized when you run:

```bash
docker-compose up -d
```

### Manual Setup

If you need to run the scripts manually:

```bash
# Connect to PostgreSQL
psql -h localhost -U servio_user -d servio_db

# Run the initialization script
\i init.sql
```

## Sample Data

The `init.sql` script includes sample data for testing:

- 3 sample users
- 3 vehicles
- 5 appointments (with different statuses)
- 3 payments
- 3 reviews
- Various service records

## Database Credentials (Development)

- **Host**: localhost
- **Port**: 5432
- **Database**: servio_db
- **Username**: servio_user
- **Password**: servio_pass

⚠️ **Important**: Change these credentials in production!

## Resetting the Database

To reset the database with fresh data:

```bash
# Stop the containers
docker-compose down -v

# Restart (this will recreate the database)
docker-compose up -d
```

## Schema Diagram

```
users
  ├── vehicles
  │     └── service_records
  ├── appointments
  │     ├── payments
  │     └── reviews
  └── notifications
```

## Indexes

The following indexes are created for performance:

- `idx_users_email`: Fast email lookups for authentication
- `idx_vehicles_user_id`: Quick vehicle queries by user
- `idx_service_records_vehicle_id`: Fast service record lookups
- `idx_appointments_user_id`: User appointment queries
- `idx_appointments_status`: Filter appointments by status
- `idx_appointments_date`: Date-based appointment queries
- `idx_payments_status`: Payment status filtering
- `idx_reviews_user_id`: User review queries

## Maintenance

### Backup Database

```bash
docker exec servio-db pg_dump -U servio_user servio_db > backup.sql
```

### Restore Database

```bash
docker exec -i servio-db psql -U servio_user servio_db < backup.sql
```

## API Endpoints Using This Data

### Dashboard Endpoints

- `GET /api/dashboard/stats` - Overall statistics
- `GET /api/dashboard/revenue-chart?months=6` - Revenue chart data
- `GET /api/dashboard/recent-activities?limit=10` - Recent activities

### Appointment Endpoints

- `GET /api/appointments` - All appointments
- `GET /api/appointments/recent` - Recent appointments
- `GET /api/appointments/status/{status}` - Filter by status
- `POST /api/appointments` - Create new appointment
- `PATCH /api/appointments/{id}/status` - Update status
- `DELETE /api/appointments/{id}` - Delete appointment

## Appointment Status Values

- `PENDING`: Appointment requested but not confirmed
- `CONFIRMED`: Appointment confirmed by service provider
- `IN_PROGRESS`: Service currently being performed
- `COMPLETED`: Service finished
- `CANCELLED`: Appointment cancelled

## Payment Status Values

- `PENDING`: Payment initiated but not completed
- `COMPLETED`: Payment successfully processed
- `FAILED`: Payment failed
- `REFUNDED`: Payment refunded to customer

## Payment Methods

- `CREDIT_CARD`
- `DEBIT_CARD`
- `CASH`
- `UPI`
- `WALLET`
