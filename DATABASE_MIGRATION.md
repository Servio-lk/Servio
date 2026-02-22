# Database Migration Guide - New Features

This document outlines the database changes required to support the new features: Mechanics, Service Bays, Walk-In Customers, Job Cards, and related functionality.

## Database Tables to Create

### 1. Mechanics Table

```sql
CREATE TABLE mechanics (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    specialization VARCHAR(255),
    experience_years INTEGER,
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT mechanic_status_check CHECK (status IN ('AVAILABLE', 'BUSY', 'ON_LEAVE'))
);

CREATE INDEX idx_mechanics_email ON mechanics(email);
CREATE INDEX idx_mechanics_status ON mechanics(status);
CREATE INDEX idx_mechanics_is_active ON mechanics(is_active);
```

### 2. Service Bays Table

```sql
CREATE TABLE service_bays (
    id BIGSERIAL PRIMARY KEY,
    bay_number VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    type VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE',
    capacity INTEGER DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT bay_type_check CHECK (type IN ('GENERAL', 'PAINT_BOOTH', 'WASH_STATION', 'ALIGNMENT_STATION', 'DIAGNOSTIC_STATION')),
    CONSTRAINT bay_status_check CHECK (status IN ('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'CLEANING'))
);

CREATE INDEX idx_service_bays_bay_number ON service_bays(bay_number);
CREATE INDEX idx_service_bays_status ON service_bays(status);
CREATE INDEX idx_service_bays_is_active ON service_bays(is_active);
```

### 3. Walk-In Customers Table

```sql
CREATE TABLE walk_in_customers (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    vehicle_make VARCHAR(100),
    vehicle_model VARCHAR(100),
    vehicle_year INTEGER,
    license_plate VARCHAR(50),
    notes TEXT,
    is_registered BOOLEAN NOT NULL DEFAULT FALSE,
    registered_user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);

CREATE INDEX idx_walk_in_customers_phone ON walk_in_customers(phone);
CREATE INDEX idx_walk_in_customers_is_registered ON walk_in_customers(is_registered);
```

### 4. Job Cards Table

```sql
CREATE TABLE job_cards (
    id BIGSERIAL PRIMARY KEY,
    appointment_id BIGINT REFERENCES appointments(id),
    mechanic_id BIGINT REFERENCES mechanics(id),
    service_bay_id BIGINT REFERENCES service_bays(id),
    walk_in_customer_id BIGINT REFERENCES walk_in_customers(id),
    job_number VARCHAR(100) UNIQUE NOT NULL,
    service_type VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'NEW',
    priority VARCHAR(50) NOT NULL DEFAULT 'NORMAL',
    estimated_hours DECIMAL(10,2),
    actual_hours DECIMAL(10,2),
    estimated_cost DECIMAL(19,2),
    actual_cost DECIMAL(19,2),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT job_status_check CHECK (status IN ('NEW', 'IN_PROGRESS', 'PAUSED', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT job_priority_check CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT'))
);

CREATE INDEX idx_job_cards_job_number ON job_cards(job_number);
CREATE INDEX idx_job_cards_appointment_id ON job_cards(appointment_id);
CREATE INDEX idx_job_cards_mechanic_id ON job_cards(mechanic_id);
CREATE INDEX idx_job_cards_service_bay_id ON job_cards(service_bay_id);
CREATE INDEX idx_job_cards_status ON job_cards(status);
```

### 5. Job Tasks Table

```sql
CREATE TABLE job_tasks (
    id BIGSERIAL PRIMARY KEY,
    job_card_id BIGINT NOT NULL REFERENCES job_cards(id),
    assigned_mechanic_id BIGINT REFERENCES mechanics(id),
    task_number VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    sequence_order INTEGER,
    estimated_hours DECIMAL(10,2),
    actual_hours DECIMAL(10,2),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT task_status_check CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
);

CREATE INDEX idx_job_tasks_job_card_id ON job_tasks(job_card_id);
CREATE INDEX idx_job_tasks_assigned_mechanic_id ON job_tasks(assigned_mechanic_id);
CREATE INDEX idx_job_tasks_status ON job_tasks(status);
```

### 6. Job Card Notes Table

```sql
CREATE TABLE job_card_notes (
    id BIGSERIAL PRIMARY KEY,
    job_card_id BIGINT NOT NULL REFERENCES job_cards(id),
    created_by_id BIGINT REFERENCES users(id),
    note_text TEXT NOT NULL,
    note_type VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT note_type_check CHECK (note_type IN ('GENERAL', 'DIAGNOSIS', 'ISSUE_FOUND', 'CUSTOMER_NOTE', 'WARNING'))
);

CREATE INDEX idx_job_card_notes_job_card_id ON job_card_notes(job_card_id);
CREATE INDEX idx_job_card_notes_created_at ON job_card_notes(created_at);
```

### 7. Job Card Photos Table

```sql
CREATE TABLE job_card_photos (
    id BIGSERIAL PRIMARY KEY,
    job_card_id BIGINT NOT NULL REFERENCES job_cards(id),
    photo_url VARCHAR(500) NOT NULL,
    description TEXT,
    photo_type VARCHAR(50) NOT NULL DEFAULT 'WORK_IN_PROGRESS',
    uploaded_by_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT photo_type_check CHECK (photo_type IN ('BEFORE', 'DURING', 'WORK_IN_PROGRESS', 'AFTER', 'ISSUE', 'DIAGNOSTIC'))
);

CREATE INDEX idx_job_card_photos_job_card_id ON job_card_photos(job_card_id);
```

## Migration Steps

1. **Backup Database**

   ```sql
   -- Create backup before running migrations
   pg_dump servio_db > servio_backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Run Migration Scripts**
   Execute the SQL statements above in order, in your database management tool.

3. **Verify Tables**

   ```sql
   \dt -- List all tables
   \d job_cards -- View job_cards table structure
   ```

4. **Create Sample Data (Optional)**
   See section below for sample data scripts.

## Sample Data Setup

### Add Sample Mechanics

```sql
INSERT INTO mechanics (full_name, email, phone, specialization, experience_years, status, is_active, created_at)
VALUES
  ('John Smith', 'john.smith@example.com', '+94701234567', 'Engine Repair', 5, 'AVAILABLE', true, NOW()),
  ('Maria Garcia', 'maria.garcia@example.com', '+94702234567', 'Electrical', 3, 'AVAILABLE', true, NOW()),
  ('Ahmed Hassan', 'ahmed.hassan@example.com', '+94703234567', 'Bodywork', 4, 'AVAILABLE', true, NOW());
```

### Add Sample Service Bays

```sql
INSERT INTO service_bays (bay_number, description, type, status, capacity, is_active, created_at)
VALUES
  ('Bay 1', 'General Service Station 1', 'GENERAL', 'AVAILABLE', 1, true, NOW()),
  ('Bay 2', 'General Service Station 2', 'GENERAL', 'AVAILABLE', 1, true, NOW()),
  ('Bay 3', 'Paint Booth', 'PAINT_BOOTH', 'AVAILABLE', 1, true, NOW()),
  ('Bay 4', 'Wash Station', 'WASH_STATION', 'AVAILABLE', 1, true, NOW());
```

## Verification Checklist

- [ ] All tables created successfully
- [ ] Indexes created for performance
- [ ] Foreign key constraints working
- [ ] Sample data inserted correctly
- [ ] Queries running without errors
- [ ] Backend application starts without errors
- [ ] Admin UI pages loading correctly
- [ ] Can create new mechanics
- [ ] Can create new service bays
- [ ] Can add walk-in customers
- [ ] Can create job cards
- [ ] Can view and manage all new entities

## Performance Considerations

1. **Indexes**: All frequently queried columns are indexed
2. **Foreign Keys**: Relationships are properly defined
3. **Constraints**: Data integrity is ensured with CHECK constraints
4. **Timestamps**: Audit trail with created_at and updated_at fields

## Rollback Plan

If you need to rollback:

```sql
DROP TABLE IF EXISTS job_card_photos;
DROP TABLE IF EXISTS job_card_notes;
DROP TABLE IF EXISTS job_tasks;
DROP TABLE IF EXISTS job_cards;
DROP TABLE IF EXISTS walk_in_customers;
DROP TABLE IF EXISTS service_bays;
DROP TABLE IF EXISTS mechanics;
```

## Support

For issues with migrations, contact the development team or check the backend logs for detailed error messages.
