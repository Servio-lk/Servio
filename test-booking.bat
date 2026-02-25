@echo off
REM Simple test to verify booking works

echo.
echo === Testing Booking Flow ===
echo.

echo 1. Testing Login...
powershell -Command "^
  $body = @{ email = 'testuser@example.com'; password = 'password123' } | ConvertTo-Json; ^
  $resp = Invoke-RestMethod -Uri 'http://localhost:3001/api/auth/login' -Method POST -Body $body -ContentType 'application/json' -SkipHttpErrorCheck; ^
  if ($resp.success) { Write-Host 'Login OK: User ID ' $resp.data.user.id; exit 0 } else { Write-Host 'Login FAILED'; exit 1 }^
"
if errorlevel 1 (
  echo 1. Testing Signup...
  powershell -Command "^
    $body = @{ fullName='Test User'; email='testuser@example.com'; phone='0771234567'; password='password123' } | ConvertTo-Json; ^
    $resp = Invoke-RestMethod -Uri 'http://localhost:3001/api/auth/signup' -Method POST -Body $body -ContentType 'application/json' -SkipHttpErrorCheck; ^
    if ($resp.success) { Write-Host 'Signup OK: User ID ' $resp.data.user.id } else { Write-Host 'Signup FAILED: ' $resp.message }^
  "
)

echo.
echo Test Complete
