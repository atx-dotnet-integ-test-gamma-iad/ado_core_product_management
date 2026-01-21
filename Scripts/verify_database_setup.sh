#!/bin/bash

# PostgreSQL Database Verification Script
# This script checks if PostgreSQL is configured correctly for the migrated application

echo "============================================"
echo "PostgreSQL Database Verification Script"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ProductManagement}"
DB_USER="${DB_USER:-postgres}"

echo "Connection Parameters:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Check 1: PostgreSQL is running
echo -n "1. Checking if PostgreSQL is running... "
if pg_isready -h "$DB_HOST" -p "$DB_PORT" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   PostgreSQL is not running or not accessible"
    exit 1
fi

# Check 2: Database exists
echo -n "2. Checking if database exists... "
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   Database '$DB_NAME' does not exist"
    echo "   Run: CREATE DATABASE ProductManagement;"
    exit 1
fi

# Check 3: Products table exists
echo -n "3. Checking if Products table exists... "
TABLE_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='products');")
if [ "$TABLE_EXISTS" = "t" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   Products table does not exist"
    echo "   Run: psql -U postgres -d ProductManagement -f Scripts/PostgreSQL_Setup.sql"
    exit 1
fi

# Check 4: Table has correct columns
echo -n "4. Checking table schema... "
REQUIRED_COLUMNS=("productid" "name" "description" "price" "stockquantity" "createddate" "modifieddate")
MISSING_COLUMNS=()

for col in "${REQUIRED_COLUMNS[@]}"; do
    COL_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name='products' AND column_name='$col');")
    if [ "$COL_EXISTS" != "t" ]; then
        MISSING_COLUMNS+=("$col")
    fi
done

if [ ${#MISSING_COLUMNS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   Missing columns: ${MISSING_COLUMNS[*]}"
    exit 1
fi

# Check 5: Sample data exists
echo -n "5. Checking for sample data... "
ROW_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM Products;")
if [ "$ROW_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($ROW_COUNT products found)"
else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   No sample data found. Consider running PostgreSQL_Setup.sql"
fi

# Check 6: Test basic query
echo -n "6. Testing basic SELECT query... "
TEST_QUERY=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1;" 2>&1)
if [ "$TEST_QUERY" = "1" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   Error executing query"
    exit 1
fi

# Check 7: Test window functions (critical for migrated queries)
echo -n "7. Testing window functions support... "
WINDOW_TEST=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT AVG(Price) OVER() FROM Products LIMIT 1;" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   Window functions not supported"
    exit 1
fi

# Check 8: Test CTE support
echo -n "8. Testing CTE (WITH clause) support... "
CTE_TEST=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "WITH test AS (SELECT 1 as val) SELECT val FROM test;" 2>&1)
if [ "$CTE_TEST" = "1" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   CTE not supported"
    exit 1
fi

# Summary
echo ""
echo "============================================"
echo -e "${GREEN}All checks passed!${NC}"
echo "============================================"
echo ""
echo "Your PostgreSQL database is ready for the migrated application."
echo ""
echo "Next steps:"
echo "  1. Build the application: dotnet build"
echo "  2. Run the application: dotnet run"
echo "  3. Test all database operations through the CLI menu"
echo ""
echo "Connection string for appsettings.json:"
echo "  Host=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;Username=$DB_USER;Password=YOUR_PASSWORD"
echo ""
