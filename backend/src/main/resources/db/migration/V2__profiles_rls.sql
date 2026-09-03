-- Ensure profiles are created/managed correctly for Supabase-authenticated users.

BEGIN;

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY,
    full_name VARCHAR(255),
    avatar_url VARCHAR(500),
    username VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(50),
    role VARCHAR(50),
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    joined TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO authenticated';
  END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS auth;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace n ON pg_proc.pronamespace = n.oid WHERE proname = 'uid' AND n.nspname = 'auth') THEN
    CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS 'SELECT ''00000000-0000-0000-0000-000000000000''::uuid;' LANGUAGE sql STABLE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc JOIN pg_namespace n ON pg_proc.pronamespace = n.oid WHERE proname = 'jwt' AND n.nspname = 'auth') THEN
    CREATE OR REPLACE FUNCTION auth.jwt() RETURNS jsonb AS 'SELECT ''{}''::jsonb;' LANGUAGE sql STABLE;
  END IF;
END $$;

DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
CREATE POLICY "Users can read own profile"
ON public.profiles
FOR SELECT
USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
ON public.profiles
FOR INSERT
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY,
    email VARCHAR(255),
    raw_user_meta_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile rows when a new auth user is created.
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data ->> 'full_name',
      NEW.raw_user_meta_data ->> 'display_name'
    ),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_profile
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user_profile();

COMMIT;

