# Servio Dashboard Setup and Test Script
# Run this script to verify your dashboard backend is working

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Servio Dashboard Setup Verification" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "1. Checking Docker status..." -ForegroundColor Yellow
docker --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker is not installed or not running" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker is running" -ForegroundColor Green
Write-Host ""

# Check if containers are running
Write-Host "2. Checking Docker containers..." -ForegroundColor Yellow
docker-compose ps
Write-Host ""

# Wait for services to be ready
Write-Host "3. Waiting for services to start (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host "✓ Services should be ready" -ForegroundColor Green
Write-Host ""

# Test database connection
Write-Host "4. Testing database connection..." -ForegroundColor Yellow
$dbTest = docker exec servio-postgres psql -U servio_user -d servio_db -c "\dt" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database is accessible" -ForegroundColor Green
    Write-Host $dbTest
} else {
    Write-Host "✗ Database connection failed" -ForegroundColor Red
}
Write-Host ""

# Count records in tables
Write-Host "5. Checking database tables..." -ForegroundColor Yellow
$query = @"
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
SELECT 'notifications', COUNT(*) FROM notifications;
"@

docker exec servio-postgres psql -U servio_user -d servio_db -c $query
Write-Host ""

# Test backend API
Write-Host "6. Testing Backend API..." -ForegroundColor Yellow
Write-Host "   Testing: GET /api/dashboard/stats" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/dashboard/stats" -Method Get -TimeoutSec 10
    Write-Host "✓ Dashboard stats endpoint working" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "✗ Backend API not ready or not responding" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "7. Testing Appointments API..." -ForegroundColor Yellow
Write-Host "   Testing: GET /api/appointments/recent" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/appointments/recent" -Method Get -TimeoutSec 10
    Write-Host "✓ Appointments endpoint working" -ForegroundColor Green
    Write-Host "   Found $($response.data.Count) recent appointments" -ForegroundColor Green
} catch {
    Write-Host "✗ Appointments API not ready" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Setup Verification Complete!" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Quick Access URLs:" -ForegroundColor Yellow
Write-Host "  Backend API:  http://localhost:8080" -ForegroundColor White
Write-Host "  Frontend:     http://localhost" -ForegroundColor White
Write-Host "  Database:     localhost:5433" -ForegroundColor White
Write-Host ""
Write-Host "API Endpoints to Try:" -ForegroundColor Yellow
Write-Host "  GET  http://localhost:8080/api/dashboard/stats" -ForegroundColor White
Write-Host "  GET  http://localhost:8080/api/dashboard/revenue-chart?months=6" -ForegroundColor White
Write-Host "  GET  http://localhost:8080/api/dashboard/recent-activities" -ForegroundColor White
Write-Host "  GET  http://localhost:8080/api/appointments" -ForegroundColor White
Write-Host "  GET  http://localhost:8080/api/appointments/status/PENDING" -ForegroundColor White
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  API Reference:     backend/DASHBOARD_API.md" -ForegroundColor White
Write-Host "  Implementation:    DASHBOARD_IMPLEMENTATION.md" -ForegroundColor White
Write-Host "  Database Guide:    database/DASHBOARD_SETUP.md" -ForegroundColor White
Write-Host ""
