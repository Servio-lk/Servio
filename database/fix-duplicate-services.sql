-- ═══════════════════════════════════════════════════════════════════════════
-- Servio: Fix Duplicate Services
-- Run this in Supabase SQL Editor to remove duplicate rows
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1. CHECK CURRENT STATE ─────────────────────────────────────────────────

-- See how many duplicates exist
SELECT name, COUNT(*) as count FROM service_categories GROUP BY name HAVING COUNT(*) > 1;
SELECT name, category_id, COUNT(*) as count FROM services GROUP BY name, category_id HAVING COUNT(*) > 1;
SELECT name, service_id, COUNT(*) as count FROM service_options GROUP BY name, service_id HAVING COUNT(*) > 1;

-- ─── 2. REMOVE DUPLICATE SERVICE OPTIONS (keep lowest id) ───────────────────

DELETE FROM service_options
WHERE id NOT IN (
    SELECT MIN(id) FROM service_options GROUP BY service_id, name
);

-- ─── 3. REMOVE DUPLICATE SERVICES (keep lowest id) ──────────────────────────

DELETE FROM services
WHERE id NOT IN (
    SELECT MIN(id) FROM services GROUP BY category_id, name
);

-- ─── 4. REMOVE DUPLICATE CATEGORIES (keep lowest id) ────────────────────────

DELETE FROM service_categories
WHERE id NOT IN (
    SELECT MIN(id) FROM service_categories GROUP BY name
);

-- ─── 5. ADD UNIQUE CONSTRAINTS TO PREVENT THIS FROM HAPPENING AGAIN ─────────

ALTER TABLE service_categories ADD CONSTRAINT uq_service_categories_name UNIQUE (name);
ALTER TABLE services ADD CONSTRAINT uq_services_category_name UNIQUE (category_id, name);
ALTER TABLE service_options ADD CONSTRAINT uq_service_options_service_name UNIQUE (service_id, name);

-- ─── 6. VERIFY ──────────────────────────────────────────────────────────────

SELECT 'Categories: ' || COUNT(*) FROM service_categories;
SELECT 'Services: ' || COUNT(*) FROM services;
SELECT 'Options: ' || COUNT(*) FROM service_options;

