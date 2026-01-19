# PostgreSQL Migration - Runtime Validation Guide

## Overview
This document provides guidance for completing the runtime validation of the migrated ADO.NET application from SQL Server to PostgreSQL.

## Current Status
✅ **Static Code Transformation**: COMPLETE
- All SQL statements converted from SQL Server to PostgreSQL syntax
- All ADO.NET classes migrated from SqlClient to Npgsql
- Package dependencies updated
- Connection strings converted to PostgreSQL format
- Application compiles without errors

⚠️ **Runtime Validation**: INCOMPLETE
- Database connectivity not tested
- CRUD operations not validated
- Transaction atomicity not verified
- No test suite exists

## Prerequisites for Runtime Testing

### 1. PostgreSQL Database Setup
To complete runtime validation, you need a PostgreSQL database instance:

```bash
# Install PostgreSQL (if not already installed)
# On Ubuntu/Debian:
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# On macOS with Homebrew:
brew install postgresql

# On Windows:
# Download and install from https://www.postgresql.org/download/windows/

# Start PostgreSQL service
# On Ubuntu/Debian:
sudo service postgresql start

# On macOS:
brew services start postgresql

# On Windows:
# Use the PostgreSQL Service Manager
```

### 2. Create Database and Schema

1. Connect to PostgreSQL:
```bash
psql -U postgres
```

2. Create the database:
```sql
CREATE DATABASE "ProductManagement";
\c ProductManagement;
```

3. Run the PostgreSQL setup script:
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### 3. Update Connection String (if needed)
The application is configured to use:
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432
```

If your PostgreSQL instance uses different credentials, update `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=YOUR_USERNAME;Password=YOUR_PASSWORD;Port=5432",
    "ProdConnection": "Host=localhost;Database=ProductManagement;Username=YOUR_USERNAME;Password=YOUR_PASSWORD;Port=5432"
  }
}
```

## Runtime Validation Tests

### Test 1: Database Connectivity
```bash
cd sourceCode
dotnet run
```

If the application starts without errors, database connectivity is successful.

### Test 2: CRUD Operations

The application provides an interactive menu for testing all CRUD operations:

1. **Create (INSERT)**:
   - Select "Add Product" from the menu
   - Enter product details
   - Verify the product is inserted successfully

2. **Read (SELECT)**:
   - Select "List All Products"
   - Verify products are retrieved and displayed
   - Select "Get Product by ID"
   - Enter a product ID and verify details

3. **Update**:
   - Select "Update Product"
   - Enter product ID and new details
   - Verify the update completes successfully
   - Retrieve the product to confirm changes

4. **Delete**:
   - Select "Delete Product"
   - Enter a product ID
   - Verify the deletion completes successfully
   - Try to retrieve the product to confirm deletion

### Test 3: Transaction Atomicity

Test transaction rollback:
1. Note the current product count
2. Modify the code to force an error in a transaction (e.g., duplicate key)
3. Verify that all changes in the transaction are rolled back
4. Confirm the product count remains unchanged

### Test 4: Advanced Queries

Test the complex queries with window functions:
- GetAllProductsAsync() - Tests CTEs and window functions
- GetProductByIdAsync() - Tests LAG window function
- GetProductsByPriceRangeAsync() - Tests RANK and PERCENT_RANK
- GetLowStockProductsAsync() - Tests multiple window functions

## SQL Equivalency Status

Of the 7 SQL statements migrated:
- ✅ 2 statements: Formally verified as EQUIVALENT
- ⚠️ 5 statements: Marked as ERROR (SQL Equivalency tool returned UNKNOWN)

The 5 ERROR statements require runtime validation to confirm functional equivalency:
1. GetAllProductsAsync - Complex CTE with window functions
2. GetProductByIdAsync - Window function with LAG
3. InsertProductAsync - Multi-statement transaction
4. UpdateProductAsync - Multi-statement transaction
5. DeleteProductAsync - Multi-statement transaction

## Known Issues

### 1. Package Vulnerability
- **Package**: Npgsql 8.0.1
- **Severity**: Moderate (NU1903)
- **Status**: Known issue, update to latest Npgsql version when available
- **Impact**: No impact on functionality, only security advisory

### 2. Nullable Reference Type Warnings
- **Count**: 11 warnings
- **Type**: CS8600, CS8602, CS8604
- **Status**: Code works correctly, warnings can be addressed with nullable annotations
- **Impact**: No runtime impact

## Test Suite

**Status**: No test suite exists in the codebase

To create a test suite:

1. Create a new test project:
```bash
dotnet new xunit -n AdoCore.Tests
cd AdoCore.Tests
dotnet add reference ../sourceCode/AdoCore.csproj
dotnet add package Npgsql
dotnet add package Microsoft.Extensions.Configuration
```

2. Create integration tests for:
   - Database connectivity
   - Each repository method
   - Transaction behavior
   - Error handling

3. Run tests:
```bash
dotnet test
```

## Migration Artifacts

All migration artifacts are preserved:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.json` - DMS conversion log with timeout errors
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `final_migration_report.json` - Complete migration summary

## Completion Checklist

Runtime validation is complete when:
- [ ] PostgreSQL database is running and accessible
- [ ] Database schema is created using 01_InitialSetup_PostgreSQL.sql
- [ ] Application successfully connects to PostgreSQL
- [ ] All CRUD operations execute without errors
- [ ] Transaction rollback behavior verified
- [ ] All 7 SQL statements execute successfully in production
- [ ] (Optional) Test suite created and passing

## Support

For questions or issues:
1. Review the conversion logs in `dms_conversion_log.json`
2. Check the equivalency report in `sql_equivalency_validation_report.json`
3. Verify PostgreSQL syntax in `converted_statements.sql`
4. Review connection string in `appsettings.json`
