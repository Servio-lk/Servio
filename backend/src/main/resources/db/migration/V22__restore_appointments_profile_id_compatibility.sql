-- V22__restore_appointments_profile_id_compatibility.sql
-- Restore profile_id column on appointments for backward compatibility with queries expecting profile_id

ALTER TABLE appointments ADD COLUMN IF NOT EXISTS profile_id UUID;

-- Backfill profile_id from user_id where currently null
UPDATE appointments SET profile_id = user_id WHERE profile_id IS NULL AND user_id IS NOT NULL;

-- Automatically keep profile_id and user_id in sync
CREATE OR REPLACE FUNCTION sync_appointments_profile_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.profile_id IS NULL AND NEW.user_id IS NOT NULL THEN
        NEW.profile_id := NEW.user_id;
    ELSIF NEW.user_id IS NULL AND NEW.profile_id IS NOT NULL THEN
        NEW.user_id := NEW.profile_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_appointments_profile_id ON appointments;
CREATE TRIGGER trg_sync_appointments_profile_id
BEFORE INSERT OR UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION sync_appointments_profile_id();

CREATE INDEX IF NOT EXISTS idx_appointments_profile_id ON appointments(profile_id);
