-- Repair Progress Tracking System Tables

-- Create repair_jobs table (main table for repair tracking)
CREATE TABLE IF NOT EXISTS repair_jobs (
    id SERIAL PRIMARY KEY,
    appointment_id INTEGER NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'INITIAL_INSPECTION', -- INITIAL_INSPECTION, QUOTE_PROVIDED, QUOTE_APPROVED, IN_PROGRESS, AWAITING_PARTS, COMPLETED, CANCELLED
    priority VARCHAR(50) NOT NULL DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
    estimated_duration_hours INTEGER,
    actual_duration_hours INTEGER,
    estimated_cost DECIMAL(10, 2),
    actual_cost DECIMAL(10, 2),
    parts_cost DECIMAL(10, 2),
    labor_cost DECIMAL(10, 2),
    assigned_technician_id INTEGER,
    start_date TIMESTAMP,
    completion_date TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_jobs
CREATE INDEX IF NOT EXISTS idx_repair_jobs_appointment_id ON repair_jobs(appointment_id);
CREATE INDEX IF NOT EXISTS idx_repair_jobs_vehicle_id ON repair_jobs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_repair_jobs_user_id ON repair_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_repair_jobs_status ON repair_jobs(status);
CREATE INDEX IF NOT EXISTS idx_repair_jobs_assigned_technician ON repair_jobs(assigned_technician_id);

-- Create repair_progress_updates table (detailed progress tracking)
CREATE TABLE IF NOT EXISTS repair_progress_updates (
    id SERIAL PRIMARY KEY,
    repair_job_id INTEGER NOT NULL REFERENCES repair_jobs(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL, -- INSPECTION_STARTED, INSPECTION_COMPLETE, PARTS_ORDERED, PARTS_RECEIVED, REPAIR_STARTED, REPAIR_IN_PROGRESS, REPAIR_PAUSED, REPAIR_COMPLETE, TESTING, TESTING_COMPLETE, QUALITY_CHECK, READY_FOR_PICKUP
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    description TEXT,
    technician_notes TEXT,
    estimated_completion_time TIMESTAMP,
    actual_completion_time TIMESTAMP,
    updated_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_progress_updates
CREATE INDEX IF NOT EXISTS idx_progress_updates_repair_job ON repair_progress_updates(repair_job_id);
CREATE INDEX IF NOT EXISTS idx_progress_updates_status ON repair_progress_updates(status);
CREATE INDEX IF NOT EXISTS idx_progress_updates_created_at ON repair_progress_updates(created_at);

-- Create repair_progress table (current progress snapshot)
CREATE TABLE IF NOT EXISTS repair_progress (
    id SERIAL PRIMARY KEY,
    repair_job_id INTEGER NOT NULL UNIQUE REFERENCES repair_jobs(id) ON DELETE CASCADE,
    current_status VARCHAR(50) NOT NULL, -- Mirrors latest status
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    estimated_completion_time TIMESTAMP,
    actual_completion_time TIMESTAMP,
    last_updated_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_progress
CREATE INDEX IF NOT EXISTS idx_repair_progress_repair_job ON repair_progress(repair_job_id);
CREATE INDEX IF NOT EXISTS idx_repair_progress_status ON repair_progress(current_status);

-- Create repair_activities table (activity log)
CREATE TABLE IF NOT EXISTS repair_activities (
    id SERIAL PRIMARY KEY,
    repair_job_id INTEGER NOT NULL REFERENCES repair_jobs(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- STATUS_CHANGE, NOTE, PARTS_UPDATE, ESTIMATE, ASSIGNMENT, SYSTEM
    description TEXT NOT NULL,
    performed_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_activities
CREATE INDEX IF NOT EXISTS idx_repair_activities_repair_job ON repair_activities(repair_job_id);
CREATE INDEX IF NOT EXISTS idx_repair_activities_type ON repair_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_repair_activities_created_at ON repair_activities(created_at);

-- Create repair_parts table (parts used in repairs)
CREATE TABLE IF NOT EXISTS repair_parts (
    id SERIAL PRIMARY KEY,
    repair_job_id INTEGER NOT NULL REFERENCES repair_jobs(id) ON DELETE CASCADE,
    part_name VARCHAR(255) NOT NULL,
    part_number VARCHAR(100),
    supplier VARCHAR(255),
    unit_cost DECIMAL(10, 2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    total_cost DECIMAL(10, 2) NOT NULL,
    order_date TIMESTAMP,
    delivery_date TIMESTAMP,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, ORDERED, RECEIVED, INSTALLED, RETURNED
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_parts
CREATE INDEX IF NOT EXISTS idx_repair_parts_repair_job ON repair_parts(repair_job_id);
CREATE INDEX IF NOT EXISTS idx_repair_parts_status ON repair_parts(status);

-- Create repair_images table (store photos of repairs/damage)
CREATE TABLE IF NOT EXISTS repair_images (
    id SERIAL PRIMARY KEY,
    repair_job_id INTEGER NOT NULL REFERENCES repair_jobs(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    image_type VARCHAR(50) NOT NULL DEFAULT 'DAMAGE', -- DAMAGE, DURING_REPAIR, COMPLETED, INVOICE, OTHER
    description TEXT,
    uploaded_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_images
CREATE INDEX IF NOT EXISTS idx_repair_images_repair_job ON repair_images(repair_job_id);
CREATE INDEX IF NOT EXISTS idx_repair_images_image_type ON repair_images(image_type);

-- Create repair_estimates table (store quotes/estimates)
CREATE TABLE IF NOT EXISTS repair_estimates (
    id SERIAL PRIMARY KEY,
    repair_job_id INTEGER NOT NULL REFERENCES repair_jobs(id) ON DELETE CASCADE,
    estimate_number VARCHAR(50) UNIQUE NOT NULL,
    estimated_parts_cost DECIMAL(10, 2),
    estimated_labor_cost DECIMAL(10, 2),
    estimated_total_cost DECIMAL(10, 2) NOT NULL,
    estimated_duration_days INTEGER,
    estimate_date TIMESTAMP NOT NULL,
    validity_days INTEGER DEFAULT 7,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED, EXPIRED
    created_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    approved_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_estimates
CREATE INDEX IF NOT EXISTS idx_repair_estimates_repair_job ON repair_estimates(repair_job_id);
CREATE INDEX IF NOT EXISTS idx_repair_estimates_status ON repair_estimates(status);
CREATE INDEX IF NOT EXISTS idx_repair_estimates_estimate_number ON repair_estimates(estimate_number);

-- Create repair_history table (historical record of all repairs per vehicle)
CREATE TABLE IF NOT EXISTS repair_history (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    repair_job_id INTEGER REFERENCES repair_jobs(id) ON DELETE SET NULL,
    repair_type VARCHAR(100) NOT NULL,
    description TEXT,
    cost DECIMAL(10, 2),
    repair_date DATE NOT NULL,
    mileage_at_repair INTEGER,
    technician_name VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for repair_history
CREATE INDEX IF NOT EXISTS idx_repair_history_vehicle ON repair_history(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_repair_history_repair_job ON repair_history(repair_job_id);
CREATE INDEX IF NOT EXISTS idx_repair_history_repair_date ON repair_history(repair_date);

-- Create triggers for updated_at columns
CREATE TRIGGER update_repair_jobs_updated_at BEFORE UPDATE ON repair_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repair_progress_updates_updated_at BEFORE UPDATE ON repair_progress_updates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repair_progress_updated_at BEFORE UPDATE ON repair_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repair_activities_updated_at BEFORE UPDATE ON repair_activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repair_parts_updated_at BEFORE UPDATE ON repair_parts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repair_images_updated_at BEFORE UPDATE ON repair_images
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repair_estimates_updated_at BEFORE UPDATE ON repair_estimates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repair_history_updated_at BEFORE UPDATE ON repair_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
