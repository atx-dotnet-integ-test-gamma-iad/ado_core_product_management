# PostgreSQL Runtime Validation Guide

This guide provides detailed instructions for validating the AdoCore application against a PostgreSQL database instance.

## Prerequisites

1. **PostgreSQL Installation**: PostgreSQL 12 or higher installed and running
2. **Database Creation**: Create the ProductManagement database
3. **User Permissions**: Ensure the postgres user (or configured user) has appropriate permissions
4. **Network Access**: PostgreSQL server must be accessible from the application host

## Setup Instructions

### Step 1: Install PostgreSQL

**For Windows:**
```bash
# Download and install from https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql
```

**For Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**For macOS:**
```bash
# Using Homebrew:
brew install postgresql
brew services start postgresql
```

**Using Docker (Recommended for testing):**
```bash
# Start PostgreSQL container
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Verify container is running
docker ps | grep postgres-adocore
```

### Step 2: Create and Initialize Database

**Option A: Using psql command-line:**
```bash
# Connect to PostgreSQL
psql -U postgres -h localhost

# Create database (if using Docker, database is already created)
CREATE DATABASE "ProductManagement";

# Connect to the database
\c ProductManagement

# Run the PostgreSQL setup script
\i /path/to/Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

**Option B: Using pgAdmin:**
1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" and select "Create" > "Database"
3. Name it "ProductManagement"
4. Open a Query Tool for the ProductManagement database
5. Open and execute the file: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`

**Option C: Using Docker exec:**
```bash
# Copy the SQL script to the container
docker cp Database/Scripts/01_InitialSetup_PostgreSQL.sql postgres-adocore:/tmp/

# Execute the script
docker exec -i postgres-adocore psql -U postgres -d ProductManagement -f /tmp/01_InitialSetup_PostgreSQL.sql
```

### Step 3: Verify Database Setup

```sql
-- Connect to PostgreSQL
psql -U postgres -h localhost -d ProductManagement

-- Check tables exist
\dt

-- Expected output should show:
-- categories
-- products
-- producthistory
-- productstats
-- suppliers

-- Verify data was inserted
SELECT COUNT(*) FROM products;
-- Expected: 18 rows

SELECT COUNT(*) FROM categories;
-- Expected: 20 rows

SELECT COUNT(*) FROM suppliers;
-- Expected: 8 rows

-- Check productstats was initialized
SELECT * FROM productstats WHERE statid = 1;
-- Should show statistics with totalproducts = 18
```

### Step 4: Configure Application Connection String

The connection string in `appsettings.json` is already configured for PostgreSQL:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres",
    "ProdConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres"
  },
  "Environment": "Development"
}
```

**If your PostgreSQL setup differs, update the connection string:**
- **Host**: Change if PostgreSQL is on a different server
- **Database**: Should remain "ProductManagement"
- **Username**: Change if using a different PostgreSQL user
- **Password**: Update with the correct password
- **Port**: Add `;Port=5432` if using a non-default port

### Step 5: Build the Application

```bash
cd /path/to/sourceCode
dotnet build
```

**Expected result:** Build should succeed with 0 errors

## Validation Tests

### Criterion 12: Database Connection Test

**Test 1: Basic Connection**
```bash
# Create a test program to verify connection
cd /path/to/sourceCode

# Run the application with a simple connection test
# The application should successfully connect without errors
```

**Test SQL Query Directly:**
```bash
# Connect via psql
psql -U postgres -h localhost -d ProductManagement

# Test the connection string parameters
SELECT version();
SELECT current_database();
SELECT current_user;
```

**Expected Result:** 
- Application connects successfully without exceptions
- Database name is "ProductManagement"
- User is "postgres" (or configured user)

**Pass Criteria:** No connection exceptions or errors

### Criterion 13: Database Operations Test

Test all CRUD operations against the PostgreSQL database.

**Test 2: SELECT Operations**

Test the read methods in ProductRepository:

1. **GetAllProductsAsync:**
```bash
# This method uses a CTE with window functions
# Should return all 18 products with price categories
```

Expected behavior:
- Returns list of products
- Includes computed columns (pricecategory, pricepercentageofaverage)
- Uses PostgreSQL window functions (AVG OVER, COUNT OVER)

2. **GetProductByIdAsync:**
```bash
# Test with productid = 1
# Uses CTE with LAG window function
```

Expected behavior:
- Returns single product with history data
- Uses LAG function for previous price/stock
- Computes price change percentage

3. **GetProductsByPriceRangeAsync:**
```bash
# Test with minPrice = 100, maxPrice = 500
# Uses RANK and PERCENT_RANK window functions
```

Expected behavior:
- Returns products within price range
- Includes price ranking and percentile
- Computes price segment (Budget/Mid-Range/Premium)

4. **GetLowStockProductsAsync:**
```bash
# Test with threshold = 10
# Uses window functions for stock analysis
```

Expected behavior:
- Returns products with stock <= threshold
- Includes stock status (Critical/Low/Adequate)
- Computes stock percentage of average

**Test 3: INSERT Operations**

Test InsertProductAsync:

```csharp
var newProduct = new Product
{
    Name = "Test Product",
    Description = "Test Description",
    Price = 99.99m,
    StockQuantity = 50
};

int newId = await repository.InsertProductAsync(newProduct);
```

Expected behavior:
- Product inserted successfully
- Returns new product ID
- Transaction commits successfully
- producthistory record created with action='INSERT'
- productstats updated (totalproducts incremented, averageprice recalculated)

**Validation queries:**
```sql
-- Verify product was inserted
SELECT * FROM products WHERE name = 'Test Product';

-- Verify history record
SELECT * FROM producthistory WHERE action = 'INSERT' ORDER BY actiondate DESC LIMIT 1;

-- Verify stats were updated
SELECT totalproducts, averageprice FROM productstats WHERE statid = 1;
```

**Test 4: UPDATE Operations**

Test UpdateProductAsync:

```csharp
var product = await repository.GetProductByIdAsync(1);
product.Price = 1399.99m;
product.StockQuantity = 20;

await repository.UpdateProductAsync(product);
```

Expected behavior:
- Product updated successfully
- modifieddate set to current timestamp
- producthistory record created with action='UPDATE', old and new values
- productstats updated (averageprice recalculated)

**Validation queries:**
```sql
-- Verify product was updated
SELECT * FROM products WHERE productid = 1;

-- Verify history record
SELECT * FROM producthistory WHERE productid = 1 AND action = 'UPDATE' ORDER BY actiondate DESC LIMIT 1;

-- Verify stats were updated
SELECT averageprice FROM productstats WHERE statid = 1;
```

**Test 5: DELETE Operations**

Test DeleteProductAsync:

```csharp
await repository.DeleteProductAsync(19); // Use the test product ID
```

Expected behavior:
- Product deleted successfully
- producthistory record created with action='DELETE', old values stored
- productstats updated (totalproducts decremented, averageprice recalculated)

**Validation queries:**
```sql
-- Verify product was deleted
SELECT COUNT(*) FROM products WHERE productid = 19; -- Should be 0

-- Verify history record
SELECT * FROM producthistory WHERE productid = 19 AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1;

-- Verify stats were updated
SELECT totalproducts, averageprice FROM productstats WHERE statid = 1;
```

**Pass Criteria for Criterion 13:**
- All SELECT operations return correct data
- INSERT creates new records with proper history and stats updates
- UPDATE modifies records with proper history and stats updates
- DELETE removes records with proper history and stats updates
- No SQL syntax errors
- All window functions execute correctly
- All CTEs execute correctly

### Criterion 14: Transaction Atomicity Test

Test that transaction blocks maintain ACID properties.

**Test 6: Successful Transaction Commit**

```csharp
// Insert a product - should commit successfully
var product = new Product
{
    Name = "Transaction Test 1",
    Description = "Should commit",
    Price = 199.99m,
    StockQuantity = 25
};

int newId = await repository.InsertProductAsync(product);
```

Expected behavior:
- All three operations commit together:
  1. INSERT into products
  2. INSERT into producthistory
  3. UPDATE productstats
- Product exists in database after transaction

**Validation:**
```sql
SELECT COUNT(*) FROM products WHERE name = 'Transaction Test 1'; -- Should be 1
SELECT COUNT(*) FROM producthistory WHERE productid = (SELECT productid FROM products WHERE name = 'Transaction Test 1'); -- Should be 1
```

**Test 7: Transaction Rollback on Error**

To test rollback, you need to force an error within a transaction:

```csharp
// Attempt to insert with a constraint violation or simulate error
// For example, try to update a non-existent product
try
{
    var product = new Product 
    { 
        ProductId = 99999, // Non-existent ID
        Name = "Transaction Test 2",
        Price = 299.99m,
        StockQuantity = 30
    };
    
    await repository.UpdateProductAsync(product);
}
catch (Exception ex)
{
    // Expected to throw exception
    Console.WriteLine($"Expected error: {ex.Message}");
}
```

Expected behavior:
- Exception thrown when product not found
- Transaction rolled back automatically
- No partial changes committed
- Database state unchanged

**Validation:**
```sql
-- No records should exist for the failed transaction
SELECT COUNT(*) FROM producthistory WHERE productid = 99999; -- Should be 0
```

**Test 8: Complex Multi-Statement Transaction**

Test the Update operation which performs multiple statements in a transaction:

```csharp
// This operation performs:
// 1. SELECT to get old values
// 2. UPDATE products
// 3. INSERT into producthistory
// 4. UPDATE productstats

var product = await repository.GetProductByIdAsync(1);
decimal oldPrice = product.Price;
int oldStock = product.StockQuantity;

product.Price = 1499.99m;
product.StockQuantity = 12;

await repository.UpdateProductAsync(product);
```

Expected behavior:
- All four operations commit atomically
- If any step fails, all steps roll back
- No partial updates visible to other connections

**Validation:**
```sql
-- Verify all changes were applied
SELECT price, stockquantity, modifieddate FROM products WHERE productid = 1;
-- modifieddate should be updated

SELECT oldprice, newprice, oldstock, newstock FROM producthistory 
WHERE productid = 1 AND action = 'UPDATE' 
ORDER BY actiondate DESC LIMIT 1;
-- Should show correct old and new values

SELECT averageprice FROM productstats WHERE statid = 1;
-- Should reflect the price change
```

**Pass Criteria for Criterion 14:**
- Successful transactions commit all statements
- Failed transactions roll back completely
- No partial updates occur
- Database maintains consistency
- Concurrent transactions properly isolated

### Criterion 15: Unit and Integration Tests

**Current Status:** No test files found in the codebase.

**Recommended Test Creation:**

Create test project:
```bash
cd /path/to/sourceCode
dotnet new xunit -n AdoCore.Tests
cd AdoCore.Tests
dotnet add reference ../AdoCore.csproj
dotnet add package Npgsql
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json
```

**Sample Integration Test:**

```csharp
using Xunit;
using AdoCore.DataAccess;
using AdoCore.Models;
using Microsoft.Extensions.Configuration;

public class ProductRepositoryIntegrationTests : IDisposable
{
    private readonly ProductRepository _repository;
    private readonly IConfiguration _configuration;

    public ProductRepositoryIntegrationTests()
    {
        _configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .Build();
        
        _repository = new ProductRepository(_configuration);
    }

    [Fact]
    public async Task GetAllProductsAsync_ShouldReturnProducts()
    {
        // Act
        var products = await _repository.GetAllProductsAsync();

        // Assert
        Assert.NotNull(products);
        Assert.True(products.Count > 0);
    }

    [Fact]
    public async Task GetProductByIdAsync_WithValidId_ShouldReturnProduct()
    {
        // Act
        var product = await _repository.GetProductByIdAsync(1);

        // Assert
        Assert.NotNull(product);
        Assert.Equal(1, product.ProductId);
    }

    [Fact]
    public async Task InsertProductAsync_ShouldCreateNewProduct()
    {
        // Arrange
        var newProduct = new Product
        {
            Name = "Test Product " + Guid.NewGuid(),
            Description = "Test Description",
            Price = 99.99m,
            StockQuantity = 50
        };

        // Act
        int newId = await _repository.InsertProductAsync(newProduct);

        // Assert
        Assert.True(newId > 0);
        
        // Cleanup
        await _repository.DeleteProductAsync(newId);
    }

    [Fact]
    public async Task UpdateProductAsync_ShouldUpdateProduct()
    {
        // Arrange - Create test product
        var product = new Product
        {
            Name = "Update Test " + Guid.NewGuid(),
            Description = "Original",
            Price = 100m,
            StockQuantity = 10
        };
        int productId = await _repository.InsertProductAsync(product);

        // Act - Update the product
        product.ProductId = productId;
        product.Description = "Updated";
        product.Price = 150m;
        await _repository.UpdateProductAsync(product);

        // Assert
        var updated = await _repository.GetProductByIdAsync(productId);
        Assert.Equal("Updated", updated.Description);
        Assert.Equal(150m, updated.Price);

        // Cleanup
        await _repository.DeleteProductAsync(productId);
    }

    [Fact]
    public async Task DeleteProductAsync_ShouldDeleteProduct()
    {
        // Arrange - Create test product
        var product = new Product
        {
            Name = "Delete Test " + Guid.NewGuid(),
            Description = "To be deleted",
            Price = 50m,
            StockQuantity = 5
        };
        int productId = await _repository.InsertProductAsync(product);

        // Act
        await _repository.DeleteProductAsync(productId);

        // Assert
        var deleted = await _repository.GetProductByIdAsync(productId);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task GetProductsByPriceRangeAsync_ShouldReturnFilteredProducts()
    {
        // Act
        var products = await _repository.GetProductsByPriceRangeAsync(100m, 500m);

        // Assert
        Assert.NotNull(products);
        Assert.All(products, p => 
        {
            Assert.InRange(p.Price, 100m, 500m);
        });
    }

    [Fact]
    public async Task GetLowStockProductsAsync_ShouldReturnLowStockProducts()
    {
        // Act
        var products = await _repository.GetLowStockProductsAsync(10);

        // Assert
        Assert.NotNull(products);
        Assert.All(products, p => 
        {
            Assert.True(p.StockQuantity <= 10);
        });
    }

    public async void Dispose()
    {
        await _repository.DisposeAsync();
    }
}
```

**Run tests:**
```bash
dotnet test
```

**Pass Criteria for Criterion 15:**
- All unit tests pass
- All integration tests pass
- Test coverage includes all repository methods
- Tests verify both success and failure scenarios

## Validation Summary

After completing all tests, document results:

### Criterion 12: Database Connection
- [ ] Application connects successfully
- [ ] Connection string parameters correct
- [ ] No connection exceptions

### Criterion 13: Database Operations
- [ ] GetAllProductsAsync works correctly
- [ ] GetProductByIdAsync works correctly
- [ ] InsertProductAsync works correctly
- [ ] UpdateProductAsync works correctly
- [ ] DeleteProductAsync works correctly
- [ ] GetProductsByPriceRangeAsync works correctly
- [ ] GetLowStockProductsAsync works correctly
- [ ] All SQL statements execute without errors
- [ ] All window functions work correctly
- [ ] All CTEs work correctly

### Criterion 14: Transaction Atomicity
- [ ] Successful transactions commit all statements
- [ ] Failed transactions roll back completely
- [ ] No partial updates occur
- [ ] Database maintains ACID properties

### Criterion 15: Tests
- [ ] Unit tests exist and pass
- [ ] Integration tests exist and pass
- [ ] All repository methods covered
- [ ] Test coverage adequate

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to PostgreSQL
```
Npgsql.NpgsqlException: Failed to connect to server
```

**Solution:**
1. Verify PostgreSQL is running: `systemctl status postgresql` (Linux) or `docker ps` (Docker)
2. Check connection string parameters match your setup
3. Verify PostgreSQL accepts connections: `psql -U postgres -h localhost`
4. Check `pg_hba.conf` allows password authentication
5. Verify firewall allows port 5432

### SQL Syntax Errors

**Problem:** SQL statement fails with syntax error

**Solution:**
1. Verify the converted SQL statement is valid PostgreSQL syntax
2. Check that all table/column names are lowercase
3. Ensure PostgreSQL-specific functions are used correctly
4. Review the converted_statements.sql file for the correct syntax

### Transaction Errors

**Problem:** Transaction deadlock or timeout

**Solution:**
1. Close all connections properly
2. Ensure transactions are committed or rolled back
3. Check for long-running transactions
4. Review transaction isolation level if needed

### Performance Issues

**Problem:** Queries are slow

**Solution:**
1. Run `ANALYZE` on tables to update statistics
2. Verify indexes are created (check with `\di`)
3. Use `EXPLAIN ANALYZE` to identify bottlenecks
4. Consider adding additional indexes if needed

## Conclusion

This guide provides comprehensive instructions for validating the migrated AdoCore application against PostgreSQL. Follow each section systematically and document results for each criterion.

For any issues encountered, refer to the Troubleshooting section or review the transformation artifacts:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `dms_conversion_log.txt` - DMS conversion log
