-- Servio staff registration details and Cloudinary document metadata.

CREATE TABLE IF NOT EXISTS mechanics (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    specialization VARCHAR(255),
    experience_years INTEGER,
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT mechanic_status_check CHECK (status IN ('AVAILABLE', 'BUSY', 'ON_LEAVE'))
);

CREATE INDEX IF NOT EXISTS idx_mechanics_email ON mechanics(email);
CREATE INDEX IF NOT EXISTS idx_mechanics_status ON mechanics(status);
CREATE INDEX IF NOT EXISTS idx_mechanics_is_active ON mechanics(is_active);

CREATE TABLE IF NOT EXISTS mechanic_staff_details (
    id BIGSERIAL PRIMARY KEY,
    mechanic_id BIGINT NOT NULL UNIQUE REFERENCES mechanics(id) ON DELETE CASCADE,
    employee_code VARCHAR(100) NOT NULL UNIQUE,
    branch VARCHAR(150),
    job_title VARCHAR(150),
    employment_type VARCHAR(50),
    joining_date DATE,
    skill_tags TEXT,
    nic_number VARCHAR(30),
    passport_number VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(30),
    driving_license_number VARCHAR(80),
    license_classes VARCHAR(120),
    license_expiry_date DATE,
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(120),
    district VARCHAR(120),
    postal_code VARCHAR(30),
    emergency_contact_name VARCHAR(150),
    emergency_contact_relationship VARCHAR(80),
    emergency_contact_phone VARCHAR(30),
    bank_name VARCHAR(120),
    bank_branch VARCHAR(120),
    account_holder_name VARCHAR(150),
    account_number VARCHAR(80),
    epf_number VARCHAR(80),
    etf_number VARCHAR(80),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mechanic_documents (
    id BIGSERIAL PRIMARY KEY,
    mechanic_id BIGINT NOT NULL REFERENCES mechanics(id) ON DELETE CASCADE,
    document_type VARCHAR(80) NOT NULL,
    original_filename VARCHAR(255),
    url VARCHAR(1000) NOT NULL,
    public_id VARCHAR(255) NOT NULL,
    resource_type VARCHAR(50),
    content_type VARCHAR(120),
    file_size_bytes BIGINT,
    uploaded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mechanic_staff_details_employee_code
    ON mechanic_staff_details(employee_code);
CREATE INDEX IF NOT EXISTS idx_mechanic_documents_mechanic
    ON mechanic_documents(mechanic_id);
CREATE INDEX IF NOT EXISTS idx_mechanic_documents_type
    ON mechanic_documents(document_type);
