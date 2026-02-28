-- Add profile_id column to vehicles table for Supabase profile-based vehicle ownership
-- Run this in your Supabase SQL editor

-- Step 1: Make user_id nullable (Supabase users don't have a local user row)
ALTER TABLE vehicles ALTER COLUMN user_id DROP NOT NULL;

-- Step 2: Add profile_id column referencing the profiles table
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS profile_id UUID REFERENCES profiles(id);

-- Step 3: Create an index for fast lookups by profile
CREATE INDEX IF NOT EXISTS idx_vehicles_profile_id ON vehicles(profile_id);

