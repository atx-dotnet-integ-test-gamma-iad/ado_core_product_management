# PostgreSQL Migration - Runtime Testing Guide

## Overview
This guide provides instructions for completing the runtime validation of the PostgreSQL migration. Several exit criteria require an actual PostgreSQL database instance for verification.

## Prerequisites

### 1. PostgreSQL Installation
Ensure PostgreSQL is installed and running:
```bash
# Check PostgreSQL status
psql --version
pg_isready

# On macOS with Homebrew
brew services start postgresql

# On Linux (systemd)
sudo systemctl start postgresql
sudo systemctl status postgresql

# On Windows
# Start PostgreSQL service via Services management console
```

### 2. Database Schema Setup
The migration uses lowercase schema naming. Create the required tables:

```sql
-- Connect to PostgreSQL
psql -U postgres

-- Create database
CREATE DATABASE "ProductManagement";

-- Connect to the database
\c ProductManagement

-- Create products table
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createdat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create product history table
CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    oldprice DECIMAL(18, 2),
    newprice DECIMAL(18, 2),
    changedat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (productid) REFERENCES products(productid)
);

-- Create product statistics table
CREATE TABLE productstats (
    statid SERIAL PRIMARY KEY,
    totalproducts INTEGER NOT NULL,
    totaldeletions INTEGER NOT NULL,
    lastupdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialize statistics
INSERT INTO productstats (totalproducts, totaldeletions, lastupdated)
VALUES (0, 0, CURRENT_TIMESTAMP);

-- Insert sample test data
INSERT INTO products (name, price, stockquantity) VALUES
    ('Product A', 10.50, 100),
    ('Product B', 25.75, 50),
    ('Product C', 15.00, 75),
    ('Product D', 30.00, 25),
    ('Product E', 8.99, 150);

-- Verify data
SELECT * FROM products;
SELECT * FROM producthistory;
SELECT * FROM productstats;
```

## Exit Criteria Testing

### Criterion 12: Database Connection Testing

**Objective**: Verify the application successfully connects to PostgreSQL.

**Test Steps**:
1. Update `appsettings.json` with correct connection string (or use environment variables)
2. Run the application:
   ```bash
   cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
   dotnet run
   ```
3. Check for successful startup without connection errors
4. Observe connection pooling behavior

**Expected Result**: Application starts without connection exceptions.

**Validation Evidence**:
- [ ] Application connects successfully
- [ ] No connection timeout or authentication errors
- [ ] Connection string parameters work correctly

---

### Criterion 13: Database Operations Testing

**Objective**: Verify all database operations (SELECT, INSERT, UPDATE, DELETE) execute successfully.

#### Test 13.1: GetAllProductsAsync()
```bash
# Run the application and select option to view all products
dotnet run
# Select: View All Products
```

**Validation**:
- [ ] Query executes without errors
- [ ] CTE (Common Table Expression) works correctly
- [ ] Window functions (ROW_NUMBER, RANK) produce correct results
- [ ] All products are displayed with proper formatting

#### Test 13.2: GetProductByIdAsync()
```bash
# Run the application and select option to view product by ID
dotnet run
# Select: View Product By ID
# Enter ID: 1
```

**Validation**:
- [ ] Query executes without errors
- [ ] LAG window function works correctly
- [ ] Previous price is calculated and displayed
- [ ] Product details are accurate

#### Test 13.3: InsertProductAsync()
```bash
# Run the application and select option to add product
dotnet run
# Select: Add New Product
# Enter: Name="Test Product", Price=19.99, Stock=50
```

**Validation**:
- [ ] INSERT executes without errors
- [ ] RETURNING clause returns correct productid
- [ ] New product appears in subsequent queries
- [ ] Timestamp fields are populated correctly

#### Test 13.4: UpdateProductAsync()
```bash
# Run the application and select option to update product
dotnet run
# Select: Update Product
# Enter: ID=1, Name="Updated Product", Price=12.50, Stock=80
```

**Validation**:
- [ ] UPDATE executes without errors
- [ ] Product data is updated correctly
- [ ] History record is created in producthistory table
- [ ] updatedat timestamp is updated

**Verify History**:
```sql
SELECT * FROM producthistory WHERE productid = 1 ORDER BY changedat DESC LIMIT 1;
```

#### Test 13.5: DeleteProductAsync()
```bash
# Run the application and select option to delete product
dotnet run
# Select: Delete Product
# Enter: ID=5
```

**Validation**:
- [ ] DELETE executes without errors
- [ ] Product is removed from products table
- [ ] Statistics are updated in productstats table
- [ ] No orphaned records remain

**Verify Statistics**:
```sql
SELECT * FROM productstats;
```

#### Test 13.6: GetProductsByPriceRangeAsync()
```bash
# Run the application and select option to search by price range
dotnet run
# Select: Get Products by Price Range
# Enter: MinPrice=10.00, MaxPrice=30.00
```

**Validation**:
- [ ] Query executes without errors
- [ ] RANK() and PERCENT_RANK() functions work correctly
- [ ] Only products within price range are returned
- [ ] Rankings are calculated correctly

#### Test 13.7: GetLowStockProductsAsync()
```bash
# Run the application and select option to view low stock products
dotnet run
# Select: Get Low Stock Products
# Enter: Threshold=60
```

**Validation**:
- [ ] Query executes without errors
- [ ] Window functions (AVG, MIN, MAX) over category work correctly
- [ ] Only products below threshold are returned
- [ ] Statistics are calculated accurately

---

### Criterion 14: Transaction Atomicity Testing

**Objective**: Verify transaction blocks maintain ACID properties.

#### Test 14.1: InsertProductAsync() Rollback
Create a test that forces a failure after INSERT:
```csharp
// Temporarily modify InsertProductAsync to simulate error after insert
// Add: throw new Exception("Test rollback");
// After the INSERT but before commit
```

**Validation**:
- [ ] Transaction rolls back on error
- [ ] No partial data is committed
- [ ] Database state remains consistent
- [ ] Error is properly caught and reported

#### Test 14.2: UpdateProductAsync() Rollback
```csharp
// Temporarily modify UpdateProductAsync to simulate error
// Add: throw new Exception("Test rollback");
// After UPDATE but before history insert
```

**Validation**:
- [ ] Transaction rolls back completely
- [ ] Original product data remains unchanged
- [ ] No history record is created
- [ ] Database state is consistent

#### Test 14.3: DeleteProductAsync() Rollback
```csharp
// Temporarily modify DeleteProductAsync to simulate error
// Add: throw new Exception("Test rollback");
// After DELETE but before stats update
```

**Validation**:
- [ ] Transaction rolls back completely
- [ ] Product is not deleted
- [ ] Statistics are not updated
- [ ] Database state is consistent

#### Test 14.4: Concurrent Transaction Testing
Run two instances of the application simultaneously and perform conflicting updates:

**Validation**:
- [ ] Transaction isolation is maintained
- [ ] No dirty reads occur
- [ ] No lost updates occur
- [ ] Proper locking behavior

---

### Criterion 15: Test Suite Development and Execution

**Objective**: Create and execute comprehensive tests.

#### Create Unit Tests Project
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet new xunit -n AdoCore.Tests
cd AdoCore.Tests
dotnet add reference ../AdoCore.csproj
dotnet add package Npgsql
dotnet add package Moq
dotnet add package FluentAssertions
```

#### Sample Unit Test Structure
```csharp
using Xunit;
using FluentAssertions;
using AdoCore.DataAccess;
using AdoCore.Models;

namespace AdoCore.Tests
{
    public class ProductRepositoryTests : IDisposable
    {
        private readonly string _testConnectionString;
        private readonly ProductRepository _repository;

        public ProductRepositoryTests()
        {
            _testConnectionString = "Host=localhost;Database=ProductManagement_Test;Username=postgres;Password=postgres;Port=5432";
            _repository = new ProductRepository();
            // Setup test database
        }

        [Fact]
        public async Task GetAllProductsAsync_ShouldReturnProducts()
        {
            // Arrange - Insert test data
            
            // Act
            var products = await _repository.GetAllProductsAsync();
            
            // Assert
            products.Should().NotBeNull();
            products.Should().NotBeEmpty();
        }

        [Fact]
        public async Task InsertProductAsync_ShouldReturnProductId()
        {
            // Arrange
            var product = new Product 
            { 
                Name = "Test Product", 
                Price = 19.99m, 
                StockQuantity = 50 
            };
            
            // Act
            var productId = await _repository.InsertProductAsync(product);
            
            // Assert
            productId.Should().BeGreaterThan(0);
        }

        // Add more tests for each method...

        public void Dispose()
        {
            // Cleanup test data
        }
    }
}
```

#### Run Tests
```bash
dotnet test
```

**Validation**:
- [ ] All unit tests pass
- [ ] Code coverage is adequate (>80% recommended)
- [ ] Integration tests with PostgreSQL pass
- [ ] Performance tests meet requirements

---

## Validation Checklist

After completing all runtime tests, verify:

### Criterion 12: Connection Testing
- [ ] Application connects successfully to PostgreSQL
- [ ] Connection pooling works correctly
- [ ] No authentication or timeout errors

### Criterion 13: Database Operations
- [ ] GetAllProductsAsync() executes successfully
- [ ] GetProductByIdAsync() executes successfully
- [ ] InsertProductAsync() executes successfully with RETURNING clause
- [ ] UpdateProductAsync() executes successfully with history logging
- [ ] DeleteProductAsync() executes successfully with statistics updates
- [ ] GetProductsByPriceRangeAsync() executes successfully
- [ ] GetLowStockProductsAsync() executes successfully
- [ ] All window functions work correctly
- [ ] All CTEs work correctly

### Criterion 14: Transaction Testing
- [ ] Insert transactions roll back on error
- [ ] Update transactions roll back on error
- [ ] Delete transactions roll back on error
- [ ] Transaction isolation is maintained
- [ ] No data corruption occurs

### Criterion 15: Test Suite
- [ ] Unit tests created for all repository methods
- [ ] Integration tests created for database operations
- [ ] All tests pass successfully
- [ ] Test coverage is adequate

---

## Troubleshooting

### Connection Issues
```sql
-- Check PostgreSQL is listening
SELECT * FROM pg_stat_activity;

-- Check user permissions
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
```

### Schema Issues
```sql
-- Verify table names are lowercase
\dt

-- Check column names
\d products
\d producthistory
\d productstats
```

### Performance Issues
```sql
-- Create indexes for better performance
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_stockquantity ON products(stockquantity);
CREATE INDEX idx_producthistory_productid ON producthistory(productid);
```

---

## Reporting Results

After completing all tests, document results in the validation summary:

1. Update each criterion status (PASS/FAIL)
2. Provide evidence (logs, screenshots, query results)
3. Document any issues encountered and resolutions
4. Include performance metrics if applicable

---

## Next Steps After Validation

Once all runtime tests pass:
1. ✅ Update validation_summary.md with test results
2. ✅ Review and address any security recommendations
3. ✅ Plan for production deployment
4. ✅ Setup monitoring and alerting
5. ✅ Document operational procedures
