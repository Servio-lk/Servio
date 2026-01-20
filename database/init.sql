-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create vehicles table
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER,
    license_plate VARCHAR(50),
    vin VARCHAR(17),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_vehicles_user_id ON vehicles(user_id);

-- Create service_records table
CREATE TABLE IF NOT EXISTS service_records (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    service_type VARCHAR(100) NOT NULL,
    description TEXT,
    service_date DATE NOT NULL,
    mileage INTEGER,
    cost DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on vehicle_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_service_records_vehicle_id ON service_records(vehicle_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updating updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_records_updated_at BEFORE UPDATE ON service_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create appointments/bookings table
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
    service_type VARCHAR(100) NOT NULL,
    appointment_date TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED
    location VARCHAR(255),
    notes TEXT,
    estimated_cost DECIMAL(10, 2),
    actual_cost DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on appointments
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_vehicle_id ON appointments(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);

-- Create trigger for appointments
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    appointment_id INTEGER REFERENCES appointments(id) ON DELETE SET NULL,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- CREDIT_CARD, DEBIT_CARD, CASH, UPI, WALLET
    payment_status VARCHAR(50) NOT NULL DEFAULT 'PENDING', -- PENDING, COMPLETED, FAILED, REFUNDED
    transaction_id VARCHAR(255) UNIQUE,
    payment_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on payments
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_appointment_id ON payments(appointment_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(payment_status);

-- Create trigger for payments
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create reviews/ratings table
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_id INTEGER REFERENCES appointments(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on reviews
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_appointment_id ON reviews(appointment_id);

-- Create trigger for reviews
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- APPOINTMENT, PAYMENT, REMINDER, PROMOTIONAL
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- Insert sample data for dashboard testing
INSERT INTO users (full_name, email, phone, password_hash) VALUES
    ('John Doe', 'john@example.com', '1234567890', '$2a$10$dummyhash1'),
    ('Jane Smith', 'jane@example.com', '0987654321', '$2a$10$dummyhash2'),
    ('Bob Johnson', 'bob@example.com', '5555555555', '$2a$10$dummyhash3')
ON CONFLICT (email) DO NOTHING;

INSERT INTO vehicles (user_id, make, model, year, license_plate, vin) VALUES
    (1, 'Toyota', 'Camry', 2020, 'ABC123', '1HGBH41JXMN109186'),
    (1, 'Honda', 'Civic', 2021, 'XYZ789', '2HGBH41JXMN109187'),
    (2, 'Ford', 'Mustang', 2019, 'DEF456', '3HGBH41JXMN109188')
ON CONFLICT DO NOTHING;

INSERT INTO appointments (user_id, vehicle_id, service_type, appointment_date, status, location, estimated_cost, actual_cost) VALUES
    (1, 1, 'Oil Change', CURRENT_TIMESTAMP + INTERVAL '2 days', 'CONFIRMED', 'Service Center A', 50.00, NULL),
    (1, 2, 'Brake Inspection', CURRENT_TIMESTAMP + INTERVAL '5 days', 'PENDING', 'Service Center B', 100.00, NULL),
    (2, 3, 'Full Service', CURRENT_TIMESTAMP - INTERVAL '2 days', 'COMPLETED', 'Service Center A', 200.00, 195.00),
    (1, 1, 'Tire Rotation', CURRENT_TIMESTAMP - INTERVAL '10 days', 'COMPLETED', 'Service Center C', 75.00, 75.00),
    (2, 3, 'Engine Diagnostic', CURRENT_TIMESTAMP - INTERVAL '15 days', 'COMPLETED', 'Service Center B', 150.00, 145.00)
ON CONFLICT DO NOTHING;

INSERT INTO payments (appointment_id, user_id, amount, payment_method, payment_status, transaction_id, payment_date) VALUES
    (3, 2, 195.00, 'CREDIT_CARD', 'COMPLETED', 'TXN123456', CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (4, 1, 75.00, 'DEBIT_CARD', 'COMPLETED', 'TXN123457', CURRENT_TIMESTAMP - INTERVAL '10 days'),
    (5, 2, 145.00, 'UPI', 'COMPLETED', 'TXN123458', CURRENT_TIMESTAMP - INTERVAL '15 days')
ON CONFLICT DO NOTHING;

INSERT INTO reviews (user_id, appointment_id, rating, comment) VALUES
    (2, 3, 5, 'Excellent service! Very professional.'),
    (1, 4, 4, 'Good service, but took a bit longer than expected.'),
    (2, 5, 5, 'Highly recommend! Great experience.')
ON CONFLICT DO NOTHING;

INSERT INTO service_records (vehicle_id, service_type, description, service_date, mileage, cost) VALUES
    (1, 'Oil Change', 'Regular oil change with synthetic oil', CURRENT_DATE - INTERVAL '30 days', 15000, 50.00),
    (2, 'Brake Service', 'Replaced front brake pads', CURRENT_DATE - INTERVAL '60 days', 20000, 150.00),
    (3, 'Full Service', 'Complete vehicle inspection and service', CURRENT_DATE - INTERVAL '90 days', 25000, 300.00)
ON CONFLICT DO NOTHING;
