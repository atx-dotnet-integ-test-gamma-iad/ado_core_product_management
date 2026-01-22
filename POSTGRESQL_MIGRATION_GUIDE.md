# PostgreSQL Migration Guide - AdoCore Application

## Overview
This document provides instructions for setting up and testing the migrated ADO.NET application with PostgreSQL.

## Prerequisites
1. PostgreSQL 12 or higher installed
2. .NET 9.0 SDK installed
3. PostgreSQL credentials (default: username=postgres, password=postgres)

## Database Setup

### Step 1: Install PostgreSQL
If you haven't installed PostgreSQL yet:

**Windows:**
```bash
# Download from https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql
```

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### Step 2: Create Database and Schema

1. Connect to PostgreSQL as superuser:
```bash
psql -U postgres
```

2. Create the database:
```sql
CREATE DATABASE "ProductManagement";
\c ProductManagement
```

3. Run the setup script:
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Alternatively, you can run it from psql:
```sql
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### Step 3: Verify Database Setup

Connect to the database and verify tables:
```bash
psql -U postgres -d ProductManagement
```

```sql
-- List all tables
\dt

-- Verify data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- Test a sample query
SELECT name, price, stock_quantity FROM products LIMIT 5;
```

Expected results:
- 18 products
- 20 categories
- 8 suppliers

## Application Configuration

### Update Connection String (if needed)

Edit `appsettings.json` if your PostgreSQL credentials differ:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=YOUR_USERNAME;Password=YOUR_PASSWORD;Pooling=true;Minimum Pool Size=1;Maximum Pool Size=20"
  }
}
```

## Building the Application

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet build
```

Expected output: `Build succeeded. 0 Warning(s) 0 Error(s)`

## Testing the Application

### Manual Testing

Run the application:
```bash
dotnet run
```

The CLI application will present options to:
1. Get all products
2. Get product by ID
3. Insert new product
4. Update existing product
5. Delete product
6. Get products by price range
7. Get low stock products

### Database Operation Verification

Test each operation and verify in PostgreSQL:

**After INSERT:**
```sql
SELECT * FROM products ORDER BY product_id DESC LIMIT 1;
SELECT * FROM product_history WHERE action = 'INSERT' ORDER BY action_date DESC LIMIT 1;
```

**After UPDATE:**
```sql
SELECT * FROM products WHERE product_id = <id>;
SELECT * FROM product_history WHERE product_id = <id> AND action = 'UPDATE' ORDER BY action_date DESC LIMIT 1;
```

**After DELETE:**
```sql
SELECT * FROM products WHERE product_id = <id>; -- Should return no rows
SELECT * FROM product_history WHERE product_id = <id> AND action = 'DELETE' ORDER BY action_date DESC LIMIT 1;
```

### Transaction Verification

To verify transaction atomicity:

1. **Test successful transaction:**
   - Insert a product through the application
   - Verify both Products and ProductHistory tables are updated
   - Verify ProductStats is updated

2. **Test rollback (requires code modification for testing):**
   - Temporarily add an error condition in the middle of a transaction
   - Verify no partial data is committed
   - All changes should be rolled back

## SQL Statement Validation

The following SQL statements were converted and validated:

1. **GetAllProductsAsync** - SELECT with ORDER BY ✓
2. **GetProductByIdAsync** - SELECT with WHERE clause ✓
3. **InsertProductAsync** - 3-statement transaction (INSERT + UPDATE + INSERT) ✓
4. **UpdateProductAsync** - 4-statement transaction (UPDATE + UPDATE + UPDATE + INSERT) ✓
5. **DeleteProductAsync** - 4-statement transaction (DELETE + DELETE + UPDATE + INSERT) ✓
6. **GetProductsByPriceRangeAsync** - Complex CTE query ⚠
7. **GetLowStockProductsAsync** - Window function query ⚠

✓ = Validated as EQUIVALENT by SQL Equivalency tool
⚠ = Tool returned ERROR/UNKNOWN due to complexity - manual verification recommended

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to PostgreSQL
```
Solution:
1. Verify PostgreSQL is running: 
   - Windows: Check Services
   - macOS/Linux: sudo systemctl status postgresql
2. Check pg_hba.conf for authentication settings
3. Verify port 5432 is not blocked by firewall
```

**Problem:** Authentication failed
```
Solution:
1. Reset postgres password:
   ALTER USER postgres WITH PASSWORD 'newpassword';
2. Update appsettings.json with correct credentials
```

### Data Issues

**Problem:** Tables not found
```
Solution:
1. Verify you're connected to correct database:
   SELECT current_database();
2. Re-run the setup script:
   \i Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

**Problem:** Trigger not firing
```
Solution:
1. Verify trigger exists:
   \d products
2. Check trigger function:
   \df trg_products_history_func
3. Test manually:
   INSERT INTO products (name, price, stock_quantity) 
   VALUES ('Test', 100, 10);
   SELECT * FROM product_history ORDER BY action_date DESC LIMIT 1;
```

## Performance Considerations

1. **Indexes:** All necessary indexes have been created for optimal query performance
2. **Connection Pooling:** Enabled with Min=1, Max=20 connections
3. **Prepared Statements:** Npgsql automatically uses prepared statements for parameterized queries

## Migration Notes

### Key Differences from SQL Server

1. **Identity Columns:** `IDENTITY(1,1)` → `SERIAL`
2. **Boolean Type:** `BIT` → `BOOLEAN`
3. **String Types:** `NVARCHAR` → `VARCHAR` (PostgreSQL uses UTF-8 by default)
4. **Date Functions:** `GETDATE()` → `CURRENT_TIMESTAMP`
5. **User Function:** `SYSTEM_USER` → `CURRENT_USER`
6. **Triggers:** Require separate trigger function in PostgreSQL
7. **Stored Procedures:** Implemented as functions returning TABLE types

### Schema Object Name Changes

**Table Names:** Converted to lowercase (PostgreSQL convention)
- `Products` → `products`
- `ProductHistory` → `product_history`
- `ProductStats` → `product_stats`
- `Categories` → `categories`
- `Suppliers` → `suppliers`

**Column Names:** Converted to snake_case (PostgreSQL convention)
- `ProductId` → `product_id`
- `StockQuantity` → `stock_quantity`
- `CreatedDate` → `created_date`
- etc.

## Next Steps

### Recommended Actions

1. **Create Unit Tests:**
   - Create a test project for ProductRepository
   - Mock database connections for unit tests
   - Create integration tests with test database

2. **Add Logging:**
   - Implement structured logging for database operations
   - Log SQL execution times
   - Monitor connection pool metrics

3. **Error Handling:**
   - Add retry logic for transient failures
   - Implement circuit breaker pattern
   - Add detailed error messages

4. **Security:**
   - Use environment variables for connection strings
   - Implement proper user authentication in PostgreSQL
   - Use read-only connections where appropriate
   - Regularly update Npgsql package

## Support

For issues specific to:
- **PostgreSQL:** https://www.postgresql.org/docs/
- **Npgsql:** https://www.npgsql.org/doc/
- **.NET ADO.NET:** https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/

## Migration Artifacts

All migration artifacts are located in the project root:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.txt` - Detailed conversion log
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `final_migration_report.json` - Complete migration summary
