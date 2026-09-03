-- V19__appointment_concurrency_and_slot_constraints.sql
-- Servio: Enforce database-level uniqueness constraint on active appointment slots

CREATE UNIQUE INDEX IF NOT EXISTS uq_appointment_active_slot 
ON appointments (appointment_date) 
WHERE status NOT IN ('CANCELLED');
