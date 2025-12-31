# PostgreSQL Migration Guide

## Overview

This application has been migrated from Microsoft SQL Server to PostgreSQL. This guide provides instructions for setting up and running the application with PostgreSQL.

## Migration Summary

- **Original Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL 12 or later
- **ADO.NET Provider**: Npgsql 8.0.5
- **Schema**: productmanagement_dbo
- **Total SQL Statements Converted**: 7
- **Build Status**: ✅ Successful (0 errors, 0 warnings)

## Prerequisites

1. **PostgreSQL Installation**:
   - PostgreSQL 12 or later (recommended: PostgreSQL 15+)
   - Download from: https://www.postgresql.org/download/

2. **.NET SDK**:
   - .NET 9.0 SDK or later
   - Verify: `dotnet --version`

3. **PostgreSQL Client** (optional but recommended):
   - pgAdmin 4 (https://www.pgadmin.org/)
   - DBeaver (https://dbeaver.io/)
   - psql command-line tool (included with PostgreSQL)

## Setup Instructions

### Step 1: Install PostgreSQL

#### Windows:
```bash
# Download installer from postgresql.org
# During installation:
# - Set postgres user password (remember this!)
# - Port: 5432 (default)
# - Locale: Default
```

#### macOS (using Homebrew):
```bash
brew install postgresql@15
brew services start postgresql@15
```

#### Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Step 2: Create Database and Schema

#### Option A: Using psql (Command Line)

```bash
# Connect as postgres superuser
psql -U postgres

# In psql prompt:
CREATE DATABASE productmanagement;
\c productmanagement
\i Database/Scripts/01_PostgreSQL_Setup.sql
\q
```

#### Option B: Using pgAdmin 4

1. Open pgAdmin 4
2. Connect to your PostgreSQL server (localhost)
3. Right-click "Databases" → "Create" → "Database"
4. Name: `productmanagement`
5. Right-click the new database → "Query Tool"
6. Open and execute `Database/Scripts/01_PostgreSQL_Setup.sql`

#### Option C: Using Docker

```bash
# Start PostgreSQL container
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=productmanagement \
  -p 5432:5432 \
  -d postgres:15

# Wait a few seconds for startup, then run setup script
docker exec -i postgres-adocore psql -U postgres -d productmanagement < Database/Scripts/01_PostgreSQL_Setup.sql
```

### Step 3: Create Application User (Recommended)

For better security, create a dedicated user for the application:

```sql
-- Connect as postgres superuser
psql -U postgres -d productmanagement

-- Create user
CREATE USER adocore_user WITH PASSWORD 'your_secure_password';

-- Grant permissions
GRANT CONNECT ON DATABASE productmanagement TO adocore_user;
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_user;

-- For future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo
GRANT ALL PRIVILEGES ON TABLES TO adocore_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo
GRANT ALL PRIVILEGES ON SEQUENCES TO adocore_user;
```

### Step 4: Configure Connection String

#### Option A: Using appsettings.json (Development)

Update `appsettings.json` with your PostgreSQL credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=your_password;Port=5432",
    "ProdConnection": "Host=your_prod_host;Database=productmanagement;Username=adocore_user;Password=your_secure_password;Port=5432"
  },
  "Environment": "Development"
}
```

#### Option B: Using Environment Variables (Recommended for Production)

Set environment variables instead of hardcoding credentials:

```bash
# Linux/macOS
export ConnectionStrings__DevConnection="Host=localhost;Database=productmanagement;Username=postgres;Password=your_password;Port=5432"

# Windows (PowerShell)
$env:ConnectionStrings__DevConnection="Host=localhost;Database=productmanagement;Username=postgres;Password=your_password;Port=5432"

# Windows (Command Prompt)
set ConnectionStrings__DevConnection=Host=localhost;Database=productmanagement;Username=postgres;Password=your_password;Port=5432
```

**Note**: When using environment variables, the application will automatically use them over appsettings.json values.

### Step 5: Build and Run

```bash
# Navigate to source directory
cd sourceCode

# Restore packages (if needed)
dotnet restore

# Build the application
dotnet build

# Run in interactive mode
dotnet run

# Or run with CLI commands
dotnet run -- list
dotnet run -- get 1
dotnet run -- add "New Product" 99.99 10 "Product description"
```

## Verification Steps

### 1. Verify Database Setup

```sql
-- Connect to database
psql -U postgres -d productmanagement

-- Check tables
\dt productmanagement_dbo.*

-- Verify data
SELECT COUNT(*) FROM productmanagement_dbo.products;
SELECT COUNT(*) FROM productmanagement_dbo.categories;
SELECT COUNT(*) FROM productmanagement_dbo.suppliers;

-- Expected results:
-- products: 18
-- categories: 20
-- suppliers: 8
```

### 2. Test Application Connectivity

```bash
# List all products (should return 18 products)
dotnet run -- list

# Get specific product
dotnet run -- get 1

# This confirms:
# ✓ Database connectivity
# ✓ Schema access
# ✓ Query execution
# ✓ Data retrieval
```

### 3. Test CRUD Operations

```bash
# Create a product
dotnet run -- add "Test Product" 29.99 5 "Test Description"

# Update the product (use the returned ID)
dotnet run -- update <product_id> "Updated Product" 39.99 10 "Updated Description"

# Update stock
dotnet run -- stock <product_id> 20

# Delete the product
dotnet run -- delete <product_id>
```

### 4. Verify Transaction Handling

The application uses ADO.NET transactions for Insert, Update, and Delete operations. To verify:

```bash
# These operations should either fully succeed or fully fail (atomicity)
dotnet run -- add "Transaction Test" 49.99 15 "Testing transactions"

# Check ProductHistory table for audit trail
psql -U postgres -d productmanagement -c "SELECT * FROM productmanagement_dbo.producthistory ORDER BY actiondate DESC LIMIT 10;"
```

## Schema Changes from SQL Server

The following changes were made during migration:

### 1. Naming Convention
- **SQL Server**: Mixed case (PascalCase) - `ProductId`, `ProductName`
- **PostgreSQL**: Lowercase - `productid`, `productname`

### 2. Schema Name
- **SQL Server**: `dbo` schema
- **PostgreSQL**: `productmanagement_dbo` schema (to avoid conflicts)

### 3. Data Types
- `NVARCHAR` → `VARCHAR` (PostgreSQL uses UTF-8 by default)
- `DATETIME` → `TIMESTAMP`
- `BIT` → `BOOLEAN`
- `IDENTITY(1,1)` → `SERIAL`

### 4. Functions
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `SCOPE_IDENTITY()` → `RETURNING productid`
- `SYSTEM_USER` → `current_user`

### 5. Transaction Handling
- **SQL Server**: SQL-level transactions (`BEGIN TRANSACTION`, `COMMIT`)
- **PostgreSQL**: ADO.NET transactions (`BeginTransactionAsync()`, `CommitAsync()`)

## SQL Statement Conversions

All 7 SQL statements were converted through AWS DMS and validated:

1. **GetAllProductsAsync**: Complex CTE with window functions (LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER)
2. **GetProductByIdAsync**: Simple SELECT with WHERE clause
3. **InsertProductAsync**: INSERT with RETURNING clause (replacing SCOPE_IDENTITY)
4. **UpdateProductAsync**: UPDATE with transaction support
5. **DeleteProductAsync**: DELETE with transaction support
6. **GetProductsByCategoryAsync**: JOIN query with window functions
7. **UpdateProductStockAsync**: UPDATE with transaction support

## Connection String Parameters

### Available Parameters:

```
Host=localhost              # PostgreSQL server hostname
Port=5432                  # PostgreSQL server port (default: 5432)
Database=productmanagement # Database name
Username=postgres          # PostgreSQL user
Password=your_password     # User password

# Optional parameters:
Timeout=30                 # Connection timeout in seconds
CommandTimeout=30          # Command timeout in seconds
Pooling=true              # Enable connection pooling
MinPoolSize=1             # Minimum pool size
MaxPoolSize=100           # Maximum pool size
SSL Mode=Prefer           # SSL mode (Disable, Allow, Prefer, Require)
Trust Server Certificate=true  # For development with self-signed certs
```

### Example Connection Strings:

```
# Development (local)
Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;Port=5432

# Production (with SSL)
Host=prod-db.example.com;Database=productmanagement;Username=adocore_user;Password=secure_pass;Port=5432;SSL Mode=Require

# Production (with connection pooling)
Host=prod-db.example.com;Database=productmanagement;Username=adocore_user;Password=secure_pass;Port=5432;Pooling=true;MinPoolSize=5;MaxPoolSize=50

# AWS RDS PostgreSQL
Host=mydb.abc123.us-east-1.rds.amazonaws.com;Database=productmanagement;Username=adocore_user;Password=secure_pass;Port=5432;SSL Mode=Require
```

## Troubleshooting

### Issue: "password authentication failed"
**Solution**: 
- Verify password in connection string
- Check PostgreSQL `pg_hba.conf` file for authentication method
- Ensure user has correct permissions

### Issue: "database does not exist"
**Solution**:
```bash
psql -U postgres
CREATE DATABASE productmanagement;
\q
```

### Issue: "schema does not exist"
**Solution**:
Run the setup script: `Database/Scripts/01_PostgreSQL_Setup.sql`

### Issue: "permission denied for schema"
**Solution**:
```sql
GRANT USAGE ON SCHEMA productmanagement_dbo TO your_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA productmanagement_dbo TO your_user;
```

### Issue: "relation does not exist"
**Solution**:
- Verify schema name in queries (should be `productmanagement_dbo.products`)
- Check if tables were created with lowercase names
- Verify search_path: `SHOW search_path;`

### Issue: Connection timeout
**Solution**:
- Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux)
- Check firewall settings
- Verify port 5432 is open and PostgreSQL is listening
- Check `postgresql.conf` for `listen_addresses`

## Performance Considerations

### 1. Connection Pooling
Connection pooling is enabled by default in Npgsql. Configure in connection string:
```
Pooling=true;MinPoolSize=5;MaxPoolSize=50
```

### 2. Indexes
All necessary indexes were created during schema setup:
- `ix_products_categoryid`
- `ix_products_supplierid`
- `ix_products_sku` (unique)
- `ix_producthistory_productid`
- `ix_producthistory_actiondate`

### 3. Query Performance
Monitor query performance:
```sql
-- Enable query timing
\timing on

-- Analyze query plans
EXPLAIN ANALYZE SELECT * FROM productmanagement_dbo.products WHERE categoryid = 1;
```

### 4. Vacuuming
PostgreSQL requires regular vacuuming for optimal performance:
```sql
-- Manual vacuum
VACUUM ANALYZE productmanagement_dbo.products;

-- Enable autovacuum (usually enabled by default)
ALTER TABLE productmanagement_dbo.products SET (autovacuum_enabled = true);
```

## Security Best Practices

### 1. Never Hardcode Credentials
- Use environment variables
- Use secrets management (AWS Secrets Manager, Azure Key Vault)
- Use configuration providers

### 2. Principle of Least Privilege
- Create dedicated database users for applications
- Grant only necessary permissions
- Use read-only users for reporting

### 3. Use SSL/TLS
```
SSL Mode=Require;Trust Server Certificate=false
```

### 4. Network Security
- Use VPC/private subnets for database servers
- Configure security groups/firewall rules
- Use connection pooling with appropriate limits

### 5. Audit Logging
Enable PostgreSQL audit logging:
```sql
-- In postgresql.conf
log_statement = 'all'
log_connections = true
log_disconnections = true
```

## Deployment Checklist

- [ ] PostgreSQL installed and running
- [ ] Database `productmanagement` created
- [ ] Schema setup script executed successfully
- [ ] Application user created with appropriate permissions
- [ ] Connection string configured (environment variables recommended)
- [ ] Application builds successfully (`dotnet build`)
- [ ] Application connects to database (`dotnet run -- list`)
- [ ] CRUD operations work correctly
- [ ] Transaction handling verified
- [ ] Connection pooling configured
- [ ] SSL/TLS enabled for production
- [ ] Backup strategy implemented
- [ ] Monitoring configured
- [ ] Documentation updated

## Additional Resources

- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Migration Reference**: See `sql_equivalency_validation_report.json` for detailed SQL statement conversions
- **DMS Conversion Log**: See `dms_conversion_log.json` for conversion details

## Support

For migration-related issues:
1. Check `final_migration_report.json` for statement-level details
2. Review `sql_equivalency_validation_report.json` for equivalency validation
3. Consult `converted_statements.sql` for SQL statement transformations
4. Review build log: `sourceCode/build.log`

## Migration Artifacts

The following files document the complete migration process:
- `extracted_statements.sql` - All original SQL Server statements
- `converted_statements.sql` - All converted PostgreSQL statements
- `dms_conversion_log.json` - DMS tool conversion log
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `final_migration_report.json` - Comprehensive migration report
- `re_integration_log.txt` - Code re-integration details
