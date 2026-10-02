-- V26__align_vehicles_vehicle_year.sql
-- Servio: Add vehicle_year column to vehicles table and sync with year for backward compatibility

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS vehicle_year INTEGER;

-- Backfill vehicle_year from year where null
UPDATE vehicles SET vehicle_year = year WHERE vehicle_year IS NULL AND year IS NOT NULL;
UPDATE vehicles SET year = vehicle_year WHERE year IS NULL AND vehicle_year IS NOT NULL;

-- Automatically keep year and vehicle_year in sync
CREATE OR REPLACE FUNCTION sync_vehicles_year()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.vehicle_year IS NULL AND NEW.year IS NOT NULL THEN
        NEW.vehicle_year := NEW.year;
    ELSIF NEW.year IS NULL AND NEW.vehicle_year IS NOT NULL THEN
        NEW.year := NEW.vehicle_year;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_vehicles_year ON vehicles;
CREATE TRIGGER trg_sync_vehicles_year
BEFORE INSERT OR UPDATE ON vehicles
FOR EACH ROW
EXECUTE FUNCTION sync_vehicles_year();
