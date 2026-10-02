-- V20__align_job_card_notes_photos_uuid.sql
-- Servio: Align job_card_notes, job_card_photos, and walk_in_customers user references to UUID

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_card_notes' AND column_name = 'created_by_id' AND data_type LIKE '%int%'
    ) THEN
        ALTER TABLE job_card_notes DROP COLUMN created_by_id;
        ALTER TABLE job_card_notes ADD COLUMN created_by_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_card_notes' AND column_name = 'created_by_id'
    ) THEN
        ALTER TABLE job_card_notes ADD COLUMN created_by_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_card_photos' AND column_name = 'uploaded_by_id' AND data_type LIKE '%int%'
    ) THEN
        ALTER TABLE job_card_photos DROP COLUMN uploaded_by_id;
        ALTER TABLE job_card_photos ADD COLUMN uploaded_by_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_card_photos' AND column_name = 'uploaded_by_id'
    ) THEN
        ALTER TABLE job_card_photos ADD COLUMN uploaded_by_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'walk_in_customers' AND column_name = 'registered_user_id' AND data_type LIKE '%int%'
    ) THEN
        ALTER TABLE walk_in_customers DROP COLUMN registered_user_id;
        ALTER TABLE walk_in_customers ADD COLUMN registered_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'walk_in_customers' AND column_name = 'registered_user_id'
    ) THEN
        ALTER TABLE walk_in_customers ADD COLUMN registered_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Ensure billing_invoices and billing_invoice_items exist for Billing entity JPA validation
CREATE TABLE IF NOT EXISTS billing_invoices (
    id BIGSERIAL PRIMARY KEY,
    invoice_no VARCHAR(100) UNIQUE NOT NULL,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    customer_name VARCHAR(255),
    customer_address VARCHAR(255),
    customer_phone VARCHAR(50),
    vehicle_type VARCHAR(100),
    vehicle_no VARCHAR(50),
    payment_mode VARCHAR(50),
    sub_total NUMERIC(19,2),
    discount NUMERIC(19,2),
    net_total NUMERIC(19,2),
    current_meter_reading VARCHAR(50),
    next_service_due VARCHAR(50),
    issued_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_billing_invoices_invoice_no ON billing_invoices(invoice_no);

CREATE TABLE IF NOT EXISTS billing_invoice_items (
    id BIGSERIAL PRIMARY KEY,
    bill_id BIGINT NOT NULL REFERENCES billing_invoices(id) ON DELETE CASCADE,
    inventory_item_id BIGINT,
    description VARCHAR(255) NOT NULL,
    quantity NUMERIC(19,2) NOT NULL,
    rate NUMERIC(19,2) NOT NULL,
    amount NUMERIC(19,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_billing_invoice_items_bill_id ON billing_invoice_items(bill_id);
