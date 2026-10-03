-- V28__verify_and_activate_mechanics.sql
-- Ensure all existing and logged in mechanics are active and verified

UPDATE mechanics
SET is_active = true,
    verification_status = 'VERIFIED'
WHERE is_active = false OR verification_status != 'VERIFIED' OR verification_status IS NULL;

INSERT INTO mechanics (full_name, email, phone, specialization, status, is_active, verification_status, created_at, updated_at)
SELECT 'Jayantha Gurugamage', 'jpgurugamage@gmail.com', '+94770000000', 'Master Technician', 'AVAILABLE', true, 'VERIFIED', NOW(), NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM mechanics WHERE LOWER(email) = 'jpgurugamage@gmail.com'
);
