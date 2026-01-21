-- Quick Test Queries for Dashboard
-- Run these queries to verify your dashboard data

-- 1. Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. Count records in each table
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL
SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'service_records', COUNT(*) FROM service_records
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications;

-- 3. Get appointment statistics
SELECT 
    COUNT(*) as total_appointments,
    COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'CONFIRMED' THEN 1 END) as confirmed,
    COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled
FROM appointments;

-- 4. Get revenue statistics
SELECT 
    COUNT(*) as total_payments,
    SUM(amount) as total_revenue,
    AVG(amount) as average_payment,
    MIN(amount) as min_payment,
    MAX(amount) as max_payment
FROM payments
WHERE payment_status = 'COMPLETED';

-- 5. Get average rating
SELECT 
    COUNT(*) as total_reviews,
    AVG(rating) as average_rating,
    MIN(rating) as min_rating,
    MAX(rating) as max_rating
FROM reviews;

-- 6. Get recent appointments with user and vehicle details
SELECT 
    a.id,
    u.full_name as user_name,
    u.email,
    v.make || ' ' || v.model as vehicle,
    a.service_type,
    a.appointment_date,
    a.status,
    a.estimated_cost
FROM appointments a
JOIN users u ON a.user_id = u.id
LEFT JOIN vehicles v ON a.vehicle_id = v.id
ORDER BY a.created_at DESC
LIMIT 10;

-- 7. Get monthly revenue (last 6 months)
SELECT 
    TO_CHAR(payment_date, 'Mon YYYY') as month,
    SUM(amount) as revenue,
    COUNT(*) as payment_count
FROM payments
WHERE payment_status = 'COMPLETED'
    AND payment_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY TO_CHAR(payment_date, 'Mon YYYY'), DATE_TRUNC('month', payment_date)
ORDER BY DATE_TRUNC('month', payment_date) DESC;

-- 8. Get user activity summary
SELECT 
    u.id,
    u.full_name,
    u.email,
    COUNT(DISTINCT v.id) as vehicles_count,
    COUNT(DISTINCT a.id) as appointments_count,
    COUNT(DISTINCT p.id) as payments_count,
    COALESCE(SUM(p.amount), 0) as total_spent
FROM users u
LEFT JOIN vehicles v ON v.user_id = u.id
LEFT JOIN appointments a ON a.user_id = u.id
LEFT JOIN payments p ON p.user_id = u.id AND p.payment_status = 'COMPLETED'
GROUP BY u.id, u.full_name, u.email
ORDER BY total_spent DESC;

-- 9. Get service type popularity
SELECT 
    service_type,
    COUNT(*) as booking_count,
    AVG(estimated_cost) as avg_cost
FROM appointments
GROUP BY service_type
ORDER BY booking_count DESC;

-- 10. Get recent activities (mixed)
SELECT 
    'APPOINTMENT' as activity_type,
    u.full_name as user_name,
    'New appointment for ' || a.service_type as description,
    a.created_at as timestamp
FROM appointments a
JOIN users u ON a.user_id = u.id
UNION ALL
SELECT 
    'PAYMENT' as activity_type,
    u.full_name as user_name,
    'Payment of $' || p.amount || ' received' as description,
    p.created_at as timestamp
FROM payments p
JOIN users u ON p.user_id = u.id
ORDER BY timestamp DESC
LIMIT 20;
