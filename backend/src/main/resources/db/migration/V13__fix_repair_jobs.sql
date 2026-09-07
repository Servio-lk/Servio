-- Allows repair jobs created from Supabase-profile appointments to exist even
-- when the appointment has no local users row or no selected vehicle.
ALTER TABLE repair_jobs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE repair_jobs ALTER COLUMN vehicle_id DROP NOT NULL;
