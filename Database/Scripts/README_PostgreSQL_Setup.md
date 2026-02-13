# PostgreSQL Database Setup Instructions

## Prerequisites
- PostgreSQL 12 or higher installed
- PostgreSQL server running
- `psql` command-line tool available

## Setup Steps

### 1. Create the Database

Connect to PostgreSQL as a superuser (e.g., postgres):

```bash
psql -U postgres
```

Create the ProductManagement database:

```sql
CREATE DATABASE "ProductManagement";
\q
```

### 2. Run the Setup Script

Execute the PostgreSQL setup script:

```bash
psql -U postgres -d ProductManagement -f 01_InitialSetup_PostgreSQL.sql
```

Alternatively, you can run it from within psql:

```bash
psql -U postgres -d ProductManagement
```

Then from the psql prompt:

```sql
\i 01_InitialSetup_PostgreSQL.sql
```

### 3. Verify the Setup

Check that all tables were created:

```sql
\dt
```

Expected tables:
- categories
- suppliers
- products
- producthistory
- productstats

Check sample data:

```sql
SELECT COUNT(*) FROM Products;
-- Should return 18 products

SELECT COUNT(*) FROM Categories;
-- Should return 20 categories

SELECT COUNT(*) FROM Suppliers;
-- Should return 8 suppliers
```

### 4. Update Application Connection String

Update the connection string in `appsettings.json` with your PostgreSQL server details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password",
    "ProdConnection": "Host=your_server;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password"
  }
}
```

**Security Note:** Never commit passwords to source control. Use environment variables or secure configuration management for production.

### 5. Test the Application

Build and run the application:

```bash
dotnet build
dotnet run
```

## Database Schema Overview

### Tables

1. **Categories** - Product categories with hierarchical structure
2. **Suppliers** - Supplier information
3. **Products** - Main product catalog
4. **ProductHistory** - Audit trail for product changes
5. **ProductStats** - Aggregated statistics about products

### Key Features

- **SERIAL columns** for auto-increment primary keys (equivalent to SQL Server IDENTITY)
- **TIMESTAMP** data type for date/time columns (equivalent to SQL Server DATETIME)
- **BOOLEAN** data type (equivalent to SQL Server BIT)
- **Triggers** implemented using PostgreSQL trigger functions
- **Stored procedures** implemented as PostgreSQL functions returning tables or values

### Indexes

All necessary indexes have been created including:
- Foreign key indexes for performance
- Unique index on SKU
- Indexes on frequently queried columns

## Troubleshooting

### Connection Issues

If you cannot connect to PostgreSQL:

1. Check that PostgreSQL service is running:
   ```bash
   sudo systemctl status postgresql  # Linux
   pg_ctl status                      # Windows/Manual installation
   ```

2. Verify `pg_hba.conf` allows your connection method
3. Check firewall settings if connecting remotely

### Permission Issues

If you get permission errors:

```sql
-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO your_username;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
```

### Data Type Issues

PostgreSQL is more strict about data types than SQL Server. Ensure:
- String comparisons are case-sensitive by default
- Use `::` for explicit casting when needed
- BOOLEAN values are `true`/`false` not 1/0

## Migration Notes

This database schema has been migrated from SQL Server to PostgreSQL with the following key changes:

1. **IDENTITY → SERIAL**: Auto-increment columns now use SERIAL data type
2. **BIT → BOOLEAN**: Boolean columns now use true/false instead of 1/0
3. **GETDATE() → CURRENT_TIMESTAMP**: Date/time functions updated
4. **NVARCHAR → VARCHAR**: String types simplified (PostgreSQL VARCHAR supports Unicode by default)
5. **SCOPE_IDENTITY() → RETURNING**: INSERT operations use RETURNING clause
6. **Triggers**: Converted from T-SQL to PL/pgSQL with trigger functions
7. **Stored Procedures**: Converted to PostgreSQL functions

For detailed SQL statement conversions, see:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.json` - Detailed conversion log
- `sql_equivalency_validation_report.json` - Equivalency validation results
