-- V19__appointment_concurrency_and_slot_constraints.sql
-- Servio: Enforce database-level uniqueness constraint on active appointment slots

-- Deduplicate any existing duplicate active appointments before creating unique index
-- Keep the most recent appointment (highest ID) and mark earlier duplicates as CANCELLED
UPDATE appointments
SET status = 'CANCELLED',
    notes = COALESCE(notes, '') || ' [Cancelled due to duplicate slot constraint]'
WHERE id IN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY appointment_date 
                   ORDER BY id DESC
               ) as rn
        FROM appointments
        WHERE status NOT IN ('CANCELLED')
    ) duplicates
    WHERE rn > 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_appointment_active_slot 
ON appointments (appointment_date) 
WHERE status NOT IN ('CANCELLED');
