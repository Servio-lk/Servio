ALTER TABLE job_cards ADD COLUMN IF NOT EXISTS billing_request_key VARCHAR(100) UNIQUE;

-- Preserve historical invoices. New invoices begin as drafts and are linked to jobs.
ALTER TABLE billing_invoices ADD COLUMN IF NOT EXISTS job_card_id BIGINT REFERENCES job_cards(id);
ALTER TABLE billing_invoices ADD COLUMN IF NOT EXISTS appointment_id BIGINT REFERENCES appointments(id);
ALTER TABLE billing_invoices ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'LKR';
ALTER TABLE billing_invoices ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'ISSUED';
ALTER TABLE billing_invoices ADD COLUMN IF NOT EXISTS issued_at TIMESTAMP;
ALTER TABLE billing_invoices ADD COLUMN IF NOT EXISTS void_reason TEXT;
ALTER TABLE billing_invoices ADD COLUMN IF NOT EXISTS request_key VARCHAR(100) UNIQUE;
UPDATE billing_invoices SET issued_at=date WHERE status='ISSUED' AND issued_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS one_live_invoice_per_job ON billing_invoices(job_card_id) WHERE status <> 'VOID';
CREATE UNIQUE INDEX IF NOT EXISTS one_live_invoice_per_appointment ON billing_invoices(appointment_id) WHERE appointment_id IS NOT NULL AND status <> 'VOID';
CREATE SEQUENCE IF NOT EXISTS billing_invoice_number_seq;
SELECT setval('billing_invoice_number_seq', GREATEST(COALESCE((SELECT MAX(id) FROM billing_invoices),0)+1,1),false);
CREATE TABLE job_charges (
 id BIGSERIAL PRIMARY KEY, job_card_id BIGINT NOT NULL REFERENCES job_cards(id),
 inventory_item_id BIGINT REFERENCES inventory_items(id), description VARCHAR(255) NOT NULL,
 quantity NUMERIC(19,2) NOT NULL CHECK(quantity>0), rate NUMERIC(19,2) NOT NULL CHECK(rate>=0),
 amount NUMERIC(19,2) NOT NULL CHECK(amount>=0), request_key VARCHAR(100) NOT NULL UNIQUE,
 created_by VARCHAR(255) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 reversed_at TIMESTAMP, reversed_by VARCHAR(255)
);
CREATE TABLE payment_allocations (
 id BIGSERIAL PRIMARY KEY, bill_id BIGINT NOT NULL REFERENCES billing_invoices(id),
 payment_id BIGINT NOT NULL REFERENCES payments(id), amount NUMERIC(19,2) NOT NULL CHECK(amount>0),
 created_by VARCHAR(255) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(bill_id,payment_id)
);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'LKR';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS request_key VARCHAR(100) UNIQUE;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS reference VARCHAR(255);
CREATE TABLE billing_refunds (
 id BIGSERIAL PRIMARY KEY, bill_id BIGINT REFERENCES billing_invoices(id),
 payment_id BIGINT NOT NULL REFERENCES payments(id), amount NUMERIC(19,2) NOT NULL CHECK(amount>0),
 reason TEXT NOT NULL, reference VARCHAR(255) NOT NULL, request_key VARCHAR(100) NOT NULL UNIQUE,
 recorded_by VARCHAR(255) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE mechanic_salary_agreements (
 id BIGSERIAL PRIMARY KEY, mechanic_id BIGINT NOT NULL REFERENCES mechanics(id),
 effective_from DATE NOT NULL CHECK(EXTRACT(DAY FROM effective_from)=1),
 basic_salary NUMERIC(19,2) NOT NULL CHECK(basic_salary>=0), allowances NUMERIC(19,2) NOT NULL CHECK(allowances>=0),
 overtime_rate NUMERIC(19,2) NOT NULL CHECK(overtime_rate>=0),
 leave_divisor NUMERIC(5,2) NOT NULL CHECK(leave_divisor>0 AND leave_divisor<=31),
 created_by VARCHAR(255) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(mechanic_id,effective_from)
);
CREATE TABLE mechanic_attendance (
 id BIGSERIAL PRIMARY KEY, mechanic_id BIGINT NOT NULL REFERENCES mechanics(id), work_date DATE NOT NULL,
 status VARCHAR(20) NOT NULL CHECK(status IN ('PRESENT','PAID_LEAVE','UNPAID_LEAVE','OFF')),
 overtime_hours NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK(overtime_hours>=0 AND overtime_hours<=24),
 approved BOOLEAN NOT NULL DEFAULT false, recorded_by VARCHAR(255) NOT NULL,
 UNIQUE(mechanic_id,work_date)
);
CREATE TABLE salary_advances (
 id BIGSERIAL PRIMARY KEY, mechanic_id BIGINT NOT NULL REFERENCES mechanics(id),
 amount NUMERIC(19,2) NOT NULL CHECK(amount>0), paid_date DATE NOT NULL, reference VARCHAR(255) NOT NULL,
 request_key VARCHAR(100) NOT NULL UNIQUE, recorded_by VARCHAR(255) NOT NULL
);
CREATE TABLE payroll_runs (
 id BIGSERIAL PRIMARY KEY, payroll_month DATE NOT NULL UNIQUE CHECK(EXTRACT(DAY FROM payroll_month)=1),
 status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK(status IN ('DRAFT','APPROVED','CLOSED')),
 created_by VARCHAR(255) NOT NULL, approved_by VARCHAR(255), approved_at TIMESTAMP,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE payroll_items (
 id BIGSERIAL PRIMARY KEY, run_id BIGINT NOT NULL REFERENCES payroll_runs(id), mechanic_id BIGINT NOT NULL REFERENCES mechanics(id),
 mechanic_name VARCHAR(255) NOT NULL, agreement_id BIGINT NOT NULL REFERENCES mechanic_salary_agreements(id),
 basic_salary NUMERIC(19,2) NOT NULL, allowances NUMERIC(19,2) NOT NULL,
 overtime_hours NUMERIC(7,2) NOT NULL, overtime_rate NUMERIC(19,2) NOT NULL, overtime_pay NUMERIC(19,2) NOT NULL,
 unpaid_days NUMERIC(5,2) NOT NULL, leave_divisor NUMERIC(5,2) NOT NULL, leave_deduction NUMERIC(19,2) NOT NULL,
 gross_salary NUMERIC(19,2) NOT NULL, advance_recovery NUMERIC(19,2) NOT NULL DEFAULT 0,
 other_deduction NUMERIC(19,2) NOT NULL DEFAULT 0, adjustment_reason TEXT,
 net_payable NUMERIC(19,2) NOT NULL CHECK(net_payable>=0), UNIQUE(run_id,mechanic_id)
);
CREATE TABLE salary_advance_recoveries (
 id BIGSERIAL PRIMARY KEY, advance_id BIGINT NOT NULL REFERENCES salary_advances(id),
 payroll_item_id BIGINT NOT NULL REFERENCES payroll_items(id), amount NUMERIC(19,2) NOT NULL CHECK(amount>0),
 UNIQUE(advance_id,payroll_item_id)
);
CREATE TABLE salary_payments (
 id BIGSERIAL PRIMARY KEY, payroll_item_id BIGINT NOT NULL REFERENCES payroll_items(id),
 amount NUMERIC(19,2) NOT NULL CHECK(amount>0), method VARCHAR(20) NOT NULL CHECK(method IN ('CASH','BANK_TRANSFER')),
 reference VARCHAR(255) NOT NULL, request_key VARCHAR(100) NOT NULL UNIQUE,
 recorded_by VARCHAR(255) NOT NULL, paid_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE finance_audit (
 id BIGSERIAL PRIMARY KEY, resource_type VARCHAR(30) NOT NULL, resource_id BIGINT NOT NULL,
 action VARCHAR(30) NOT NULL, actor VARCHAR(255) NOT NULL, details TEXT,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX payment_allocations_payment_idx ON payment_allocations(payment_id);
CREATE INDEX job_charges_job_idx ON job_charges(job_card_id);
CREATE INDEX attendance_month_idx ON mechanic_attendance(work_date,mechanic_id);

CREATE TABLE payment_attempts (
 order_id VARCHAR(100) PRIMARY KEY, appointment_id BIGINT NOT NULL REFERENCES appointments(id),
 expected_amount NUMERIC(19,2) NOT NULL CHECK(expected_amount>0), currency VARCHAR(3) NOT NULL DEFAULT 'LKR',
 status VARCHAR(20) NOT NULL DEFAULT 'PENDING', transaction_id VARCHAR(255),
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, expires_at TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX one_pending_payment_attempt ON payment_attempts(appointment_id) WHERE status='PENDING';

-- Finance is served through the admin backend, never through public Supabase clients.
-- The migration/table owner continues to access these tables through JDBC.
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
