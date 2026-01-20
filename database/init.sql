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

-- Service Categories Table
CREATE TABLE IF NOT EXISTS service_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Services Table
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_services_category_id ON services(category_id);
CREATE INDEX IF NOT EXISTS idx_services_featured ON services(is_featured);

-- Service Options Table
CREATE TABLE IF NOT EXISTS service_options (
    id SERIAL PRIMARY KEY,
    service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price_adjustment DECIMAL(10, 2) DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_service_options_service ON service_options(service_id);

-- Service Providers Table
CREATE TABLE IF NOT EXISTS service_providers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    rating DECIMAL(3, 2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Offers Table
CREATE TABLE IF NOT EXISTS offers (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    subtitle VARCHAR(200),
    description TEXT,
    discount_type VARCHAR(20) CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10, 2),
    image_url VARCHAR(500),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add triggers for new tables
CREATE TRIGGER update_service_categories_updated_at BEFORE UPDATE ON service_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_options_updated_at BEFORE UPDATE ON service_options
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_providers_updated_at BEFORE UPDATE ON service_providers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert seed data for service categories
INSERT INTO service_categories (name, description, display_order) VALUES
('Periodic Maintenance', 'Regular vehicle maintenance services', 1),
('Nano Coating', 'Advanced paint protection services', 2),
('Detailing', 'Professional vehicle detailing services', 3),
('Tyre & Battery', 'Tyre and battery related services', 4),
('Diagnostics', 'Vehicle diagnostics and inspection', 5);

-- Insert seed data for services
INSERT INTO services (category_id, name, description, base_price, price_range, duration_minutes, is_featured) VALUES
-- Periodic Maintenance
(1, 'Full Service (Free Pickup & Drop)', 'Comprehensive vehicle service including engine oil change, filter replacements, and multi-point inspection', 8500.00, 'LKR 8,500 - 15,000', 180, TRUE),
(1, 'Lube Service (Free Pickup & Drop)', 'Engine oil and filter change service', 4500.00, 'LKR 4,500 - 8,000', 60, TRUE),
(1, 'Hybrid Battery Inspection', 'Specialized inspection and diagnostics for hybrid vehicle batteries', 3500.00, 'LKR 3,500', 90, FALSE),

-- Nano Coating
(2, 'Graphene Nano Coating', 'Advanced graphene-based protective coating', 45000.00, 'LKR 45,000 - 85,000', 360, TRUE),
(2, 'Ceramic Coating (9H)', 'Premium ceramic coating with 9H hardness', 35000.00, 'LKR 35,000 - 65,000', 300, FALSE),
(2, 'Glass Coating', 'Specialized glass protection coating', 12000.00, 'LKR 12,000 - 18,000', 120, FALSE),

-- Detailing
(3, 'Interior Detailing', 'Deep cleaning and restoration of vehicle interior', 8500.00, 'LKR 8,500 - 15,000', 180, FALSE),
(3, 'Exterior Detailing', 'Professional exterior cleaning and polishing', 6500.00, 'LKR 6,500 - 12,000', 150, FALSE),
(3, 'Full Detailing Package', 'Complete interior and exterior detailing', 15000.00, 'LKR 15,000 - 25,000', 300, TRUE),
(3, 'Engine Bay Cleaning', 'Professional engine compartment cleaning', 3500.00, 'LKR 3,500 - 5,000', 90, FALSE),

-- Tyre & Battery
(4, 'Wheel Alignment', 'Professional wheel alignment service', 2500.00, 'LKR 2,500 - 4,000', 60, FALSE),
(4, 'Wheel Balancing', 'Precise wheel balancing', 1500.00, 'LKR 1,500 - 2,500', 45, FALSE),
(4, 'Tyre Rotation', 'Regular tyre rotation service', 1000.00, 'LKR 1,000', 30, FALSE),
(4, 'Battery Health Check', 'Comprehensive battery diagnostics', 500.00, 'Free - LKR 500', 15, TRUE),

-- Diagnostics
(5, 'Computer Diagnostics', 'Full vehicle computer system diagnostics', 2500.00, 'LKR 2,500 - 5,000', 45, FALSE),
(5, 'Pre-Purchase Inspection', 'Comprehensive vehicle inspection before purchase', 7500.00, 'LKR 7,500 - 12,000', 120, TRUE),
(5, 'Emission Testing', 'Vehicle emission testing and certification', 1500.00, 'LKR 1,500', 30, FALSE);

-- Insert service options for Lube Service
INSERT INTO service_options (service_id, name, description, price_adjustment, is_default, display_order) VALUES
(2, 'Mineral Oil', 'Standard mineral-based engine oil', 0.00, TRUE, 1),
(2, 'Semi-Synthetic Oil', 'Semi-synthetic engine oil for better performance', 1500.00, FALSE, 2),
(2, 'Full Synthetic Oil', 'Premium full synthetic engine oil', 3500.00, FALSE, 3);

-- Insert service providers
INSERT INTO service_providers (name, address, city, phone, rating) VALUES
('Auto Miraj Battaramulla', '1043 Pannipitiya Rd, Pelawatta', 'Battaramulla', '+94 77 123 4567', 4.80),
('Auto Miraj Nugegoda', '123 High Level Rd', 'Nugegoda', '+94 77 234 5678', 4.75),
('Auto Miraj Rajagiriya', '456 Kotte Rd', 'Rajagiriya', '+94 77 345 6789', 4.85);

-- Insert offers
INSERT INTO offers (title, subtitle, description, discount_type, discount_value, valid_until) VALUES
('Get 20% off', 'on your first full service', 'New customer offer - save 20% on comprehensive full service package', 'percentage', 20.00, CURRENT_TIMESTAMP + INTERVAL '30 days'),
('Free battery check', 'with any service', 'Complimentary battery health check with any paid service', 'fixed', 500.00, CURRENT_TIMESTAMP + INTERVAL '60 days'),
('Detailing Special', 'Full detailing at 15% off', 'Limited time offer on complete interior and exterior detailing', 'percentage', 15.00, CURRENT_TIMESTAMP + INTERVAL '45 days');