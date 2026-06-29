-- Ensure vehicles.profile_id -> profiles.id cascades on delete.
-- Run this in Supabase SQL Editor (or psql) for existing environments.

DO $$
DECLARE
  fk record;
BEGIN
  -- Drop any existing FK from vehicles.profile_id to profiles.id (name differs by environment).
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
END $$;

ALTER TABLE public.vehicles
  ADD CONSTRAINT vehicles_profile_id_fkey
  FOREIGN KEY (profile_id)
  REFERENCES public.profiles(id)
  ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_vehicles_profile_id ON public.vehicles(profile_id);

