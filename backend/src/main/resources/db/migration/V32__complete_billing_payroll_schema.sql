-- Forward-only completion for databases that already applied the first V31 draft.
-- All existing finance rows and historical invoice amounts are preserved.
ALTER TABLE job_cards ADD COLUMN IF NOT EXISTS billing_request_key VARCHAR(100) UNIQUE;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS reference VARCHAR(255);
ALTER TABLE billing_refunds ALTER COLUMN bill_id DROP NOT NULL;
UPDATE billing_invoices SET issued_at=date WHERE status='ISSUED' AND issued_at IS NULL;
CREATE TABLE IF NOT EXISTS payment_attempts (
 order_id VARCHAR(100) PRIMARY KEY, appointment_id BIGINT NOT NULL REFERENCES appointments(id),
 expected_amount NUMERIC(19,2) NOT NULL CHECK(expected_amount>0), currency VARCHAR(3) NOT NULL DEFAULT 'LKR',
 status VARCHAR(20) NOT NULL DEFAULT 'PENDING', transaction_id VARCHAR(255),
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, expires_at TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS one_pending_payment_attempt ON payment_attempts(appointment_id) WHERE status='PENDING';
ALTER TABLE billing_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE mechanic_salary_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE mechanic_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_advance_recoveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_attempts ENABLE ROW LEVEL SECURITY;
DO $$
DECLARE finance_role TEXT;
BEGIN
  FOREACH finance_role IN ARRAY ARRAY['anon','authenticated'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=finance_role) THEN
      EXECUTE format('REVOKE ALL ON billing_invoices,billing_invoice_items,job_charges,payment_allocations,billing_refunds,mechanic_salary_agreements,mechanic_attendance,salary_advances,payroll_runs,payroll_items,salary_advance_recoveries,salary_payments,finance_audit,payment_attempts FROM %I',finance_role);
    END IF;
  END LOOP;
END $$;
