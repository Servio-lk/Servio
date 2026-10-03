-- Fix infinite recursion in repair chat RLS policies
-- Previously, repair_members_member_read had a subquery referencing repair_conversation_members directly,
-- which caused Postgres error 42P17 (infinite recursion detected) and broke Supabase Realtime / REST queries.

-- 1. Helper function with SECURITY DEFINER to bypass RLS when checking membership
CREATE OR REPLACE FUNCTION public.is_repair_conversation_member(_conversation_id BIGINT, _user_id TEXT, _email TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.repair_conversation_members
    WHERE conversation_id = _conversation_id
      AND (
        member_user_id = _user_id
        OR member_user_id = _email
      )
  );
$$;

-- 2. Helper function with SECURITY DEFINER to bypass RLS when checking write access
CREATE OR REPLACE FUNCTION public.is_repair_conversation_writer(_conversation_id BIGINT, _user_id TEXT, _email TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.repair_conversation_members
    WHERE conversation_id = _conversation_id
      AND can_write = TRUE
      AND (
        member_user_id = _user_id
        OR member_user_id = _email
      )
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_repair_conversation_member TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_repair_conversation_writer TO authenticated, anon;

-- 3. Replace repair_conversation_members SELECT policy
DROP POLICY IF EXISTS repair_members_member_read ON repair_conversation_members;
CREATE POLICY repair_members_member_read
    ON repair_conversation_members FOR SELECT
    USING (
        member_user_id = auth.uid()::text
        OR member_user_id = auth.jwt() ->> 'email'
        OR public.is_repair_conversation_member(conversation_id, auth.uid()::text, auth.jwt() ->> 'email')
        OR EXISTS (
            SELECT 1
            FROM profiles p
            WHERE p.id = auth.uid()
              AND UPPER(COALESCE(p.role, '')) = 'ADMIN'
        )
    );

-- 4. Replace repair_conversations SELECT policy
DROP POLICY IF EXISTS repair_conversations_member_read ON repair_conversations;
CREATE POLICY repair_conversations_member_read
    ON repair_conversations FOR SELECT
    USING (
        public.is_repair_conversation_member(id, auth.uid()::text, auth.jwt() ->> 'email')
        OR EXISTS (
            SELECT 1
            FROM profiles p
            WHERE p.id = auth.uid()
              AND UPPER(COALESCE(p.role, '')) = 'ADMIN'
        )
    );

-- 5. Replace repair_messages SELECT & INSERT policies
DROP POLICY IF EXISTS repair_messages_member_read ON repair_messages;
CREATE POLICY repair_messages_member_read
    ON repair_messages FOR SELECT
    USING (
        public.is_repair_conversation_member(conversation_id, auth.uid()::text, auth.jwt() ->> 'email')
        OR EXISTS (
            SELECT 1
            FROM profiles p
            WHERE p.id = auth.uid()
              AND UPPER(COALESCE(p.role, '')) = 'ADMIN'
        )
    );

DROP POLICY IF EXISTS repair_messages_member_insert ON repair_messages;
CREATE POLICY repair_messages_member_insert
    ON repair_messages FOR INSERT
    WITH CHECK (
        public.is_repair_conversation_writer(conversation_id, auth.uid()::text, auth.jwt() ->> 'email')
        OR EXISTS (
            SELECT 1
            FROM profiles p
            WHERE p.id = auth.uid()
              AND UPPER(COALESCE(p.role, '')) = 'ADMIN'
        )
    );

-- Ensure replica identity full for realtime broadcasting
ALTER TABLE repair_messages REPLICA IDENTITY FULL;
