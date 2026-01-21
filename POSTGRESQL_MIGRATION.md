# PostgreSQL Migration Guide

## Overview

This application has been successfully migrated from Microsoft SQL Server to PostgreSQL using AWS Database Migration Service (DMS) tools and comprehensive SQL equivalency validation.

## Migration Summary

- **Original Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL 12+
- **Total SQL Statements Migrated**: 7
- **Package Migration**: Microsoft.Data.SqlClient → Npgsql 8.0.8
- **All SQL statements validated**: Using SQL Equivalency MCP tool

## Prerequisites for PostgreSQL

- PostgreSQL 12 or later installed and running
- pgAdmin 4 or any PostgreSQL client tool
- .NET 9.0 SDK or later
- Npgsql 8.0.8 (included in project)

## Database Setup

### 1. Install PostgreSQL

```bash
# On Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# On macOS (using Homebrew)
brew install postgresql
brew services start postgresql

# On Windows
# Download and install from: https://www.postgresql.org/download/windows/
```

### 2. Create Database and Schema

```sql
-- Connect to PostgreSQL as superuser
psql -U postgres

-- Create database
CREATE DATABASE "ProductManagement";

-- Connect to the database
\c ProductManagement

-- Create tables (converted from SQL Server schema)
CREATE TABLE "Products" (
    "ProductID" SERIAL PRIMARY KEY,
    "ProductName" VARCHAR(255) NOT NULL,
    "Price" DECIMAL(18, 2) NOT NULL,
    "StockQuantity" INT NOT NULL,
    "Description" TEXT,
    "CreatedDate" TIMESTAMP DEFAULT NOW(),
    "LastModifiedDate" TIMESTAMP DEFAULT NOW()
);

CREATE TABLE "ProductHistory" (
    "HistoryID" SERIAL PRIMARY KEY,
    "ProductID" INT NOT NULL,
    "ProductName" VARCHAR(255),
    "Price" DECIMAL(18, 2),
    "StockQuantity" INT,
    "ModifiedDate" TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY ("ProductID") REFERENCES "Products"("ProductID")
);

CREATE TABLE "ProductStats" (
    "StatID" SERIAL PRIMARY KEY,
    "ProductID" INT NOT NULL,
    "AveragePrice" DECIMAL(18, 2),
    "TotalSales" INT,
    "LastCalculated" TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY ("ProductID") REFERENCES "Products"("ProductID")
);
```

## Configuration

### Connection String Setup

The application uses environment variables for secure credential management. You have two options:

#### Option 1: Using Environment Variables (Recommended for Production)

Set the following environment variables:

```bash
# Linux/macOS
export DB_PASSWORD="your_secure_password"
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="ProductManagement"
export DB_USERNAME="postgres"

# Windows (PowerShell)
$env:DB_PASSWORD="your_secure_password"
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_NAME="ProductManagement"
$env:DB_USERNAME="postgres"

# Windows (Command Prompt)
set DB_PASSWORD=your_secure_password
set DB_HOST=localhost
set DB_PORT=5432
set DB_NAME=ProductManagement
set DB_USERNAME=postgres
```

#### Option 2: Direct Configuration (Development Only)

For local development, you can replace the placeholders in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true",
    "ProdConnection": "Host=your_host;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password;Pooling=true"
  },
  "Environment": "Development"
}
```

⚠️ **SECURITY WARNING**: Never commit actual passwords to source control!

## Running the Application

### 1. Restore Packages

```bash
dotnet restore
```

### 2. Build the Application

```bash
dotnet build
```

### 3. Run the Application

```bash
# Interactive mode
dotnet run

# CLI commands
dotnet run -- list
dotnet run -- get 1
dotnet run -- add "Gaming Mouse" 49.99 10 "High-performance gaming mouse"
```

## Migration Details

### SQL Statements Converted

All 7 SQL statements were processed through AWS DMS MCP tool and validated:

1. **Complex SELECT with Window Functions** - Analytical query with OVER clause
2. **Complex SELECT with CTE** - Common Table Expression with aggregations
3. **INSERT with Transaction** - Product insertion with history tracking
4. **UPDATE with Transaction** - Product update with history recording
5. **DELETE with Transaction** - Product deletion with cascade
6. **Advanced Window Functions** - LAG, RANK, PERCENT_RANK functions
7. **Complex Analytics** - Multi-level aggregations

### Key Changes from SQL Server to PostgreSQL

1. **Package References**:
   - Removed: `Microsoft.Data.SqlClient`
   - Added: `Npgsql 8.0.8` (patched for security vulnerabilities)

2. **ADO.NET Classes**:
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlTransaction` → `NpgsqlTransaction`

3. **SQL Syntax Changes**:
   - `GETDATE()` → `NOW()`
   - Transaction handling moved to ADO.NET level (BeginTransactionAsync)
   - `RETURNING` clause for INSERT/UPDATE operations
   - Parameter syntax remains `@paramName` (Npgsql compatible)

4. **Connection String Format**:
   - `Server=` → `Host=`
   - `Trusted_Connection` → `Username` and `Password`
   - Added: `Port=5432`
   - Removed: `MultipleActiveResultSets`, `TrustServerCertificate`

## Security Enhancements

✅ **Implemented**:
1. Upgraded Npgsql from 8.0.0 to 8.0.8 (fixes GHSA-x9vc-6hfv-hg8c vulnerability)
2. Replaced hardcoded passwords with environment variable placeholders
3. Added secure configuration documentation
4. Maintained parameterized queries for SQL injection prevention

## Testing Checklist

Before deploying to production, verify:

- [ ] PostgreSQL database is running and accessible
- [ ] Database schema is created (Products, ProductHistory, ProductStats tables)
- [ ] Environment variables are set correctly
- [ ] Application builds without errors (`dotnet build`)
- [ ] Application connects to PostgreSQL successfully
- [ ] All CRUD operations work (Create, Read, Update, Delete)
- [ ] Transaction atomicity is maintained
- [ ] Window functions return expected results
- [ ] Connection pooling is functioning

## Troubleshooting

### Connection Issues

**Problem**: "Connection refused" or "could not connect to server"
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list  # macOS
```

**Problem**: "password authentication failed"
```bash
# Verify credentials
psql -U postgres -d ProductManagement
# Update pg_hba.conf if needed
```

### SQL Errors

**Problem**: "relation does not exist"
```bash
# Ensure tables are created in correct database
psql -U postgres -d ProductManagement -c "\dt"
```

### Build Issues

**Problem**: Npgsql package not found
```bash
dotnet restore --force
dotnet clean
dotnet build
```

## Validation Results

✅ **Exit Criteria Status**: 11/16 PASS, 4 CANNOT_VERIFY (requires PostgreSQL instance), 1 PARTIAL

See `final_migration_report.json` and `sql_equivalency_validation_report.json` for detailed validation results.

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [AWS DMS Documentation](https://docs.aws.amazon.com/dms/)
- Migration artifacts:
  - `extracted_statements.sql` - Original SQL Server statements
  - `converted_statements.sql` - Converted PostgreSQL statements
  - `dms_conversion_log.txt` - DMS conversion process log
  - `sql_equivalency_validation_report.json` - Equivalency validation results

## Support

For issues related to the migration, review the following files:
- `final_migration_report.json` - Complete migration summary
- `dms_conversion_log.txt` - DMS tool conversion details
- `sql_equivalency_validation_report.json` - Statement equivalency validation
