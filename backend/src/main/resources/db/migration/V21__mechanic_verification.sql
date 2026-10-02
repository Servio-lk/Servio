-- V21__mechanic_verification.sql
-- Add verification status and rejection reason to mechanics table

ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) NOT NULL DEFAULT 'VERIFIED';
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_mechanics_verification_status ON mechanics(verification_status);
