# PostgreSQL Database Setup Instructions

This document provides step-by-step instructions for setting up the PostgreSQL database required to test the migrated application.

## Prerequisites

- PostgreSQL 13 or higher installed
- PostgreSQL client tools (psql) available
- PostgreSQL server running

## Setup Steps

### 1. Create the Database

Connect to PostgreSQL as a superuser (usually `postgres`):

```bash
psql -U postgres
```

Create the ProductManagement database:

```sql
CREATE DATABASE "ProductManagement";
```

Exit psql:

```sql
\q
```

### 2. Run the Setup Script

Connect to the newly created database and run the setup script:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

This script will:
- Create the `productmanagement_dbo` schema
- Create all required tables (categories, suppliers, products, producthistory, productstats)
- Create indexes for optimal performance
- Create triggers for automatic history tracking
- Create PostgreSQL functions (equivalent to SQL Server stored procedures)
- Insert sample data for testing

### 3. Create Application User (Optional but Recommended)

For security best practices, create a dedicated application user:

```bash
psql -U postgres -d ProductManagement
```

```sql
-- Create application user
CREATE USER appuser WITH PASSWORD 'your_secure_password';

-- Grant schema usage
GRANT USAGE ON SCHEMA productmanagement_dbo TO appuser;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO appuser;

-- Grant sequence permissions (for SERIAL columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO appuser;

-- Grant function execution permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA productmanagement_dbo TO appuser;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;

ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
GRANT USAGE, SELECT ON SEQUENCES TO appuser;

ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
GRANT EXECUTE ON FUNCTIONS TO appuser;
```

### 4. Update Connection String

Update the `appsettings.json` file with your PostgreSQL connection details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=appuser;Password=your_secure_password",
    "ProdConnection": "Host=your_prod_server;Port=5432;Database=ProductManagement;Username=appuser;Password=your_secure_password"
  },
  "Environment": "Development"
}
```

If you're using the default postgres user for testing, use:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_postgres_password"
  }
}
```

## Verification

### Test Database Connection

You can verify the database setup by connecting and running a simple query:

```bash
psql -U postgres -d ProductManagement
```

```sql
-- Set search path
SET search_path TO productmanagement_dbo, public;

-- Check tables
\dt productmanagement_dbo.*

-- Check sample data
SELECT COUNT(*) FROM productmanagement_dbo.products;
SELECT COUNT(*) FROM productmanagement_dbo.categories;
SELECT COUNT(*) FROM productmanagement_dbo.suppliers;

-- Test a query
SELECT productid, name, price, stockquantity 
FROM productmanagement_dbo.products 
LIMIT 5;
```

Expected results:
- 19 products
- 20 categories
- 8 suppliers

### Test Application Connectivity

Once the database is set up, test the application:

```bash
dotnet run
```

The application should:
1. Successfully connect to PostgreSQL
2. Execute all CRUD operations (SELECT, INSERT, UPDATE, DELETE)
3. Maintain transaction atomicity

## Schema Details

### Key Tables

1. **products**: Main product catalog
   - Primary key: `productid` (SERIAL)
   - Contains product details, pricing, and stock information
   - Uses lowercase column names (PostgreSQL convention)

2. **producthistory**: Audit trail for product changes
   - Automatically populated by trigger
   - Tracks INSERT, UPDATE, and DELETE operations

3. **productstats**: Aggregated statistics
   - Single-row table with global statistics
   - Updated by application code

4. **categories**: Product categorization
   - Supports hierarchical structure with self-referencing foreign key

5. **suppliers**: Supplier information
   - Links to products via foreign key

### Important Notes

1. **Schema Name**: All tables are in the `productmanagement_dbo` schema to match the converted application code.

2. **Lowercase Names**: PostgreSQL uses lowercase names by default. The migration converted all table and column names to lowercase.

3. **Serial vs Identity**: PostgreSQL uses SERIAL (or BIGSERIAL) instead of SQL Server's IDENTITY. These work similarly but have slight syntax differences.

4. **Functions vs Stored Procedures**: PostgreSQL uses functions (that can return tables) instead of SQL Server's stored procedures.

5. **Triggers**: PostgreSQL trigger syntax differs from SQL Server. The setup script includes proper PostgreSQL trigger functions.

## Troubleshooting

### Connection Issues

If you cannot connect:
1. Check PostgreSQL is running: `pg_isready`
2. Verify `pg_hba.conf` allows local connections
3. Check firewall settings for port 5432
4. Verify username and password in connection string

### Permission Issues

If you get permission errors:
1. Ensure the user has proper grants (see Step 3)
2. Check schema ownership
3. Verify `search_path` includes `productmanagement_dbo`

### Schema Not Found

If application reports schema not found:
1. Verify schema exists: `\dn` in psql
2. Check connection string includes correct database name
3. Ensure application code references `productmanagement_dbo` schema

## Next Steps

After successfully setting up the database:

1. **Run the Application**: Test all CRUD operations
2. **Verify Transactions**: Test rollback scenarios
3. **Check History Tracking**: Verify trigger creates history records
4. **Test Edge Cases**: Try boundary conditions and error scenarios
5. **Performance Testing**: Validate query performance with larger datasets

## Support

For PostgreSQL-specific questions:
- Official documentation: https://www.postgresql.org/docs/
- Community support: https://www.postgresql.org/support/

For application-specific questions:
- Review the migration_summary_report.txt
- Check sql_equivalency_validation_report.json for statement conversions
- Review dms_conversion_log.txt for conversion details
