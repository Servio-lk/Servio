-- V18__unify_uuid_identities_and_features.sql
-- Servio: Unify User Identity to UUID, reconcile domain entities, and create core feature tables.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Unify users table to UUID primary key
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all foreign keys pointing to users(id)
    FOR r IN (
        SELECT conname, relname 
        FROM pg_constraint 
        JOIN pg_class ON pg_constraint.conrelid = pg_class.oid 
        WHERE confrelid = 'users'::regclass AND contype = 'f'
    ) LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(r.relname) || ' DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname) || ' CASCADE';
    END LOOP;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'id' AND data_type LIKE '%int%'
    ) THEN
        ALTER TABLE users ADD COLUMN id_uuid UUID DEFAULT gen_random_uuid();
        UPDATE users SET id_uuid = gen_random_uuid() WHERE id_uuid IS NULL;
        ALTER TABLE users DROP CONSTRAINT IF EXISTS users_pkey CASCADE;
        ALTER TABLE users DROP COLUMN id;
        ALTER TABLE users RENAME COLUMN id_uuid TO id;
        ALTER TABLE users ADD PRIMARY KEY (id);
    END IF;
END $$;

-- 2. Standardize vehicles table with user_id UUID
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vehicles' AND column_name = 'user_id' AND data_type LIKE '%int%'
    ) THEN
        ALTER TABLE vehicles DROP COLUMN user_id;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vehicles' AND column_name = 'user_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE vehicles ADD COLUMN user_id UUID;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vehicles' AND column_name = 'profile_id'
    ) THEN
        UPDATE vehicles SET user_id = profile_id WHERE user_id IS NULL AND profile_id IS NOT NULL;
        ALTER TABLE vehicles DROP COLUMN IF EXISTS profile_id CASCADE;
    END IF;
    
    ALTER TABLE vehicles DROP CONSTRAINT IF EXISTS vehicles_user_id_fkey;
    ALTER TABLE vehicles ADD CONSTRAINT vehicles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
END $$;

CREATE INDEX IF NOT EXISTS idx_vehicles_user_id ON vehicles(user_id);

-- 3. Standardize appointments table with user_id UUID
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'user_id' AND data_type LIKE '%int%'
    ) THEN
        ALTER TABLE appointments DROP COLUMN user_id;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'user_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE appointments ADD COLUMN user_id UUID;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'profile_id'
    ) THEN
        UPDATE appointments SET user_id = profile_id WHERE user_id IS NULL AND profile_id IS NOT NULL;
        ALTER TABLE appointments DROP COLUMN IF EXISTS profile_id CASCADE;
    END IF;
    
    ALTER TABLE appointments DROP CONSTRAINT IF EXISTS check_user_or_profile;
    ALTER TABLE appointments DROP CONSTRAINT IF EXISTS chk_appointments_user_or_profile;
    ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_user_id_fkey;
    ALTER TABLE appointments ADD CONSTRAINT appointments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
END $$;

CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);

-- 4. Standardize payments table with user_id UUID
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'user_id' AND data_type LIKE '%int%'
    ) THEN
        ALTER TABLE payments DROP COLUMN user_id;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'user_id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE payments ADD COLUMN user_id UUID;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'profile_id'
    ) THEN
        UPDATE payments SET user_id = profile_id WHERE user_id IS NULL AND profile_id IS NOT NULL;
        ALTER TABLE payments DROP COLUMN IF EXISTS profile_id CASCADE;
    END IF;
    
    ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_user_id_fkey;
    ALTER TABLE payments ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);

-- 5. Standardize repair_jobs, notifications, reviews with user_id UUID
DO $$
BEGIN
    -- repair_jobs
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repair_jobs' AND column_name = 'user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE repair_jobs DROP COLUMN user_id;
        ALTER TABLE repair_jobs ADD COLUMN user_id UUID;
        ALTER TABLE repair_jobs ADD CONSTRAINT repair_jobs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- notifications
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE notifications DROP COLUMN user_id;
        ALTER TABLE notifications ADD COLUMN user_id UUID;
        ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- reviews
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE reviews DROP COLUMN user_id;
        ALTER TABLE reviews ADD COLUMN user_id UUID;
        ALTER TABLE reviews ADD CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 6. Standardize repair detail tables with user UUIDs
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repair_activities' AND column_name = 'performed_by_user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE repair_activities DROP COLUMN performed_by_user_id;
        ALTER TABLE repair_activities ADD COLUMN performed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repair_progress_updates' AND column_name = 'updated_by_user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE repair_progress_updates DROP COLUMN updated_by_user_id;
        ALTER TABLE repair_progress_updates ADD COLUMN updated_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repair_images' AND column_name = 'uploaded_by_user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE repair_images DROP COLUMN uploaded_by_user_id;
        ALTER TABLE repair_images ADD COLUMN uploaded_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repair_estimates' AND column_name = 'created_by_user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE repair_estimates DROP COLUMN created_by_user_id;
        ALTER TABLE repair_estimates ADD COLUMN created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repair_estimates' AND column_name = 'approved_by_user_id' AND data_type LIKE '%int%') THEN
        ALTER TABLE repair_estimates DROP COLUMN approved_by_user_id;
        ALTER TABLE repair_estimates ADD COLUMN approved_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 7. Create Service Bays Table
CREATE TABLE IF NOT EXISTS service_bays (
    id BIGSERIAL PRIMARY KEY,
    bay_number VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    type VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE',
    capacity INTEGER DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT bay_type_check CHECK (type IN ('GENERAL', 'PAINT_BOOTH', 'WASH_STATION', 'ALIGNMENT_STATION', 'DIAGNOSTIC_STATION')),
    CONSTRAINT bay_status_check CHECK (status IN ('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'CLEANING'))
);

CREATE INDEX IF NOT EXISTS idx_service_bays_bay_number ON service_bays(bay_number);
CREATE INDEX IF NOT EXISTS idx_service_bays_status ON service_bays(status);
CREATE INDEX IF NOT EXISTS idx_service_bays_is_active ON service_bays(is_active);

-- 8. Create Walk-In Customers Table
CREATE TABLE IF NOT EXISTS walk_in_customers (
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
    registered_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_walk_in_customers_phone ON walk_in_customers(phone);
CREATE INDEX IF NOT EXISTS idx_walk_in_customers_is_registered ON walk_in_customers(is_registered);

-- 9. Create Job Cards Table
CREATE TABLE IF NOT EXISTS job_cards (
    id BIGSERIAL PRIMARY KEY,
    appointment_id BIGINT REFERENCES appointments(id) ON DELETE SET NULL,
    mechanic_id BIGINT REFERENCES mechanics(id) ON DELETE SET NULL,
    service_bay_id BIGINT REFERENCES service_bays(id) ON DELETE SET NULL,
    walk_in_customer_id BIGINT REFERENCES walk_in_customers(id) ON DELETE SET NULL,
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
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT job_status_check CHECK (status IN ('NEW', 'IN_PROGRESS', 'PAUSED', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT job_priority_check CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT'))
);

CREATE INDEX IF NOT EXISTS idx_job_cards_job_number ON job_cards(job_number);
CREATE INDEX IF NOT EXISTS idx_job_cards_status ON job_cards(status);
CREATE INDEX IF NOT EXISTS idx_job_cards_appointment_id ON job_cards(appointment_id);
CREATE INDEX IF NOT EXISTS idx_job_cards_mechanic_id ON job_cards(mechanic_id);
CREATE INDEX IF NOT EXISTS idx_job_cards_bay_id ON job_cards(service_bay_id);

-- 10. Create Job Tasks Table
CREATE TABLE IF NOT EXISTS job_tasks (
    id BIGSERIAL PRIMARY KEY,
    job_card_id BIGINT NOT NULL REFERENCES job_cards(id) ON DELETE CASCADE,
    assigned_mechanic_id BIGINT REFERENCES mechanics(id) ON DELETE SET NULL,
    task_number VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    sequence_order INTEGER,
    estimated_hours DOUBLE PRECISION,
    actual_hours DOUBLE PRECISION,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT task_status_check CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
);

CREATE INDEX IF NOT EXISTS idx_job_tasks_job_card_id ON job_tasks(job_card_id);
CREATE INDEX IF NOT EXISTS idx_job_tasks_status ON job_tasks(status);

-- 11. Create Job Card Notes Table
CREATE TABLE IF NOT EXISTS job_card_notes (
    id BIGSERIAL PRIMARY KEY,
    job_card_id BIGINT NOT NULL REFERENCES job_cards(id) ON DELETE CASCADE,
    created_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    note_text TEXT NOT NULL,
    note_type VARCHAR(50) DEFAULT 'GENERAL',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_card_notes_job_card_id ON job_card_notes(job_card_id);

-- 12. Create Job Card Photos Table
CREATE TABLE IF NOT EXISTS job_card_photos (
    id BIGSERIAL PRIMARY KEY,
    job_card_id BIGINT NOT NULL REFERENCES job_cards(id) ON DELETE CASCADE,
    photo_url VARCHAR(500) NOT NULL,
    description TEXT,
    photo_type VARCHAR(50) DEFAULT 'WORK_IN_PROGRESS',
    uploaded_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_card_photos_job_card_id ON job_card_photos(job_card_id);

-- 13. Create Inventory Items Table
CREATE TABLE IF NOT EXISTS inventory_items (
    id BIGSERIAL PRIMARY KEY,
    part_number VARCHAR(100) UNIQUE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    quantity INTEGER NOT NULL DEFAULT 0,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    min_quantity INTEGER DEFAULT 5,
    supplier VARCHAR(255),
    location VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_items_part_number ON inventory_items(part_number);
CREATE INDEX IF NOT EXISTS idx_inventory_items_category ON inventory_items(category);

-- 14. Create Stock Transactions Table
CREATE TABLE IF NOT EXISTS stock_transactions (
    id BIGSERIAL PRIMARY KEY,
    inventory_item_id BIGINT NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2),
    reference_type VARCHAR(50),
    reference_id VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_transactions_item_id ON stock_transactions(inventory_item_id);

-- 15. Create Bills & Bill Items Tables
CREATE TABLE IF NOT EXISTS bills (
    id BIGSERIAL PRIMARY KEY,
    appointment_id BIGINT REFERENCES appointments(id) ON DELETE SET NULL,
    job_card_id BIGINT REFERENCES job_cards(id) ON DELETE SET NULL,
    walk_in_customer_id BIGINT REFERENCES walk_in_customers(id) ON DELETE SET NULL,
    invoice_number VARCHAR(100) UNIQUE NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(50),
    notes TEXT,
    issued_at TIMESTAMP,
    paid_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bills_invoice_number ON bills(invoice_number);
CREATE INDEX IF NOT EXISTS idx_bills_appointment_id ON bills(appointment_id);

CREATE TABLE IF NOT EXISTS bill_items (
    id BIGSERIAL PRIMARY KEY,
    bill_id BIGINT NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    description VARCHAR(255) NOT NULL,
    item_type VARCHAR(50) NOT NULL DEFAULT 'SERVICE',
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    inventory_item_id BIGINT REFERENCES inventory_items(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON bill_items(bill_id);

-- 16. Create Offers & Service Providers Tables
CREATE TABLE IF NOT EXISTS offers (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    discount_percentage DECIMAL(5,2),
    discount_amount DECIMAL(10,2),
    promo_code VARCHAR(50) UNIQUE,
    valid_from TIMESTAMP,
    valid_until TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_providers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    rating DECIMAL(3,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 17. Create Agent Conversations Table for Persistent AI Assistant
CREATE TABLE IF NOT EXISTS agent_conversations (
    id VARCHAR(128) PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    history_json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agent_conversations_user_id ON agent_conversations(user_id);
