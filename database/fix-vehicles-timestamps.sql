-- Fix vehicles timestamp defaults for Supabase/PostgREST inserts
-- Run this in Supabase SQL Editor for each environment.

BEGIN;

-- Backfill existing rows if any were inserted before this fix.
UPDATE public.vehicles
SET created_at = COALESCE(created_at, NOW()),
    updated_at = COALESCE(updated_at, NOW())
WHERE created_at IS NULL OR updated_at IS NULL;

-- Ensure inserts do not fail when timestamp fields are omitted.
ALTER TABLE public.vehicles
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET DEFAULT NOW();

-- Keep created_at mandatory while preserving automatic default behavior.
ALTER TABLE public.vehicles
  ALTER COLUMN created_at SET NOT NULL;

COMMIT;

