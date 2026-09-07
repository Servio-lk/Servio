-- V17__fix_profile_cascade.sql
-- Fix appointments and vehicles profile cascade constraints to ON DELETE SET NULL
-- This ensures that when a user profile is deleted (anonymized), their data is retained
-- under the local backend user_id instead of being cascade-deleted.

DO $$
DECLARE
  fk record;
BEGIN
  -- Drop any existing FK from vehicles.profile_id to profiles.id
  FOR fk IN
    SELECT c.conname
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace tn ON tn.oid = t.relnamespace
    JOIN pg_class r ON r.oid = c.confrelid
    JOIN pg_namespace rn ON rn.oid = r.relnamespace
    JOIN unnest(c.conkey) WITH ORDINALITY AS ck(attnum, ord) ON true
    JOIN pg_attribute ca ON ca.attrelid = t.oid AND ca.attnum = ck.attnum
    JOIN unnest(c.confkey) WITH ORDINALITY AS rk(attnum, ord) ON rk.ord = ck.ord
    JOIN pg_attribute ra ON ra.attrelid = r.oid AND ra.attnum = rk.attnum
    WHERE c.contype = 'f'
      AND tn.nspname = 'public'
      AND t.relname = 'vehicles'
      AND rn.nspname = 'public'
      AND r.relname = 'profiles'
      AND ca.attname = 'profile_id'
      AND ra.attname = 'id'
  LOOP
    EXECUTE format('ALTER TABLE public.vehicles DROP CONSTRAINT %I', fk.conname);
  END LOOP;

  -- Drop any existing FK from appointments.profile_id to profiles.id
  FOR fk IN
    SELECT c.conname
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace tn ON tn.oid = t.relnamespace
    JOIN pg_class r ON r.oid = c.confrelid
    JOIN pg_namespace rn ON rn.oid = r.relnamespace
    JOIN unnest(c.conkey) WITH ORDINALITY AS ck(attnum, ord) ON true
    JOIN pg_attribute ca ON ca.attrelid = t.oid AND ca.attnum = ck.attnum
    JOIN unnest(c.confkey) WITH ORDINALITY AS rk(attnum, ord) ON rk.ord = ck.ord
    JOIN pg_attribute ra ON ra.attrelid = r.oid AND ra.attnum = rk.attnum
    WHERE c.contype = 'f'
      AND tn.nspname = 'public'
      AND t.relname = 'appointments'
      AND rn.nspname = 'public'
      AND r.relname = 'profiles'
      AND ca.attname = 'profile_id'
      AND ra.attname = 'id'
  LOOP
    EXECUTE format('ALTER TABLE public.appointments DROP CONSTRAINT %I', fk.conname);
  END LOOP;
END $$;

-- 1. Modify appointments profile_id constraint to ON DELETE SET NULL
ALTER TABLE public.appointments ADD CONSTRAINT appointments_profile_id_fkey 
    FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 2. Modify appointments check constraint to allow user_id to be NOT NULL even if profile_id is NULL
ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS chk_appointments_user_or_profile;
ALTER TABLE public.appointments ADD CONSTRAINT chk_appointments_user_or_profile 
    CHECK (user_id IS NOT NULL OR profile_id IS NOT NULL);

-- 3. Modify vehicles profile_id constraint to ON DELETE SET NULL
ALTER TABLE public.vehicles ADD CONSTRAINT vehicles_profile_id_fkey 
    FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
