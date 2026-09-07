-- Add role column to users table for admin panel functionality
-- This migration adds role-based access control to the system

-- Add role enum column with default value CUSTOMER
ALTER TABLE users
ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER';

-- Add check constraint to ensure valid role values
ALTER TABLE users
ADD CONSTRAINT users_role_check
CHECK (role IN ('CUSTOMER', 'ADMIN', 'STAFF'));

-- Create an admin user for testing (password: admin123)
-- Note: This is for development only, remove or change in production
INSERT INTO users (full_name, email, phone, password_hash, role, created_at, updated_at)
VALUES (
    'Admin User',
    'admin@servio.com',
    '+1234567890',
    '$2a$10$YQzHfWq8LvVE8T5R6qE.zOGKFJDQZBVvXXGJH6YvW9cVQ8zR7F2xm',  -- BCrypt hash of 'admin123'
    'ADMIN',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (email) DO NOTHING;

-- Create index on role column for better query performance
CREATE INDEX idx_users_role ON users(role);

-- Add comment to the column
COMMENT ON COLUMN users.role IS 'User role: CUSTOMER (default), ADMIN, or STAFF';
