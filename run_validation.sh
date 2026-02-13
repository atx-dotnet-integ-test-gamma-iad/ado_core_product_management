#!/bin/bash

# PostgreSQL Migration Validation Quick Start Script
# This script helps set up and validate the PostgreSQL migration

set -e

echo "=========================================="
echo "PostgreSQL Migration Validation"
echo "=========================================="
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed or not in PATH"
    echo "Please install PostgreSQL 12 or later and try again"
    exit 1
fi

echo "✅ PostgreSQL is installed"
echo ""

# Get PostgreSQL credentials
echo "Enter PostgreSQL credentials (or press Enter for defaults):"
read -p "Host [localhost]: " PG_HOST
PG_HOST=${PG_HOST:-localhost}

read -p "Port [5432]: " PG_PORT
PG_PORT=${PG_PORT:-5432}

read -p "Username [postgres]: " PG_USER
PG_USER=${PG_USER:-postgres}

read -sp "Password [postgres]: " PG_PASSWORD
echo ""
PG_PASSWORD=${PG_PASSWORD:-postgres}

export PGPASSWORD=$PG_PASSWORD

echo ""
echo "=========================================="
echo "Step 1: Creating PostgreSQL Database"
echo "=========================================="
echo ""

# Check if database exists
if psql -h $PG_HOST -p $PG_PORT -U $PG_USER -lqt | cut -d \| -f 1 | grep -qw ProductManagement; then
    echo "⚠️  Database 'ProductManagement' already exists"
    read -p "Do you want to drop and recreate it? (yes/no): " RECREATE
    if [ "$RECREATE" = "yes" ]; then
        psql -h $PG_HOST -p $PG_PORT -U $PG_USER -c "DROP DATABASE ProductManagement;"
        echo "✅ Dropped existing database"
    else
        echo "ℹ️  Using existing database"
    fi
fi

# Create database if it doesn't exist
if ! psql -h $PG_HOST -p $PG_PORT -U $PG_USER -lqt | cut -d \| -f 1 | grep -qw ProductManagement; then
    psql -h $PG_HOST -p $PG_PORT -U $PG_USER -c "CREATE DATABASE ProductManagement;"
    echo "✅ Created database 'ProductManagement'"
fi

echo ""
echo "=========================================="
echo "Step 2: Setting up Database Schema"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_SCRIPT="$SCRIPT_DIR/Database/Scripts/01_PostgreSQL_Setup.sql"

if [ ! -f "$SQL_SCRIPT" ]; then
    echo "❌ Setup script not found at: $SQL_SCRIPT"
    exit 1
fi

psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d ProductManagement -f "$SQL_SCRIPT"
echo "✅ Database schema created successfully"

echo ""
echo "=========================================="
echo "Step 3: Updating Connection String"
echo "=========================================="
echo ""

# Update appsettings.json with the connection details
cat > appsettings.json << EOF
{
  "ConnectionStrings": {
    "DevConnection": "Host=$PG_HOST;Database=ProductManagement;Username=$PG_USER;Password=$PG_PASSWORD;Port=$PG_PORT",
    "ProdConnection": "Host=$PG_HOST;Database=ProductManagement;Username=$PG_USER;Password=$PG_PASSWORD;Port=$PG_PORT"
  },
  "Environment": "Development"
}
EOF

echo "✅ Connection string updated in appsettings.json"

echo ""
echo "=========================================="
echo "Step 4: Building Application"
echo "=========================================="
echo ""

dotnet build
if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 5: Running Validation Tests"
echo "=========================================="
echo ""

dotnet run -- --validate

TEST_RESULT=$?

echo ""
echo "=========================================="
echo "Validation Complete"
echo "=========================================="
echo ""

if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ All validation tests passed!"
    echo ""
    echo "The PostgreSQL migration is complete and validated."
    echo "All database operations are working correctly."
else
    echo "❌ Some validation tests failed"
    echo ""
    echo "Please review the test output above for details."
    echo "Check the validation guide for troubleshooting: POSTGRESQL_VALIDATION_GUIDE.md"
fi

echo ""
echo "For more details, see:"
echo "  - Validation Guide: POSTGRESQL_VALIDATION_GUIDE.md"
echo "  - Validation Summary: ~/.aws/atx/custom/20260213_022941_c8cdef92/artifacts/validation_summary.md"
echo ""

exit $TEST_RESULT
