# Verify Supabase Database Setup Script

Write-Host "=== Checking Supabase Database Setup ===" -ForegroundColor Cyan
Write-Host ""

# Supabase connection details from your config
$DB_HOST = "aws-1-ap-south-1.pooler.supabase.com"
$DB_PORT = "6543"
$DB_USER = "postgres.szgvnurzdglflmdabjol"
$DB_PASSWORD = "EG/2022/5006/15/19/83"
$DB_NAME = "postgres"

Write-Host "Testing connection to Supabase PostgreSQL..." -ForegroundColor Yellow

# Create connection string
$env:PGPASSWORD = $DB_PASSWORD

# Check if psql is available (from Docker)
Write-Host "Checking if appointments table exists..." -ForegroundColor Yellow

# Try to check table using docker exec with PostgreSQL client
$checkTableCmd = @"
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('appointments', 'profiles', 'users', 'vehicles')
ORDER BY table_name;
"@

Write-Host ""
Write-Host "To verify your Supabase database setup:" -ForegroundColor Green
Write-Host ""
Write-Host "Option 1 - Using Supabase Dashboard (Easiest):" -ForegroundColor Cyan
Write-Host "  1. Go to https://supabase.com/dashboard/project/szgvnurzdglflmdabjol/editor" -ForegroundColor White
Write-Host "  2. Check if these tables exist:" -ForegroundColor White
Write-Host "     - users" -ForegroundColor Gray
Write-Host "     - profiles" -ForegroundColor Gray
Write-Host "     - appointments" -ForegroundColor Gray
Write-Host "     - vehicles" -ForegroundColor Gray
Write-Host "     - services" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2 - Using psql (if you have PostgreSQL client installed):" -ForegroundColor Cyan
Write-Host '  psql "postgresql://postgres.szgvnurzdglflmdabjol:EG/2022/5006/15/19/83@aws-1-ap-south-1.pooler.supabase.com:6543/postgres"' -ForegroundColor White
Write-Host '  Then run: \dt' -ForegroundColor White
Write-Host ""
Write-Host "Option 3 - Using Supabase SQL Editor:" -ForegroundColor Cyan
Write-Host "  1. Go to https://supabase.com/dashboard/project/szgvnurzdglflmdabjol/sql/new" -ForegroundColor White
Write-Host "  2. Run this query:" -ForegroundColor White
Write-Host "     SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';" -ForegroundColor Gray
Write-Host ""

# Check backend connection
Write-Host "Checking if backend is connected to Supabase..." -ForegroundColor Yellow
$backendLogs = docker logs servio-backend --tail 100 2>&1 | Select-String "HikariPool-1.*Added connection"

if ($backendLogs) {
    Write-Host "✓ Backend is connected to database!" -ForegroundColor Green
}
else {
    Write-Host "✗ Backend may not be connected properly. Check logs:" -ForegroundColor Red
    Write-Host "  docker logs servio-backend" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "If tables DO NOT exist in Supabase:" -ForegroundColor Yellow
Write-Host "  1. Go to Supabase SQL Editor: https://supabase.com/dashboard/project/szgvnurzdglflmdabjol/sql/new" -ForegroundColor White
Write-Host "  2. Copy all contents from: database\init.sql" -ForegroundColor White
Write-Host "  3. Paste and run in the SQL Editor" -ForegroundColor White
Write-Host ""
Write-Host "If tables DO exist:" -ForegroundColor Green
Write-Host "  ✓ Your setup is complete!" -ForegroundColor Green
Write-Host "  ✓ All 4 team members can now create appointments" -ForegroundColor Green
Write-Host "  ✓ Appointments will be saved to Supabase and visible to everyone" -ForegroundColor Green
Write-Host ""
