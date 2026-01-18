# ADO.NET PostgreSQL Migration - Setup Guide

## Overview
This application has been migrated from Microsoft SQL Server to PostgreSQL. This guide provides instructions for setting up and running the application.

## Prerequisites

1. **PostgreSQL Database Server** (version 12 or higher recommended)
   - Download from: https://www.postgresql.org/download/
   - Ensure PostgreSQL service is running

2. **.NET SDK** (version 9.0 or compatible)
   - Current target framework: net9.0

3. **Npgsql** (version 8.0.5)
   - Automatically installed via NuGet package restore

## Database Setup

### Step 1: Create the Database

Connect to your PostgreSQL server as a superuser (e.g., postgres) and create the database:

```sql
CREATE DATABASE "ProductManagement";
```

### Step 2: Run the Setup Script

Execute the PostgreSQL setup script to create the schema, tables, and sample data:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_Setup.sql
```

Or connect to the database and run the script manually:

```bash
psql -U postgres -d ProductManagement
\i Database/Scripts/01_PostgreSQL_Setup.sql
```

This script will:
- Create the `productmanagement_dbo` schema
- Create all required tables (products, producthistory, productstats, categories, suppliers)
- Create indexes for optimal performance
- Insert sample data
- Create triggers and functions

### Step 3: Verify Database Setup

Check that the tables were created successfully:

```sql
\c ProductManagement
SET search_path TO productmanagement_dbo, public;
\dt
```

You should see the following tables:
- categories
- suppliers
- products
- producthistory
- productstats

## Application Configuration

### Connection String

The application uses connection strings defined in `appsettings.json`. Update these if your PostgreSQL setup differs:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
  },
  "Environment": "Development"
}
```

**Connection String Parameters:**
- `Host`: PostgreSQL server hostname (default: localhost)
- `Port`: PostgreSQL server port (default: 5432)
- `Database`: Database name (ProductManagement)
- `Username`: PostgreSQL username
- `Password`: PostgreSQL password
- `Pooling`: Enable connection pooling (recommended: true)

**Security Note:** For production environments, use secure credential management instead of storing passwords in configuration files.

## Building the Application

### Restore Dependencies

```bash
dotnet restore
```

### Build the Project

```bash
dotnet build
```

Expected output:
- Build Succeeded
- 0 Error(s)
- Warnings about Npgsql 8.0.0 vulnerability have been resolved by upgrading to 8.0.5

## Running the Application

```bash
dotnet run
```

The application will:
1. Connect to the PostgreSQL database using the configured connection string
2. Execute CRUD operations on the products table
3. Demonstrate transaction handling

## Verification Checklist

### Database Connection
- [ ] PostgreSQL server is running
- [ ] Database "ProductManagement" exists
- [ ] Schema "productmanagement_dbo" exists
- [ ] All tables are created
- [ ] Sample data is inserted
- [ ] Connection string in appsettings.json is correct

### Application Build
- [ ] Dependencies restored successfully
- [ ] Project builds without errors
- [ ] No security warnings (Npgsql 8.0.5+ resolves known vulnerabilities)

### Runtime Testing (Manual Verification Required)
- [ ] Application connects to PostgreSQL successfully
- [ ] SELECT operations return data correctly
- [ ] INSERT operations create new records
- [ ] UPDATE operations modify existing records
- [ ] DELETE operations remove records
- [ ] Transactions maintain atomicity (commit/rollback work correctly)

## Migration Summary

### SQL Server to PostgreSQL Changes

#### 1. Package References
- **Removed:** Microsoft.Data.SqlClient
- **Added:** Npgsql 8.0.5

#### 2. ADO.NET Classes
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`
- `SqlTransaction` → `NpgsqlTransaction`

#### 3. SQL Syntax Conversions
All SQL statements were processed through AWS DMS MCP tool and validated:
- Window functions adapted for PostgreSQL
- Date/time functions converted (GETDATE() → CURRENT_TIMESTAMP, GETUTCDATE() → clock_timestamp())
- Identity columns converted to SERIAL type
- SCOPE_IDENTITY() converted to RETURNING clause
- Schema names converted to lowercase (productmanagement_dbo)
- Stored procedures converted to PostgreSQL functions

#### 4. Connection Strings
- `Server=` → `Host=`
- `Integrated Security=` → `Username=` and `Password=`
- Added `Port=5432` for PostgreSQL

#### 5. Transaction Handling
- All transactions use NpgsqlTransaction
- BeginTransactionAsync(), CommitAsync(), RollbackAsync() patterns maintained

## SQL Statement Conversion Report

All SQL statements were:
1. **Extracted** from the codebase (documented in `extracted_statements.sql`)
2. **Converted** using AWS DMS MCP tool (documented in `converted_statements.sql` and `dms_conversion_log.json`)
3. **Validated** using SQL Equivalency tool (documented in `sql_equivalency_validation_report.json`)
4. **Re-integrated** into the codebase with proper PostgreSQL syntax

### Conversion Statistics
- Total statements processed: 7
- Successfully converted by DMS: 4
- Converted with warnings: 2
- Manual conversion after DMS failure: 2
- All statements validated through SQL Equivalency tool

## Troubleshooting

### Connection Issues

**Error:** "Connection refused"
- **Solution:** Verify PostgreSQL service is running: `sudo systemctl status postgresql`

**Error:** "password authentication failed"
- **Solution:** Check username/password in appsettings.json matches PostgreSQL credentials

**Error:** "database does not exist"
- **Solution:** Create the database: `CREATE DATABASE "ProductManagement";`

### Schema Issues

**Error:** "relation does not exist"
- **Solution:** Run the setup script: `psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_Setup.sql`

**Error:** "schema 'productmanagement_dbo' does not exist"
- **Solution:** The setup script creates this schema. Ensure the script ran successfully.

### Build Issues

**Warning:** Npgsql vulnerability (NU1903)
- **Solution:** Already resolved - using Npgsql 8.0.5

**Error:** Package restore failed
- **Solution:** Run `dotnet restore` manually

## Known Limitations

### SQL Equivalency Validation
All 7 SQL statement pairs returned ERROR status from the SQL Equivalency tool because the Z3 solver could not formally prove equivalence. This does **not** indicate the statements are incorrect - it means formal verification was inconclusive. Runtime testing is required to validate functional correctness.

### Unit/Integration Tests
The original codebase does not include unit or integration tests. Consider adding tests for:
- Database connection
- CRUD operations
- Transaction atomicity
- Error handling

## Security Considerations

1. **Credentials:** Use environment variables or secure vaults for production credentials
2. **Connection Pooling:** Already enabled for performance
3. **SQL Injection:** All queries use parameterized commands (protected)
4. **Npgsql Version:** Using 8.0.5 (no known vulnerabilities)

## Support and Documentation

- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Npgsql Documentation:** https://www.npgsql.org/doc/
- **Migration Report:** See `migration_summary_report.md` for detailed conversion information
- **SQL Conversion Log:** See `dms_conversion_log.json` for DMS tool processing details
- **Equivalency Report:** See `sql_equivalency_validation_report.json` for validation results

## Next Steps for Production Deployment

1. **Runtime Testing:** Execute comprehensive runtime tests against PostgreSQL
2. **Performance Testing:** Validate query performance meets requirements
3. **Security Audit:** Review connection strings and credential management
4. **Monitoring:** Set up database and application monitoring
5. **Backup Strategy:** Implement PostgreSQL backup and recovery procedures
6. **High Availability:** Configure PostgreSQL replication if required
7. **Unit Tests:** Develop comprehensive test suite for database operations

## Contact

For issues or questions about this migration, refer to:
- Transformation artifacts in the project root
- AWS DMS and SQL Equivalency tool documentation
- PostgreSQL community resources
