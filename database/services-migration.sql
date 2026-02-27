-- ═══════════════════════════════════════════════════════════════════════════
-- Servio: Service Catalog Migration for Supabase
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
--
-- NOTE: This script only creates tables, indexes, and RLS policies.
-- It does NOT insert any data — the backend DataSeeder handles seeding.
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1. CREATE TABLES (if they don't exist) ──────────────────────────────────

CREATE TABLE IF NOT EXISTS service_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    base_price DECIMAL(10, 2),
    price_range VARCHAR(50),
    duration_minutes INTEGER,
    image_url VARCHAR(500),
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (category_id, name)
);

CREATE TABLE IF NOT EXISTS service_options (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price_adjustment DECIMAL(10, 2) DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (service_id, name)
);

-- ─── 2. CREATE INDEXES ──────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_services_category_id ON services(category_id);
CREATE INDEX IF NOT EXISTS idx_services_is_active ON services(is_active);
CREATE INDEX IF NOT EXISTS idx_services_is_featured ON services(is_featured);
CREATE INDEX IF NOT EXISTS idx_service_options_service_id ON service_options(service_id);

-- ─── 3. ENABLE RLS + PUBLIC READ ────────────────────────────────────────────

ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_options ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'service_categories' AND policyname = 'Public read service_categories') THEN
        EXECUTE 'CREATE POLICY "Public read service_categories" ON service_categories FOR SELECT USING (true)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'services' AND policyname = 'Public read services') THEN
        EXECUTE 'CREATE POLICY "Public read services" ON services FOR SELECT USING (true)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'service_options' AND policyname = 'Public read service_options') THEN
        EXECUTE 'CREATE POLICY "Public read service_options" ON service_options FOR SELECT USING (true)';
    END IF;
END $$;
