# PostgreSQL Database Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the PostgreSQL database required for the migrated ADO.NET application.

## Prerequisites
- PostgreSQL 12 or higher installed
- PostgreSQL server running on localhost:5432 (or adjust connection strings accordingly)
- PostgreSQL user with database creation privileges (default: postgres)

## Setup Steps

### 1. Install PostgreSQL (if not already installed)

#### Windows
Download and install from: https://www.postgresql.org/download/windows/

#### macOS
```bash
brew install postgresql@14
brew services start postgresql@14
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. Create Database and Run Schema Script

#### Option A: Using psql Command Line

1. Connect to PostgreSQL as superuser:
```bash
psql -U postgres
```

2. Create the database:
```sql
CREATE DATABASE "ProductManagement";
```

3. Connect to the new database:
```sql
\c ProductManagement
```

4. Run the schema script:
```sql
\i /path/to/Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Or run from command line:
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

#### Option B: Using pgAdmin (GUI)

1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" and select "Create" > "Database"
3. Name it "ProductManagement"
4. Right-click on the new database and select "Query Tool"
5. Open the file `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
6. Execute the script

### 3. Verify Database Setup

Connect to the database and verify tables were created:

```sql
-- List all tables
\dt

-- Expected tables:
-- categories
-- suppliers
-- products
-- producthistory
-- productstats

-- Verify sample data
SELECT COUNT(*) FROM products;  -- Should return 18
SELECT COUNT(*) FROM categories;  -- Should return 20
SELECT COUNT(*) FROM suppliers;  -- Should return 8
```

### 4. Configure Application Connection String

Update the `appsettings.json` file with your PostgreSQL connection details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD"
  }
}
```

**Security Note**: Replace `YOUR_PASSWORD` with your actual PostgreSQL password. For production environments, use environment variables or secure configuration management instead of hardcoded passwords.

### 5. Test Database Connectivity

Run a simple test to verify connectivity:

```bash
dotnet run
```

The application should now connect to PostgreSQL and execute database operations.

## Database Schema Overview

### Tables Created

1. **categories** - Product categories with hierarchical structure
   - Primary Key: categoryid (SERIAL)
   - Self-referencing foreign key for parent categories

2. **suppliers** - Supplier information
   - Primary Key: supplierid (SERIAL)

3. **products** - Main product table
   - Primary Key: productid (SERIAL)
   - Foreign Keys: categoryid, supplierid

4. **producthistory** - Audit trail for product changes
   - Primary Key: historyid (SERIAL)
   - Foreign Key: productid

5. **productstats** - Aggregated product statistics
   - Primary Key: statid (constrained to value 1)
   - Single-row table for global statistics

### Database Objects

- **Indexes**: Created on foreign keys and frequently queried columns
- **Trigger**: `trg_products_history` - Automatically logs all INSERT, UPDATE, DELETE operations on products
- **Functions**: PostgreSQL functions equivalent to original SQL Server stored procedures:
  - `sp_getallproducts()` - Get all products
  - `sp_getproductbyid(p_productid)` - Get product by ID
  - `sp_insertproduct(...)` - Insert new product
  - `sp_updateproduct(...)` - Update existing product
  - `sp_deleteproduct(p_productid)` - Delete product

### Key Differences from SQL Server Schema

1. **Naming Convention**: All schema objects use lowercase names (PostgreSQL convention)
   - `Products` → `products`
   - `ProductId` → `productid`

2. **Data Types**:
   - `IDENTITY` → `SERIAL`
   - `NVARCHAR` → `VARCHAR`
   - `BIT` → `BOOLEAN`
   - `DATETIME` → `TIMESTAMP`
   - `GETDATE()` → `CURRENT_TIMESTAMP`

3. **Stored Procedures**: Converted to PostgreSQL functions
   - Return types explicitly defined
   - Use `RETURNS TABLE` for result sets
   - Use `LANGUAGE plpgsql`

4. **Triggers**: Converted to trigger functions
   - Separate function created (`trg_products_history_func`)
   - Trigger calls function using `EXECUTE FUNCTION`

## Integration Testing Checklist

After database setup, verify the following operations work correctly:

### Basic CRUD Operations
- [ ] GetAllProducts - Retrieve all products
- [ ] GetProductById - Retrieve single product
- [ ] InsertProduct - Create new product
- [ ] UpdateProduct - Modify existing product
- [ ] DeleteProduct - Remove product

### Transaction Operations
- [ ] InsertProductAsync - Insert with transaction
- [ ] UpdateProductAsync - Update with transaction
- [ ] DeleteProductAsync - Delete with transaction
- [ ] Transaction rollback on error

### Trigger Functionality
- [ ] Product history logged on INSERT
- [ ] Product history logged on UPDATE
- [ ] Product history logged on DELETE

### Statistics Operations
- [ ] GetProductStatsAsync - Retrieve statistics
- [ ] UpdateProductStatsAsync - Update statistics

## Troubleshooting

### Connection Errors

**Error**: `Connection refused`
- **Solution**: Ensure PostgreSQL service is running
```bash
# Linux/macOS
sudo systemctl status postgresql
# or
brew services list

# Start if not running
sudo systemctl start postgresql
# or
brew services start postgresql@14
```

**Error**: `password authentication failed`
- **Solution**: Verify username and password in connection string
- Reset password if needed:
```sql
ALTER USER postgres PASSWORD 'new_password';
```

### Schema Errors

**Error**: `relation "products" does not exist`
- **Solution**: Verify schema script ran successfully
- Check current database: `SELECT current_database();`
- Re-run schema script if needed

**Error**: `permission denied`
- **Solution**: Grant necessary permissions:
```sql
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;
```

### Data Type Errors

**Error**: Column type mismatch
- **Solution**: Verify the schema script matches the application's data model
- Check for any manual modifications to table structures

## Security Considerations

1. **Production Passwords**: Never commit passwords to source control
2. **User Privileges**: Create dedicated database user with minimum required privileges
3. **SSL Connection**: Enable SSL for production databases
4. **Firewall**: Configure PostgreSQL to accept connections only from trusted sources
5. **Backup**: Implement regular backup strategy for production data

## Sample Production User Setup

```sql
-- Create dedicated application user
CREATE USER appuser WITH PASSWORD 'secure_password_here';

-- Grant necessary privileges
GRANT CONNECT ON DATABASE "ProductManagement" TO appuser;
GRANT USAGE ON SCHEMA public TO appuser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO appuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO appuser;

-- Update connection string to use appuser
-- "Host=localhost;Port=5432;Database=ProductManagement;Username=appuser;Password=secure_password_here"
```

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- PostgreSQL vs SQL Server: https://wiki.postgresql.org/wiki/Things_to_find_out_about_when_moving_from_Microsoft_SQL_Server_to_PostgreSQL

## Next Steps

After completing database setup:

1. Run the application: `dotnet run`
2. Execute integration tests (if available)
3. Verify all database operations work correctly
4. Review application logs for any database-related errors
5. Test transaction rollback scenarios
6. Verify trigger and stored procedure functionality
