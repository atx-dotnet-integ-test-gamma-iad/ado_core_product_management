# PostgreSQL Database Verification Script (PowerShell)
# This script checks if PostgreSQL is configured correctly for the migrated application

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PostgreSQL Database Verification Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Default connection parameters
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "ProductManagement" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "postgres" }

Write-Host "Connection Parameters:"
Write-Host "  Host: $DB_HOST"
Write-Host "  Port: $DB_PORT"
Write-Host "  Database: $DB_NAME"
Write-Host "  User: $DB_USER"
Write-Host ""

$allPassed = $true

# Check 1: PostgreSQL is running
Write-Host -NoNewline "1. Checking if PostgreSQL is running... "
try {
    $result = & pg_isready -h $DB_HOST -p $DB_PORT 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ PASS" -ForegroundColor Green
    } else {
        Write-Host "✗ FAIL" -ForegroundColor Red
        Write-Host "   PostgreSQL is not running or not accessible" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "✗ FAIL" -ForegroundColor Red
    Write-Host "   pg_isready command not found. Is PostgreSQL installed?" -ForegroundColor Red
    $allPassed = $false
}

# Check 2: Database exists
Write-Host -NoNewline "2. Checking if database exists... "
$dbExists = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt 2>&1 | Select-String -Pattern "\s+$DB_NAME\s+"
if ($dbExists) {
    Write-Host "✓ PASS" -ForegroundColor Green
} else {
    Write-Host "✗ FAIL" -ForegroundColor Red
    Write-Host "   Database '$DB_NAME' does not exist" -ForegroundColor Red
    Write-Host "   Run: CREATE DATABASE ProductManagement;" -ForegroundColor Yellow
    $allPassed = $false
}

# Check 3: Products table exists
Write-Host -NoNewline "3. Checking if Products table exists... "
$tableExists = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='products');" 2>&1
if ($tableExists -eq "t") {
    Write-Host "✓ PASS" -ForegroundColor Green
} else {
    Write-Host "✗ FAIL" -ForegroundColor Red
    Write-Host "   Products table does not exist" -ForegroundColor Red
    Write-Host "   Run: psql -U postgres -d ProductManagement -f Scripts\PostgreSQL_Setup.sql" -ForegroundColor Yellow
    $allPassed = $false
}

# Check 4: Table has correct columns
Write-Host -NoNewline "4. Checking table schema... "
$requiredColumns = @("productid", "name", "description", "price", "stockquantity", "createddate", "modifieddate")
$missingColumns = @()

foreach ($col in $requiredColumns) {
    $colExists = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name='products' AND column_name='$col');" 2>&1
    if ($colExists -ne "t") {
        $missingColumns += $col
    }
}

if ($missingColumns.Count -eq 0) {
    Write-Host "✓ PASS" -ForegroundColor Green
} else {
    Write-Host "✗ FAIL" -ForegroundColor Red
    Write-Host "   Missing columns: $($missingColumns -join ', ')" -ForegroundColor Red
    $allPassed = $false
}

# Check 5: Sample data exists
Write-Host -NoNewline "5. Checking for sample data... "
$rowCount = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM Products;" 2>&1
if ([int]$rowCount -gt 0) {
    Write-Host "✓ PASS ($rowCount products found)" -ForegroundColor Green
} else {
    Write-Host "⚠ WARNING" -ForegroundColor Yellow
    Write-Host "   No sample data found. Consider running PostgreSQL_Setup.sql" -ForegroundColor Yellow
}

# Check 6: Test basic query
Write-Host -NoNewline "6. Testing basic SELECT query... "
$testQuery = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT 1;" 2>&1
if ($testQuery -eq "1") {
    Write-Host "✓ PASS" -ForegroundColor Green
} else {
    Write-Host "✗ FAIL" -ForegroundColor Red
    Write-Host "   Error executing query" -ForegroundColor Red
    $allPassed = $false
}

# Check 7: Test window functions
Write-Host -NoNewline "7. Testing window functions support... "
$windowTest = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT AVG(Price) OVER() FROM Products LIMIT 1;" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ PASS" -ForegroundColor Green
} else {
    Write-Host "✗ FAIL" -ForegroundColor Red
    Write-Host "   Window functions not supported" -ForegroundColor Red
    $allPassed = $false
}

# Check 8: Test CTE support
Write-Host -NoNewline "8. Testing CTE (WITH clause) support... "
$cteTest = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "WITH test AS (SELECT 1 as val) SELECT val FROM test;" 2>&1
if ($cteTest -eq "1") {
    Write-Host "✓ PASS" -ForegroundColor Green
} else {
    Write-Host "✗ FAIL" -ForegroundColor Red
    Write-Host "   CTE not supported" -ForegroundColor Red
    $allPassed = $false
}

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "All checks passed!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your PostgreSQL database is ready for the migrated application." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Build the application: dotnet build"
    Write-Host "  2. Run the application: dotnet run"
    Write-Host "  3. Test all database operations through the CLI menu"
} else {
    Write-Host "Some checks failed!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please address the failed checks before running the application." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Connection string for appsettings.json:"
Write-Host "  Host=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;Username=$DB_USER;Password=YOUR_PASSWORD" -ForegroundColor Cyan
Write-Host ""
