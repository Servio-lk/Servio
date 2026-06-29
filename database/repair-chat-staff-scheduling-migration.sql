-- Repair chat, conversation membership, and mechanic scheduling.

ALTER TABLE repair_jobs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE repair_jobs ALTER COLUMN vehicle_id DROP NOT NULL;

CREATE TABLE IF NOT EXISTS repair_conversations (
    id BIGSERIAL PRIMARY KEY,
    repair_job_id BIGINT NOT NULL UNIQUE REFERENCES repair_jobs(id) ON DELETE CASCADE,
    is_read_only BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS repair_conversation_members (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES repair_conversations(id) ON DELETE CASCADE,
    role VARCHAR(32) NOT NULL CHECK (role IN ('CLIENT', 'MECHANIC', 'ADMIN')),
    member_ref VARCHAR(128) NOT NULL,
    member_user_id VARCHAR(128),
    mechanic_id BIGINT REFERENCES mechanics(id) ON DELETE SET NULL,
    can_write BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_repair_conversation_member_role_ref UNIQUE (conversation_id, role, member_ref)
);

CREATE TABLE IF NOT EXISTS repair_messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES repair_conversations(id) ON DELETE CASCADE,
    repair_job_id BIGINT NOT NULL REFERENCES repair_jobs(id) ON DELETE CASCADE,
    sender_id VARCHAR(128) NOT NULL,
    sender_role VARCHAR(32) NOT NULL,
    body TEXT NOT NULL,
    read_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mechanic_schedules (
    id BIGSERIAL PRIMARY KEY,
    mechanic_id BIGINT NOT NULL REFERENCES mechanics(id) ON DELETE CASCADE,
    day_of_week VARCHAR(16) NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (shift_start < shift_end)
);

CREATE TABLE IF NOT EXISTS mechanic_unavailable_blocks (
    id BIGSERIAL PRIMARY KEY,
    mechanic_id BIGINT NOT NULL REFERENCES mechanics(id) ON DELETE CASCADE,
    starts_at TIMESTAMP NOT NULL,
    ends_at TIMESTAMP NOT NULL,
    reason VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (starts_at < ends_at)
);

CREATE INDEX IF NOT EXISTS idx_repair_messages_conversation_created
    ON repair_messages(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_repair_conversation_members_user
    ON repair_conversation_members(member_user_id, conversation_id);
CREATE INDEX IF NOT EXISTS idx_mechanic_schedules_mechanic
    ON mechanic_schedules(mechanic_id);
CREATE INDEX IF NOT EXISTS idx_mechanic_unavailable_blocks_mechanic
    ON mechanic_unavailable_blocks(mechanic_id, starts_at);

ALTER TABLE repair_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE repair_conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE repair_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS repair_conversations_member_read ON repair_conversations;
CREATE POLICY repair_conversations_member_read
    ON repair_conversations FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = id
              AND m.member_user_id = auth.uid()::text
        )
        OR EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = id
              AND m.member_user_id = auth.jwt() ->> 'email'
        )
        OR EXISTS (
            SELECT 1
            FROM profiles p
            WHERE p.id = auth.uid()
              AND UPPER(COALESCE(p.role, '')) = 'ADMIN'
        )
    );

DROP POLICY IF EXISTS repair_members_member_read ON repair_conversation_members;
CREATE POLICY repair_members_member_read
    ON repair_conversation_members FOR SELECT
    USING (
        member_user_id = auth.uid()::text
        OR member_user_id = auth.jwt() ->> 'email'
        OR EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = repair_conversation_members.conversation_id
              AND m.member_user_id = auth.uid()::text
        )
        OR EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = repair_conversation_members.conversation_id
              AND m.member_user_id = auth.jwt() ->> 'email'
        )
        OR EXISTS (
            SELECT 1
            FROM profiles p
            WHERE p.id = auth.uid()
              AND UPPER(COALESCE(p.role, '')) = 'ADMIN'
        )
    );

DROP POLICY IF EXISTS repair_messages_member_read ON repair_messages;
CREATE POLICY repair_messages_member_read
    ON repair_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = repair_messages.conversation_id
              AND m.member_user_id = auth.uid()::text
        )
        OR EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = repair_messages.conversation_id
              AND m.member_user_id = auth.jwt() ->> 'email'
        )
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
        EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = repair_messages.conversation_id
              AND m.member_user_id = auth.uid()::text
              AND m.can_write = TRUE
        )
        OR EXISTS (
            SELECT 1
            FROM repair_conversation_members m
            WHERE m.conversation_id = repair_messages.conversation_id
              AND m.member_user_id = auth.jwt() ->> 'email'
              AND m.can_write = TRUE
        )
        OR EXISTS (
            SELECT 1
            FROM profiles p
            WHERE p.id = auth.uid()
              AND UPPER(COALESCE(p.role, '')) = 'ADMIN'
        )
    );
