-- Servio: Admin service management, selectable packages, photos, and realtime notifications

ALTER TABLE services
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED',
  ADD COLUMN IF NOT EXISTS warranty_included BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS published_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS customer_notified_at TIMESTAMP;

ALTER TABLE services
  DROP COLUMN IF EXISTS rating,
  DROP COLUMN IF EXISTS review_count;

UPDATE services
SET status = CASE WHEN is_active IS TRUE THEN 'PUBLISHED' ELSE 'HIDDEN' END
WHERE status IS NULL;

UPDATE services
SET published_at = COALESCE(published_at, created_at)
WHERE status = 'PUBLISHED';

CREATE TABLE IF NOT EXISTS service_included_items (
  service_id BIGINT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  display_order INTEGER NOT NULL DEFAULT 0,
  item TEXT NOT NULL,
  PRIMARY KEY (service_id, display_order)
);

CREATE TABLE IF NOT EXISTS service_photos (
  id BIGSERIAL PRIMARY KEY,
  service_id BIGINT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  url VARCHAR(500) NOT NULL,
  public_id VARCHAR(255),
  display_order INTEGER DEFAULT 0,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE service_options
  ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_services_status ON services(status);
CREATE INDEX IF NOT EXISTS idx_service_photos_service_id ON service_photos(service_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- Supabase Realtime uses the publication below for postgres_changes subscriptions.
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;
END $$;
