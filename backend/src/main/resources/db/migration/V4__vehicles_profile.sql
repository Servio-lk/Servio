-- Add profile_id column to vehicles table for Supabase profile-based vehicle ownership
-- Run this in your Supabase SQL editor

-- Step 1: Make user_id nullable (Supabase users don't have a local user row)
ALTER TABLE vehicles ALTER COLUMN user_id DROP NOT NULL;

-- Step 2: Add profile_id column referencing the profiles table.
-- Use ON DELETE CASCADE so profile deletion also cleans up dependent vehicles.
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE;

-- Step 3: Create an index for fast lookups by profile
CREATE INDEX IF NOT EXISTS idx_vehicles_profile_id ON vehicles(profile_id);

-- Step 4: Enable RLS and allow users to manage only their own vehicles
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Ensure authenticated users can access the table/sequence (RLS still applies)
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE vehicles TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE vehicles_id_seq TO authenticated;

-- Remove any legacy/conflicting policies first.
DO $$
DECLARE
  p record;
BEGIN
  FOR p IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'vehicles'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON vehicles', p.policyname);
  END LOOP;
END $$;

DROP POLICY IF EXISTS "Users can read own vehicles" ON vehicles;
CREATE POLICY "Users can read own vehicles"
ON vehicles
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own vehicles" ON vehicles;
CREATE POLICY "Users can insert own vehicles"
ON vehicles
FOR INSERT
TO authenticated
WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own vehicles" ON vehicles;
CREATE POLICY "Users can update own vehicles"
ON vehicles
FOR UPDATE
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own vehicles" ON vehicles;
CREATE POLICY "Users can delete own vehicles"
ON vehicles
FOR DELETE
TO authenticated
USING (profile_id = auth.uid());
