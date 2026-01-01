# PostgreSQL Database Setup Guide

## Overview
This guide provides instructions for setting up the PostgreSQL database for the AdoCore application after migration from SQL Server.

## Prerequisites
- PostgreSQL 12 or higher installed
- psql command-line tool or pgAdmin
- PostgreSQL server running on localhost (or update connection string accordingly)

## Setup Steps

### 1. Create Database
```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Create the database
CREATE DATABASE productmanagement;

# Connect to the new database
\c productmanagement
```

### 2. Run Schema Setup Script
```bash
# From command line (recommended)
psql -U postgres -d productmanagement -f Database/Scripts/postgresql_schema_setup.sql

# Or from within psql
\i Database/Scripts/postgresql_schema_setup.sql
```

### 3. Verify Setup
```sql
-- List all tables
\dt

-- Check product count
SELECT COUNT(*) FROM products;

-- Verify statistics are initialized
SELECT * FROM productstats;
```

### 4. Update Connection String
The application uses the connection string from `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=postgres"
  }
}
```

Update the connection string with your PostgreSQL credentials:
- **Host**: PostgreSQL server hostname (default: localhost)
- **Database**: Database name (default: productmanagement)
- **Username**: PostgreSQL username (default: postgres)
- **Password**: Your PostgreSQL password

## Schema Details

### Tables Created
1. **categories** - Product categories with hierarchical support
2. **suppliers** - Supplier information
3. **products** - Main product table (18 sample products)
4. **producthistory** - Audit log for product changes
5. **productstats** - Aggregated product statistics

### Triggers
- **trg_products_history** - Automatically logs INSERT/UPDATE/DELETE operations on products table

### Sample Data
The schema setup script includes:
- 20 categories (hierarchical structure)
- 8 suppliers
- 18 sample products across various categories
- Initialized product statistics

## Testing the Setup

### Test Basic Queries
```sql
-- Get all products
SELECT * FROM products ORDER BY name;

-- Get products with categories
SELECT p.name, p.price, c.name as category 
FROM products p 
LEFT JOIN categories c ON p.categoryid = c.categoryid;

-- Check low stock products
SELECT name, stockquantity, reorderlevel 
FROM products 
WHERE stockquantity <= reorderlevel;
```

### Test Application Queries
The application uses the following complex queries:

1. **GetAllProductsAsync** - Products with price analysis using window functions
2. **GetProductByIdAsync** - Product with historical price tracking
3. **InsertProductAsync** - Insert with automatic history logging and stats update
4. **UpdateProductAsync** - Update with history logging and stats recalculation
5. **DeleteProductAsync** - Delete with history logging and stats adjustment
6. **GetProductsByPriceRangeAsync** - Price range with ranking and percentile
7. **GetLowStockProductsAsync** - Stock analysis with window functions

## Troubleshooting

### Connection Issues
If you encounter connection errors:
1. Verify PostgreSQL is running: `systemctl status postgresql` (Linux) or check Services (Windows)
2. Check pg_hba.conf for authentication settings
3. Ensure the user has permissions on the database:
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE productmanagement TO postgres;
   ```

### Permission Issues
If you get permission errors:
```sql
-- Grant schema permissions
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

### Schema Name Issues
The DMS tool converted table references to use the `productmanagement_dbo` schema prefix. However, the current implementation uses the default `public` schema with lowercase table names. This is intentional for simplicity. If you need to use a custom schema:

1. Create the schema:
   ```sql
   CREATE SCHEMA productmanagement_dbo;
   ```

2. Update the schema setup script to create tables in that schema

3. The application SQL statements already use lowercase names which PostgreSQL handles correctly

## Migration Notes

### Key Differences from SQL Server
1. **Schema Names**: PostgreSQL uses `public` schema by default; SQL Server uses `dbo`
2. **Case Sensitivity**: PostgreSQL identifiers are case-insensitive by default; the application uses lowercase
3. **IDENTITY**: Replaced with SERIAL in PostgreSQL
4. **GETDATE()**: Replaced with CURRENT_TIMESTAMP
5. **Transactions**: Handled at application level using Npgsql transactions
6. **SCOPE_IDENTITY()**: Replaced with RETURNING clause

### Complex Queries Status
All 7 SQL statements have been converted to PostgreSQL:
- **Statements 1, 2, 6, 7**: Use CTEs and window functions (LAG, AVG, RANK, PERCENT_RANK)
- **Statement 3**: Uses RETURNING clause for insert
- **Statements 4, 5**: Split into multiple statements with application-level transactions

### Equivalency Validation Results
- **2 statements**: Validated as EQUIVALENT by SQL Equivalency tool
- **5 statements**: Marked as ERROR due to tool limitations with complex CTEs/window functions
- All 5 ERROR statements are syntactically correct and should work functionally, but require runtime testing

## Next Steps

1. **Database Setup**: Execute the schema setup script
2. **Connection Testing**: Run the application and verify database connectivity
3. **Functional Testing**: Test all CRUD operations:
   - Create new products
   - Read product lists and details
   - Update product information
   - Delete products
4. **Transaction Testing**: Verify transaction atomicity with rollback scenarios
5. **Performance Testing**: Verify query performance with window functions and CTEs

## Support Resources
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- Application Repository: See README.md in project root
