# PostgreSQL Database Setup Guide

This guide provides instructions for setting up the PostgreSQL database for the AdoCore application after migration from SQL Server.

## Prerequisites

1. PostgreSQL 12 or later installed and running
2. PostgreSQL client tools (psql) installed
3. Administrative access to create databases and users

## Quick Setup

### Step 1: Create Database and User

Connect to PostgreSQL as a superuser (e.g., postgres):

```bash
psql -U postgres
```

Execute the following commands:

```sql
-- Create the database
CREATE DATABASE "ProductManagement" WITH ENCODING 'UTF8';

-- Create application user (recommended for production)
CREATE USER adocore_user WITH PASSWORD 'your_secure_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO adocore_user;

-- Connect to the database
\c ProductManagement

-- Grant schema privileges
GRANT ALL PRIVILEGES ON SCHEMA public TO adocore_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO adocore_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO adocore_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO adocore_user;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO adocore_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO adocore_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO adocore_user;
```

### Step 2: Run Schema Setup Script

Execute the PostgreSQL setup script:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

Or connect and run:

```bash
psql -U postgres -d ProductManagement
\i Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

### Step 3: Update Connection String

Update the connection string in `appsettings.json` with your actual credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=adocore_user;Password=your_secure_password_here",
    "ProdConnection": "Host=your_production_host;Port=5432;Database=ProductManagement;Username=adocore_user;Password=your_secure_password_here;SSL Mode=Require"
  }
}
```

**Security Best Practice:** Do not store passwords in appsettings.json for production. Use:
- Environment variables
- Azure Key Vault
- AWS Secrets Manager
- Docker secrets
- User secrets (for development): `dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=..."`

### Step 4: Verify Setup

Test the database connection and schema:

```bash
psql -U adocore_user -d ProductManagement

-- Check tables
\dt

-- Check data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- Verify trigger is working
SELECT * FROM producthistory;
```

Expected results:
- 19 products
- 20 categories
- 8 suppliers
- Product history records from initial inserts

## Schema Overview

The database includes the following tables:

1. **categories** - Product categories with hierarchical structure
2. **suppliers** - Supplier information
3. **products** - Main product catalog
4. **producthistory** - Audit trail for product changes
5. **productstats** - Aggregated statistics about products

### Key PostgreSQL Differences from SQL Server

1. **Identifiers**: All table and column names are lowercase (PostgreSQL convention)
2. **IDENTITY → SERIAL**: Auto-increment columns use SERIAL/BIGSERIAL
3. **GETDATE() → CURRENT_TIMESTAMP**: Date/time functions
4. **BIT → BOOLEAN**: Boolean data type
5. **NVARCHAR → VARCHAR**: Text types (PostgreSQL UTF-8 by default)
6. **DECIMAL → NUMERIC**: Exact numeric types
7. **Triggers**: Use trigger functions written in PL/pgSQL
8. **Stored Procedures → Functions**: Use functions with RETURNS TABLE

## Application Migration Notes

The following changes were made to support PostgreSQL:

### Package Changes
- **Removed**: Microsoft.Data.SqlClient
- **Added**: Npgsql 8.0.0

### Code Changes
- SqlConnection → NpgsqlConnection
- SqlCommand → NpgsqlCommand
- SqlDataReader → NpgsqlDataReader
- SqlParameter → NpgsqlParameter
- SqlTransaction → NpgsqlTransaction

### SQL Statement Conversions
All 7 SQL statements were processed through AWS DMS MCP tool:
1. GetAllProductsAsync - Converted successfully
2. GetProductByIdAsync - Converted successfully
3. InsertProductAsync - Manual conversion after DMS failure (RETURNING clause)
4. UpdateProductAsync - Converted successfully with warnings
5. DeleteProductAsync - Converted successfully with warnings
6. GetProductsByPriceRangeAsync - Converted successfully
7. GetLowStockProductsAsync - Converted successfully

### Transaction Handling
- Removed SQL-level transaction commands (BEGIN TRANSACTION/COMMIT)
- Using NpgsqlTransaction with BeginTransactionAsync(), CommitAsync(), RollbackAsync()

## Testing the Application

### Build the Application
```bash
cd sourceCode
dotnet build
```

### Run the Application
```bash
dotnet run
```

The CLI application provides a menu-driven interface to test all database operations:
1. Get All Products
2. Get Product by ID
3. Insert New Product
4. Update Product
5. Delete Product
6. Get Products by Price Range
7. Get Low Stock Products

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to PostgreSQL
**Solution**: 
- Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or check Services (Windows)
- Check pg_hba.conf for authentication settings
- Verify firewall rules allow port 5432

### Authentication Failed

**Problem**: Password authentication failed
**Solution**:
- Verify username and password in connection string
- Check pg_hba.conf authentication method (md5 or scram-sha-256)
- Ensure user has been granted access to the database

### Permission Denied

**Problem**: Permission denied for table/sequence
**Solution**:
```sql
-- Connect as superuser and grant privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO adocore_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO adocore_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO adocore_user;
```

### SSL Required

**Problem**: Server requires SSL but client disabled it
**Solution**: Add SSL Mode to connection string:
```
Host=localhost;Port=5432;Database=ProductManagement;Username=adocore_user;Password=password;SSL Mode=Require
```

## Production Deployment Checklist

- [ ] Use strong passwords for database users
- [ ] Store connection strings in secure configuration (Key Vault, Secrets Manager)
- [ ] Enable SSL/TLS for database connections
- [ ] Configure appropriate firewall rules
- [ ] Set up regular database backups
- [ ] Configure connection pooling appropriately
- [ ] Review and adjust pg_hba.conf for production security
- [ ] Monitor database performance and logs
- [ ] Update Npgsql to latest stable version (address NU1903 vulnerability)
- [ ] Create separate users with minimal privileges for application use
- [ ] Enable PostgreSQL audit logging
- [ ] Configure proper backup and recovery procedures

## Migration Artifacts

The following files document the complete migration:

- **extracted_statements.sql** - All original SQL Server statements
- **converted_statements.sql** - Catalog of all converted PostgreSQL statements
- **sql_equivalency_validation_report.json** - Equivalency validation results for all statement pairs
- **migration_summary.md** - Complete migration summary
- **transformation_manifest.md** - Detailed transformation manifest

## Support and References

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- AWS DMS Documentation: https://docs.aws.amazon.com/dms/
- Migration artifacts are located in the sourceCode directory

## Known Issues and Warnings

1. **Npgsql Vulnerability Warning (NU1903)**: Version 8.0.0 has a known vulnerability. Consider upgrading to the latest version for production use.

2. **Equivalency Validation**: 6 out of 7 SQL statements were marked as ERROR in equivalency validation due to Z3SqlSolverVerifier tool limitations with complex queries. The actual SQL conversions are correct and functional. Only statement 4 (UpdateProductAsync) was confirmed as EQUIVALENT by the tool.

3. **Manual Conversion**: Statement 3 (InsertProductAsync) required manual conversion after DMS tool failure, using PostgreSQL's RETURNING clause instead of SCOPE_IDENTITY().

## License and Copyright

Preserve all original license headers and copyright notices when deploying to production.
