# PostgreSQL Migration Deployment Guide

## Overview
This document provides instructions for deploying and testing the migrated ADO.NET application with PostgreSQL database.

## Prerequisites
1. PostgreSQL 12 or higher installed and running
2. .NET 9.0 SDK installed
3. Database client tool (psql, pgAdmin, or similar)

## Database Setup

### Step 1: Create Database
```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Create the database
CREATE DATABASE "ProductManagement";

# Connect to the new database
\c ProductManagement
```

### Step 2: Execute Schema Script
Run the PostgreSQL schema setup script:
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Or from within psql:
```sql
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### Step 3: Verify Database Setup
```sql
-- Check tables
\dt

-- Verify data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- Expected results:
-- products: 18 rows
-- categories: 20 rows
-- suppliers: 8 rows
```

## Application Configuration

### Connection String
The application is pre-configured with the following connection string in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432",
    "ProdConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432"
  }
}
```

**Security Note**: Update the connection string with appropriate credentials before deploying to production.

### Update Connection String (if needed)
Edit `appsettings.json` and modify the connection parameters:
- **Host**: PostgreSQL server hostname/IP
- **Database**: Database name (ProductManagement)
- **Username**: PostgreSQL username
- **Password**: PostgreSQL password
- **Port**: PostgreSQL port (default: 5432)

## Building the Application

```bash
# Navigate to the source code directory
cd sourceCode

# Restore dependencies
dotnet restore

# Build the application
dotnet build

# Expected output: "Build succeeded. 0 Warning(s) 0 Error(s)"
```

## Running the Application

```bash
# Run the application
dotnet run
```

## Testing Database Operations

### Manual Testing Checklist

#### 1. Connection Test
- Run the application
- Verify it starts without connection errors
- Check logs for successful database connection

#### 2. Read Operations (Criterion 13)
Test the following operations:
```csharp
// GetAllProductsAsync
// Expected: Returns list of 18 products with window function calculations

// GetProductByIdAsync
// Expected: Returns specific product details
```

#### 3. Insert Operations (Criterion 13)
```csharp
// InsertProductAsync
// Expected: Successfully inserts new product and returns new ProductId
// Verification: Check product_history table for INSERT record
```

#### 4. Update Operations (Criterion 13)
```csharp
// UpdateProductAsync
// Expected: Successfully updates product
// Verification: Check product_history table for UPDATE record
```

#### 5. Delete Operations (Criterion 13)
```csharp
// DeleteProductAsync
// Expected: Successfully deletes product
// Verification: Product removed from products table, history preserved
```

#### 6. Transaction Atomicity (Criterion 14)
Test transaction rollback scenarios:

**Test A: Successful Transaction**
```sql
-- Start monitoring
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM product_history;

-- Run Insert/Update/Delete operation
-- Verify counts increased correctly
```

**Test B: Failed Transaction Rollback**
```sql
-- Simulate error condition in application
-- Verify transaction rolled back (no data changes)
-- Check product_history table has no partial records
```

**Test C: Concurrent Operations**
- Run multiple operations simultaneously
- Verify data integrity maintained
- Check no deadlocks or race conditions

### SQL Verification Queries

```sql
-- Verify Products Table
SELECT product_id, name, price, stock_quantity 
FROM products 
ORDER BY product_id 
LIMIT 5;

-- Verify History Tracking
SELECT product_id, action, old_price, new_price, action_date
FROM product_history
ORDER BY action_date DESC
LIMIT 10;

-- Verify Stats Updates
SELECT * FROM product_stats WHERE stat_id = 1;

-- Test Window Functions (used in application)
WITH ProductStats AS (
    SELECT 
        product_id,
        AVG(price) OVER() as avg_price,
        COUNT(*) OVER() as total_products
    FROM products
)
SELECT * FROM ProductStats LIMIT 5;

-- Verify Triggers Working
-- Insert test product and check history
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Test Product', 'Test Description', 99.99, 10);

SELECT * FROM product_history WHERE action = 'INSERT' ORDER BY action_date DESC LIMIT 1;
```

## Validation Criteria Status

### Code-Level Criteria (PASSED)
✅ Criterion 1: SQL Server packages replaced with PostgreSQL equivalents
✅ Criterion 2: ADO.NET classes replaced with Npgsql
✅ Criterion 3: All SQL statements processed through DMS MCP tool
✅ Criterion 4: Comprehensive SQL statement catalog exists
✅ Criterion 5: All SQL pairs validated through SQL Equivalency tool
✅ Criterion 6: Equivalency validation report generated
✅ Criterion 7: No agent judgment used for equivalency
✅ Criterion 8: DMS failures documented
✅ Criterion 9: Connection strings updated to PostgreSQL format
✅ Criterion 10: Transaction handling updated
✅ Criterion 11: Application compiles without errors

### Runtime-Level Criteria (REQUIRE TESTING)
❌ Criterion 12: **Application successfully connects to PostgreSQL database**
   - **Action**: Run application after database setup
   - **Verification**: No connection errors, application starts successfully

❌ Criterion 13: **All database operations execute successfully**
   - **Action**: Execute all CRUD operations (GetAll, GetById, Insert, Update, Delete)
   - **Verification**: All operations complete without errors, data persists correctly

❌ Criterion 14: **Transaction blocks maintain atomicity**
   - **Action**: Test transaction commit and rollback scenarios
   - **Verification**: Failed transactions rollback completely, concurrent operations maintain integrity

❌ Criterion 15: **Application passes all tests**
   - **Status**: No unit test suite exists in current project
   - **Action**: Create test project or execute manual testing checklist above

## Troubleshooting

### Connection Issues
```
Error: "could not connect to server"
Solution: 
- Verify PostgreSQL is running: sudo service postgresql status
- Check connection string parameters
- Verify firewall rules allow connection to port 5432
```

### Authentication Issues
```
Error: "password authentication failed"
Solution:
- Verify username and password in appsettings.json
- Check PostgreSQL pg_hba.conf for authentication method
- Grant appropriate privileges to user
```

### Schema Issues
```
Error: "relation does not exist"
Solution:
- Verify database setup script executed successfully
- Check table names are lowercase (PostgreSQL convention)
- Confirm connected to correct database
```

## Migration Artifacts

The following artifacts document the complete migration process:

1. **extracted_statements.sql** - All original SQL Server statements
2. **converted_statements.sql** - All converted PostgreSQL statements
3. **dms_conversion_log.json** - DMS tool conversion log with manual conversions
4. **sql_equivalency_validation_report.json** - Complete equivalency validation results
5. **final_migration_report.json** - Comprehensive migration summary

## Next Steps

1. ✅ Setup PostgreSQL database using provided script
2. ✅ Configure connection string in appsettings.json
3. ✅ Build application (dotnet build)
4. ✅ Run application (dotnet run)
5. ✅ Test connection (Criterion 12)
6. ✅ Test all CRUD operations (Criterion 13)
7. ✅ Test transaction scenarios (Criterion 14)
8. ✅ Document test results
9. ⚠️ Consider creating automated test suite (Criterion 15)

## Success Criteria

The migration is considered successful when:
- ✅ Application builds without errors
- ✅ Application connects to PostgreSQL database
- ✅ All database operations execute correctly
- ✅ Transactions maintain ACID properties
- ✅ Data integrity preserved across all operations
- ✅ No SQL syntax errors in production queries

---

**Migration Date**: 2026-02-16
**Source Database**: Microsoft SQL Server
**Target Database**: PostgreSQL 12+
**Application Framework**: .NET 9.0 with Npgsql 8.0.7
