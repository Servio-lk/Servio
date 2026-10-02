-- V23: Create part_requests table and enhance job_tasks with appointment linking

-- 1. Create part_requests table
CREATE TABLE IF NOT EXISTS part_requests (
    id BIGSERIAL PRIMARY KEY,
    mechanic_id BIGINT REFERENCES mechanics(id) ON DELETE SET NULL,
    appointment_id BIGINT REFERENCES appointments(id) ON DELETE SET NULL,
    part_name VARCHAR(255) NOT NULL,
    part_number VARCHAR(100),
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1,
    unit VARCHAR(50) DEFAULT 'units',
    urgency VARCHAR(50) NOT NULL DEFAULT 'STANDARD',
    notes TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Performance indexes for part_requests
CREATE INDEX IF NOT EXISTS idx_part_requests_status ON part_requests(status);
CREATE INDEX IF NOT EXISTS idx_part_requests_appointment_id ON part_requests(appointment_id);
CREATE INDEX IF NOT EXISTS idx_part_requests_mechanic_id ON part_requests(mechanic_id);

-- Ensure update_updated_at_column function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Updated_at trigger for part_requests
DROP TRIGGER IF EXISTS update_part_requests_updated_at ON part_requests;
CREATE TRIGGER update_part_requests_updated_at BEFORE UPDATE ON part_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS for part_requests
ALTER TABLE part_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS part_requests_select_policy ON part_requests;
CREATE POLICY part_requests_select_policy ON part_requests FOR SELECT USING (true);
DROP POLICY IF EXISTS part_requests_insert_policy ON part_requests;
CREATE POLICY part_requests_insert_policy ON part_requests FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS part_requests_update_policy ON part_requests;
CREATE POLICY part_requests_update_policy ON part_requests FOR UPDATE USING (true);

-- 2. Enhance job_tasks table with appointment_id and flexible constraints
ALTER TABLE job_tasks ADD COLUMN IF NOT EXISTS appointment_id BIGINT REFERENCES appointments(id) ON DELETE CASCADE;
ALTER TABLE job_tasks ALTER COLUMN job_card_id DROP NOT NULL;
ALTER TABLE job_tasks ALTER COLUMN task_number DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_tasks_appointment_id ON job_tasks(appointment_id);

-- Backfill appointment_id on existing job_tasks from job_cards
UPDATE job_tasks jt
SET appointment_id = jc.appointment_id
FROM job_cards jc
WHERE jt.job_card_id = jc.id
  AND jt.appointment_id IS NULL
  AND jc.appointment_id IS NOT NULL;

-- 3. Register tables in Supabase Realtime publication
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE part_requests;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE job_tasks;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE repair_messages;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;
END $$;
