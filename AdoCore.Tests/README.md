# AdoCore.Tests

This test project contains integration tests for the AdoCore application after migration from SQL Server to PostgreSQL.

## Test Requirements

All tests in this project require a **live PostgreSQL database** to execute. Tests are currently marked with `Skip` attribute because:

1. No live PostgreSQL database is configured in the CI/CD environment
2. Database schema must be created before tests can run
3. Test data must be seeded before executing tests

## Database Setup Instructions

### 1. Install PostgreSQL

Ensure PostgreSQL is installed and running:
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Start PostgreSQL if not running
sudo systemctl start postgresql
```

### 2. Create Database and Schema

```sql
-- Create database
CREATE DATABASE "ProductManagement";

-- Connect to the database
\c ProductManagement

-- Create schema
CREATE SCHEMA IF NOT EXISTS public;

-- Create Products table
CREATE TABLE public."Products" (
    "ProductId" SERIAL PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "Price" NUMERIC(10, 2) NOT NULL,
    "StockQuantity" INT NOT NULL,
    "CreatedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create ProductHistory table
CREATE TABLE public."ProductHistory" (
    "HistoryId" SERIAL PRIMARY KEY,
    "ProductId" INT NOT NULL,
    "Action" VARCHAR(50) NOT NULL,
    "ChangedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "ChangedBy" VARCHAR(100),
    FOREIGN KEY ("ProductId") REFERENCES public."Products"("ProductId") ON DELETE CASCADE
);

-- Create ProductStats table (if used)
CREATE TABLE public."ProductStats" (
    "StatId" SERIAL PRIMARY KEY,
    "ProductId" INT NOT NULL,
    "AvgPrice" NUMERIC(10, 2),
    "TotalProducts" INT,
    "LastUpdated" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("ProductId") REFERENCES public."Products"("ProductId") ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX idx_products_price ON public."Products"("Price");
CREATE INDEX idx_products_stock ON public."Products"("StockQuantity");
CREATE INDEX idx_producthistory_productid ON public."ProductHistory"("ProductId");
```

### 3. Seed Test Data (Optional)

```sql
-- Insert sample products for testing
INSERT INTO public."Products" ("Name", "Price", "StockQuantity") VALUES
('Laptop', 999.99, 50),
('Mouse', 25.50, 200),
('Keyboard', 75.00, 150),
('Monitor', 299.99, 30),
('USB Cable', 9.99, 500),
('Hard Drive', 89.99, 75),
('RAM Module', 149.99, 100);
```

### 4. Configure Connection String

Update the connection string in `ProductRepositoryTests.cs` if your PostgreSQL configuration differs:

```csharp
["ConnectionStrings:DevConnection"] = "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;"
```

## Running the Tests

### Enable Tests

Remove the `Skip` attribute from tests you want to run:

```csharp
// Before
[Fact(Skip = "Requires live PostgreSQL database")]

// After
[Fact]
```

### Execute Tests

```bash
# Run all tests
dotnet test

# Run specific test
dotnet test --filter "FullyQualifiedName~GetAllProductsAsync_ShouldReturnProducts"

# Run with verbose output
dotnet test --verbosity detailed
```

## Test Coverage

The test suite covers:

1. **CRUD Operations**
   - `GetAllProductsAsync` - Retrieve all products with complex CTE queries
   - `GetProductByIdAsync` - Retrieve product by ID
   - `InsertProductAsync` - Insert new product with RETURNING clause
   - `UpdateProductAsync` - Update existing product
   - `DeleteProductAsync` - Delete product

2. **Advanced Queries**
   - `GetProductsByPriceRangeAsync` - Filter products by price range
   - `GetLowStockProductsAsync` - Find products below stock threshold

3. **Transaction Handling**
   - `ExecuteInTransactionAsync_WithCommit` - Verify transaction commit
   - `ExecuteInTransactionAsync_WithException` - Verify transaction rollback

## Test Results Validation

After running tests against a live PostgreSQL database, you can validate:

- ✅ **Exit Criterion 12**: Database connectivity is working
- ✅ **Exit Criterion 13**: All database operations execute successfully  
- ✅ **Exit Criterion 14**: Transaction atomicity is maintained
- ✅ **Exit Criterion 15**: Tests pass with PostgreSQL database

## Known Issues

1. **Complex Queries with CTEs**: 5 SQL statements involve CTEs and window functions that were marked as ERROR by the SQL Equivalency tool. These require manual validation through actual database execution.

2. **Parameter Binding**: Verify that PostgreSQL parameter syntax (`@ParameterName`) works correctly for all parameterized queries.

3. **RETURNING Clause**: The `InsertProductAsync` method uses PostgreSQL's RETURNING clause to get the new ID. Verify this works as expected.

## Troubleshooting

### Connection Failed
```
Npgsql.NpgsqlException: Connection refused
```
**Solution**: Ensure PostgreSQL is running and accessible on the specified host/port.

### Authentication Failed
```
Npgsql.NpgsqlException: password authentication failed
```
**Solution**: Verify username and password in connection string.

### Table Not Found
```
Npgsql.NpgsqlException: relation "Products" does not exist
```
**Solution**: Run the database setup scripts to create required tables.

### Transaction Deadlock
```
Npgsql.NpgsqlException: deadlock detected
```
**Solution**: Ensure tests run sequentially or use different test data to avoid conflicts.

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [xUnit Documentation](https://xunit.net/)
