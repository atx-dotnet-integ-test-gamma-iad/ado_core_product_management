# PostgreSQL Migration Testing Guide

## Overview
This document provides instructions for setting up a PostgreSQL database to test the migrated ADO.NET application.

## Prerequisites
- PostgreSQL 12 or higher installed
- PostgreSQL client tools (psql) or GUI tool (pgAdmin)
- .NET 9.0 SDK
- Access to create databases and execute SQL scripts

## Database Setup

### Step 1: Create the Database
Connect to PostgreSQL as a superuser or with database creation privileges:

```bash
# Using psql command-line
psql -U postgres
```

Create the database:
```sql
CREATE DATABASE "ProductManagement";
```

### Step 2: Connect to the Database
```bash
psql -U postgres -d ProductManagement
```

### Step 3: Execute the Schema Script
Run the PostgreSQL setup script to create tables, insert sample data, and set up triggers:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Or from within psql:
```sql
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### Step 4: Verify Database Setup
Check that all tables were created:
```sql
\dt
```

Expected tables:
- categories
- suppliers
- products
- product_history
- product_stats

Verify sample data:
```sql
SELECT COUNT(*) FROM products;  -- Should return 18
SELECT COUNT(*) FROM categories;  -- Should return 20
SELECT COUNT(*) FROM suppliers;  -- Should return 8
```

## Application Configuration

### Update Connection String (if needed)
The application is configured to use the following connection string by default in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres"
  },
  "Environment": "Development"
}
```

Update the connection string parameters if your PostgreSQL setup differs:
- **Host**: PostgreSQL server hostname (default: localhost)
- **Port**: PostgreSQL port (default: 5432)
- **Database**: Database name (ProductManagement)
- **Username**: PostgreSQL username
- **Password**: PostgreSQL password

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

### Expected Operations
The application should successfully:
1. Connect to the PostgreSQL database
2. Execute SELECT queries to retrieve products
3. Execute INSERT queries to add new products
4. Execute UPDATE queries to modify products
5. Execute DELETE queries to remove products
6. Handle transactions properly with commit/rollback

## Testing Individual Repository Methods

### Test Data Retrieval Methods

#### GetAllProductsAsync()
This method retrieves all products with statistics using a CTE (Common Table Expression).
Expected: Returns all 18 products with average price and total product count.

#### GetProductByIdAsync(int productId)
Test with various product IDs:
```sql
-- Verify test data exists
SELECT product_id, name FROM products LIMIT 5;
```
Expected: Returns single product details for valid IDs, null for invalid IDs.

#### GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
Test with various price ranges:
- Low range: 0 - 100 (should find mice, keyboards)
- Mid range: 100 - 500 (should find most products)
- High range: 1000+ (should find laptops, desktops)

#### GetLowStockProductsAsync(int threshold)
Test with threshold = 10:
Expected: Returns products where stock_quantity <= 10

### Test Data Modification Methods

#### InsertProductAsync(Product product)
Test inserting a new product:
```csharp
var newProduct = new Product {
    Name = "Test Product",
    Description = "Test Description",
    Price = 99.99m,
    StockQuantity = 50
};
```
Expected: 
- Product inserted successfully
- New ProductId returned
- Product history record created
- ProductStats updated

#### UpdateProductAsync(Product product)
Test updating an existing product:
```csharp
var product = await repository.GetProductByIdAsync(1);
product.Price = 1399.99m;
product.StockQuantity = 20;
await repository.UpdateProductAsync(product);
```
Expected:
- Product updated in database
- Product history record created with old and new values
- ProductStats updated
- Transaction commits successfully

#### DeleteProductAsync(int productId)
Test deleting a product:
```csharp
await repository.DeleteProductAsync(1);
```
Expected:
- Product removed from products table
- Product history record created
- ProductStats updated
- Transaction commits successfully

## Verification Queries

### Check Transaction History
```sql
SELECT * FROM product_history ORDER BY action_date DESC LIMIT 10;
```

### Check Product Statistics
```sql
SELECT * FROM product_stats;
```

### Verify Trigger Functionality
After inserting/updating/deleting products, verify that product_history records are created:
```sql
SELECT 
    ph.history_id,
    ph.product_id,
    p.name as product_name,
    ph.action,
    ph.old_price,
    ph.new_price,
    ph.old_stock,
    ph.new_stock,
    ph.action_date
FROM product_history ph
LEFT JOIN products p ON ph.product_id = p.product_id
ORDER BY ph.action_date DESC;
```

## Troubleshooting

### Connection Issues
If the application cannot connect:
1. Verify PostgreSQL is running: `systemctl status postgresql` (Linux) or check Services (Windows)
2. Verify connection parameters in appsettings.json
3. Check PostgreSQL authentication in pg_hba.conf
4. Verify firewall allows connections to port 5432

### Permission Issues
If you encounter permission errors:
```sql
-- Grant all privileges to the user
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

### Data Type Issues
All data types have been properly converted:
- NVARCHAR → VARCHAR
- DECIMAL(18,2) → DECIMAL(18,2)
- INT → INTEGER
- BIT → BOOLEAN
- DATETIME → TIMESTAMP
- IDENTITY → SERIAL

### SQL Syntax Differences
Key differences handled in migration:
- GETDATE() → CURRENT_TIMESTAMP
- SCOPE_IDENTITY() → RETURNING clause
- Square brackets [table] → Double quotes "table" or no quotes
- Stored procedures → Functions with RETURNS TABLE or RETURNS type
- Triggers use CREATE FUNCTION + CREATE TRIGGER pattern

## Exit Criteria Validation

### Criterion 12: Database Connectivity
✅ Test: Run application and verify connection establishment
```bash
dotnet run
# Look for successful connection messages in output
```

### Criterion 13: Database Operations
✅ Test each repository method:
- GetAllProductsAsync()
- GetProductByIdAsync()
- InsertProductAsync()
- UpdateProductAsync()
- DeleteProductAsync()
- GetProductsByPriceRangeAsync()
- GetLowStockProductsAsync()

### Criterion 14: Transaction Atomicity
✅ Test transaction rollback:
- Modify InsertProductAsync to throw exception after insert
- Verify product is NOT inserted (transaction rolled back)
- Remove exception and verify successful insert

### Criterion 15: Unit/Integration Tests
If unit tests exist in the project:
```bash
dotnet test
```

## Known Limitations

### SQL Equivalency Validation
All 7 SQL statement pairs returned ERROR status from the SQL Equivalency tool due to tool-specific issues ('uniqueID' error). The statements were manually converted following PostgreSQL syntax guidelines and best practices:

1. GetAllProductsAsync: CTE syntax conversion
2. GetProductByIdAsync: Parameter syntax conversion
3. InsertProductAsync: Transaction and INSERT syntax
4. UpdateProductAsync: Transaction and UPDATE syntax
5. DeleteProductAsync: Transaction and DELETE syntax
6. GetProductsByPriceRangeAsync: BETWEEN clause conversion
7. GetLowStockProductsAsync: Simple SELECT conversion

Manual verification of these conversions through actual database execution is the recommended validation approach.

## Success Criteria

The migration is considered successful when:
1. ✅ Application connects to PostgreSQL database without errors
2. ✅ All SELECT operations return expected data
3. ✅ All INSERT operations successfully create records
4. ✅ All UPDATE operations successfully modify records
5. ✅ All DELETE operations successfully remove records
6. ✅ Transactions maintain atomicity (rollback on error, commit on success)
7. ✅ Triggers create product history records correctly
8. ✅ Product statistics are updated properly
9. ✅ All unit/integration tests pass (if tests exist)

## Support

For issues with:
- **PostgreSQL setup**: Refer to PostgreSQL official documentation
- **SQL syntax**: Review converted_statements.sql in project root
- **Migration details**: Review final_migration_report.json in project root
- **Equivalency validation**: Review sql_equivalency_validation_report.json in project root
