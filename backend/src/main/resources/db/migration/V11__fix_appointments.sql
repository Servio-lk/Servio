-- Add profile_id column to appointments table to support Supabase users
-- This allows linking appointments to Supabase profiles (UUID) in addition to local users (INTEGER)

ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_appointments_profile_id ON appointments(profile_id);

-- Make user_id nullable since we'll use either user_id OR profile_id
ALTER TABLE appointments 
ALTER COLUMN user_id DROP NOT NULL;

-- Add a check constraint to ensure at least one of user_id or profile_id is set
ALTER TABLE appointments
ADD CONSTRAINT check_user_or_profile CHECK (
    (user_id IS NOT NULL AND profile_id IS NULL) OR
    (user_id IS NULL AND profile_id IS NOT NULL)
);

-- Comment for documentation
COMMENT ON COLUMN appointments.profile_id IS 'Reference to Supabase profile (UUID) - use either user_id or profile_id';
COMMENT ON COLUMN appointments.user_id IS 'Reference to local user (INTEGER) - use either user_id or profile_id';
