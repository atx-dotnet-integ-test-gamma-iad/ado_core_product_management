# PostgreSQL Migration Testing Guide

## Overview
This guide provides step-by-step instructions for completing the remaining validation criteria (12-15) that require runtime access to a PostgreSQL database. The code-level migration is complete and the application compiles successfully. This testing phase validates that the application works correctly with PostgreSQL at runtime.

## Prerequisites

### Required Software
- **PostgreSQL 13 or higher** (version 15 recommended)
- **.NET 9.0 SDK** (already verified - application compiles)
- **pgAdmin 4** or **psql CLI** (for database management)

### Installation Options

#### Option 1: Local PostgreSQL Installation
**Windows:**
```bash
# Download from https://www.postgresql.org/download/windows/
# Or use winget
winget install PostgreSQL.PostgreSQL
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

#### Option 2: Docker PostgreSQL
```bash
# Pull and run PostgreSQL in Docker
docker run --name adocore-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Verify running
docker ps | grep adocore-postgres
```

#### Option 3: AWS RDS PostgreSQL
1. Navigate to AWS RDS Console
2. Create PostgreSQL database instance (version 13+)
3. Configure security group to allow your IP
4. Note the endpoint and credentials

## Step-by-Step Testing Instructions

### Phase 1: Database Setup and Schema Creation

#### Step 1.1: Create PostgreSQL Database
```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Create database
CREATE DATABASE "ProductManagement";

# Connect to the database
\c ProductManagement
```

#### Step 1.2: Execute Schema Setup Script
```bash
# Option A: From psql
\i Database/Scripts/02_PostgreSQL_Setup.sql

# Option B: From command line
psql -U postgres -d ProductManagement -f Database/Scripts/02_PostgreSQL_Setup.sql

# Option C: Using pgAdmin
# Open pgAdmin -> Connect to server -> Open Query Tool -> Load 02_PostgreSQL_Setup.sql -> Execute
```

#### Step 1.3: Verify Schema Creation
```sql
-- Check schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'productmanagement_dbo';

-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'productmanagement_dbo'
ORDER BY table_name;

-- Expected tables:
-- categories, producthistory, products, productstats, suppliers

-- Check sample data loaded
SELECT COUNT(*) as product_count FROM productmanagement_dbo.products;
-- Expected: 18 products

SELECT COUNT(*) as category_count FROM productmanagement_dbo.categories;
-- Expected: 20 categories

SELECT COUNT(*) as supplier_count FROM productmanagement_dbo.suppliers;
-- Expected: 8 suppliers
```

### Phase 2: Configure Application Connection String

#### Step 2.1: Update appsettings.json
Edit `sourceCode/appsettings.json` with your actual PostgreSQL credentials:

**For Local PostgreSQL:**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_ACTUAL_PASSWORD;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_ACTUAL_PASSWORD;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Development"
}
```

**For Docker PostgreSQL:**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
  },
  "Environment": "Development"
}
```

**For AWS RDS PostgreSQL:**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=your-rds-endpoint.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_RDS_PASSWORD;Pooling=true;SSL Mode=Require",
    "ProdConnection": "Host=your-rds-endpoint.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_RDS_PASSWORD;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Development"
}
```

### Phase 3: Test Database Connectivity (Exit Criterion 12)

#### Test 3.1: Basic Connection Test
```bash
cd sourceCode
dotnet run -- list
```

**Expected Output:**
- Application connects successfully
- Lists all products from database
- No connection errors

**Validation:**
✅ **Exit Criterion 12 PASSED** if:
- Connection established without errors
- Data retrieved from PostgreSQL database
- No authentication or connection timeout issues

**Common Issues:**
- `Connection refused`: Check PostgreSQL is running (`sudo systemctl status postgresql` or `docker ps`)
- `Authentication failed`: Verify username/password in appsettings.json
- `Database does not exist`: Run Step 1.2 schema setup script
- `SSL connection error`: Add `SSL Mode=Prefer` or `SSL Mode=Disable` to connection string for local testing

### Phase 4: Test Database Operations (Exit Criterion 13)

#### Test 4.1: SELECT Operations
```bash
# Test GetAllProductsAsync - Complex CTE with window functions
dotnet run -- list

# Test GetProductByIdAsync - CTE with LAG window function
dotnet run -- get 1

# Test GetProductsByPriceRangeAsync - RANK and PERCENT_RANK window functions
# (Requires interactive mode to test)
dotnet run
# Select option for price range search
```

**Expected Results:**
- All products listed with correct data
- Individual product retrieved successfully
- Price range queries return filtered results
- Window functions (RANK, PERCENT_RANK, LAG) work correctly

#### Test 4.2: INSERT Operations
```bash
# Test InsertProductAsync - Multi-statement transaction with RETURNING
dotnet run -- add "Test Product Migration" 99.99 50 "PostgreSQL migration test product"
```

**Expected Results:**
- New product inserted successfully
- Returns new ProductId (auto-generated by PostgreSQL sequence)
- producthistory record created
- productstats updated
- All three statements in transaction execute atomically

**Verification:**
```sql
-- Check product was inserted
SELECT * FROM productmanagement_dbo.products 
WHERE name = 'Test Product Migration';

-- Check history was logged
SELECT * FROM productmanagement_dbo.producthistory 
WHERE action = 'INSERT' 
ORDER BY actiondate DESC LIMIT 1;

-- Check stats were updated
SELECT * FROM productmanagement_dbo.productstats WHERE statid = 1;
```

#### Test 4.3: UPDATE Operations
```bash
# Test UpdateProductAsync - Multi-statement transaction
dotnet run -- update 1 "Updated Product Name" 199.99 100 "Updated description"
```

**Expected Results:**
- Product updated successfully
- Old values captured in producthistory
- productstats recalculated
- modifieddate set to current timestamp

**Verification:**
```sql
-- Check product was updated
SELECT name, price, stockquantity, modifieddate 
FROM productmanagement_dbo.products 
WHERE productid = 1;

-- Check history was logged
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = 1 AND action = 'UPDATE' 
ORDER BY actiondate DESC LIMIT 1;
```

#### Test 4.4: DELETE Operations
```bash
# Test DeleteProductAsync - Multi-statement transaction
# First, get the ID of the test product created in 4.2
dotnet run -- list
# Note the ProductId of "Test Product Migration"

# Delete it
dotnet run -- delete <ProductId>
```

**Expected Results:**
- Product deleted successfully
- History logged before deletion
- productstats updated
- Foreign key constraints respected

**Verification:**
```sql
-- Verify product deleted
SELECT * FROM productmanagement_dbo.products 
WHERE name = 'Test Product Migration';
-- Should return no rows

-- Verify history logged
SELECT * FROM productmanagement_dbo.producthistory 
WHERE action = 'DELETE' 
ORDER BY actiondate DESC LIMIT 1;
```

#### Test 4.5: Complex Queries with Window Functions
```bash
# Test GetLowStockProductsAsync - Window functions with CASE
# (Requires interactive mode or code modification to test)
```

**Validation:**
✅ **Exit Criterion 13 PASSED** if:
- All SELECT operations return correct data
- All INSERT operations create records successfully
- All UPDATE operations modify records correctly
- All DELETE operations remove records properly
- Complex SQL features work (CTEs, window functions, CASE expressions)
- Schema object names match DMS conversions (lowercase, productmanagement_dbo schema)

### Phase 5: Test Transaction Atomicity (Exit Criterion 14)

#### Test 5.1: Transaction Rollback on Insert Failure
Create a test to intentionally fail a transaction:

**Option A: Invalid data type (triggers constraint violation)**
```sql
-- Temporarily add constraint to test rollback
ALTER TABLE productmanagement_dbo.products 
ADD CONSTRAINT chk_price_positive CHECK (price > 0);

-- Now try to insert with negative price via app
-- This should trigger rollback
```

```bash
# This should fail and rollback entire transaction
dotnet run -- add "Invalid Product" -10.00 5 "Negative price test"
```

**Expected Result:**
- Transaction fails with constraint violation
- No product inserted
- No producthistory record created
- No productstats updated
- All statements rolled back atomically

**Verification:**
```sql
-- Verify nothing was committed
SELECT * FROM productmanagement_dbo.products WHERE name = 'Invalid Product';
-- Should return no rows

SELECT * FROM productmanagement_dbo.producthistory 
WHERE actiondate > NOW() - INTERVAL '1 minute';
-- Should not show the failed insert attempt

-- Clean up constraint
ALTER TABLE productmanagement_dbo.products DROP CONSTRAINT chk_price_positive;
```

#### Test 5.2: Transaction Rollback on Update Failure
```bash
# Try to update non-existent product (should fail gracefully)
dotnet run -- update 99999 "Does Not Exist" 100.00 10 "Test"
```

**Expected Result:**
- Update fails (no rows affected)
- No producthistory record created
- No productstats updated
- Transaction rolled back

#### Test 5.3: Transaction Rollback on Delete Failure
```bash
# Try to delete non-existent product
dotnet run -- delete 99999
```

**Expected Result:**
- Delete fails (no rows affected)
- No producthistory record created
- Transaction rolled back

#### Test 5.4: Successful Transaction Commit
```bash
# Insert, update, then verify all parts committed
dotnet run -- add "Transaction Test" 75.00 25 "Testing atomicity"
# Note the new ProductId returned

# Update it
dotnet run -- update <ProductId> "Transaction Test Updated" 80.00 30 "Testing atomicity updated"

# Verify both operations committed
```

**Verification:**
```sql
-- Should see both INSERT and UPDATE in history
SELECT action, oldprice, newprice, oldstock, newstock 
FROM productmanagement_dbo.producthistory 
WHERE productid = <ProductId>
ORDER BY actiondate;
-- Expected: Two rows (INSERT and UPDATE)
```

**Validation:**
✅ **Exit Criterion 14 PASSED** if:
- Failed transactions roll back all statements (no partial commits)
- Successful transactions commit all statements atomically
- producthistory and productstats remain consistent
- No orphaned or incomplete data after rollbacks

### Phase 6: Test Suite Execution (Exit Criterion 15)

#### Step 6.1: Check for Existing Tests
```bash
# Search for test projects
find . -name "*Test*.csproj" -o -name "*.Tests.csproj"

# Search for test files
find . -name "*Test*.cs" -o -name "*Tests.cs"
```

**Current Status:** No existing test files identified in the repository.

#### Step 6.2: Create Integration Test Project (Recommended)
```bash
# Navigate to solution directory
cd sourceCode

# Create test project
dotnet new xunit -n AdoCore.IntegrationTests

# Add reference to main project
cd AdoCore.IntegrationTests
dotnet add reference ../AdoCore.csproj

# Add required packages
dotnet add package Npgsql
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json

# Add to solution
cd ..
dotnet sln AdoCore.sln add AdoCore.IntegrationTests/AdoCore.IntegrationTests.csproj
```

#### Step 6.3: Sample Integration Test Template
Create `AdoCore.IntegrationTests/ProductRepositoryIntegrationTests.cs`:

```csharp
using System;
using System.Threading.Tasks;
using Xunit;
using Microsoft.Extensions.Configuration;
using AdoCore.DataAccess;
using AdoCore.Models;

namespace AdoCore.IntegrationTests
{
    public class ProductRepositoryIntegrationTests : IAsyncDisposable
    {
        private readonly ProductRepository _repository;
        private readonly IConfiguration _configuration;

        public ProductRepositoryIntegrationTests()
        {
            _configuration = new ConfigurationBuilder()
                .SetBasePath(AppContext.BaseDirectory)
                .AddJsonFile("appsettings.json", optional: false)
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
            Assert.NotEmpty(products);
        }

        [Fact]
        public async Task GetProductByIdAsync_WithValidId_ShouldReturnProduct()
        {
            // Arrange
            int productId = 1;

            // Act
            var product = await _repository.GetProductByIdAsync(productId);

            // Assert
            Assert.NotNull(product);
            Assert.Equal(productId, product.ProductId);
        }

        [Fact]
        public async Task InsertUpdateDeleteProduct_ShouldWorkCorrectly()
        {
            // Arrange
            var newProduct = new Product
            {
                Name = "Integration Test Product",
                Description = "Created by integration test",
                Price = 99.99m,
                StockQuantity = 10
            };

            // Act - Insert
            int newId = await _repository.InsertProductAsync(newProduct);
            Assert.True(newId > 0);

            // Act - Get
            var retrieved = await _repository.GetProductByIdAsync(newId);
            Assert.NotNull(retrieved);
            Assert.Equal(newProduct.Name, retrieved.Name);

            // Act - Update
            retrieved.Price = 149.99m;
            retrieved.StockQuantity = 20;
            await _repository.UpdateProductAsync(retrieved);

            var updated = await _repository.GetProductByIdAsync(newId);
            Assert.Equal(149.99m, updated.Price);
            Assert.Equal(20, updated.StockQuantity);

            // Act - Delete
            await _repository.DeleteProductAsync(newId);
            var deleted = await _repository.GetProductByIdAsync(newId);
            Assert.Null(deleted);
        }

        [Fact]
        public async Task GetProductsByPriceRangeAsync_ShouldReturnFilteredProducts()
        {
            // Act
            var products = await _repository.GetProductsByPriceRangeAsync(100.00m, 500.00m);

            // Assert
            Assert.NotNull(products);
            Assert.All(products, p => 
            {
                Assert.InRange(p.Price, 100.00m, 500.00m);
            });
        }

        [Fact]
        public async Task GetLowStockProductsAsync_ShouldReturnLowStockProducts()
        {
            // Act
            var products = await _repository.GetLowStockProductsAsync(15);

            // Assert
            Assert.NotNull(products);
            Assert.All(products, p => 
            {
                Assert.True(p.StockQuantity <= 15);
            });
        }

        public async ValueTask DisposeAsync()
        {
            await _repository.DisposeAsync();
        }
    }
}
```

#### Step 6.4: Run Integration Tests
```bash
# Build test project
cd AdoCore.IntegrationTests
dotnet build

# Run all tests
dotnet test

# Run with verbose output
dotnet test --logger "console;verbosity=detailed"

# Run specific test
dotnet test --filter "FullyQualifiedName~GetAllProductsAsync"
```

**Expected Results:**
- All tests pass
- Database operations execute successfully
- No connection or SQL syntax errors

**Validation:**
✅ **Exit Criterion 15 PASSED** if:
- All created tests pass successfully
- Tests cover all repository methods
- Tests verify transaction behavior
- Tests confirm PostgreSQL compatibility

**Note:** If no tests are created, document that testing framework needs to be established as a post-migration task.

## Validation Summary Checklist

After completing all phases, verify the following:

### ✅ Exit Criterion 12: Database Connectivity
- [ ] Application connects to PostgreSQL database
- [ ] No authentication errors
- [ ] Connection pooling works correctly
- [ ] SSL/TLS configuration (if required) works

### ✅ Exit Criterion 13: Database Operations
- [ ] SELECT queries return correct data
- [ ] INSERT operations create records with correct IDs
- [ ] UPDATE operations modify records correctly
- [ ] DELETE operations remove records properly
- [ ] Complex SQL features work (CTEs, window functions, CASE, JOINs)
- [ ] Schema names match DMS conversions (lowercase, productmanagement_dbo)

### ✅ Exit Criterion 14: Transaction Atomicity
- [ ] Failed transactions roll back completely
- [ ] Successful transactions commit atomically
- [ ] No partial commits on errors
- [ ] producthistory remains consistent
- [ ] productstats updated correctly

### ✅ Exit Criterion 15: Test Suite
- [ ] Integration tests created (or documented as needed)
- [ ] All tests pass against PostgreSQL
- [ ] Test coverage includes all repository methods
- [ ] Transaction tests verify atomicity

## Troubleshooting Common Issues

### Issue: "Npgsql.PostgresException: relation does not exist"
**Solution:** Schema prefix missing or incorrect case. PostgreSQL schema objects are lowercase.
```csharp
// Incorrect (uppercase)
SELECT * FROM Products

// Correct (lowercase with schema)
SELECT * FROM productmanagement_dbo.products
```

### Issue: "column does not exist"
**Solution:** Column names are lowercase in PostgreSQL.
```csharp
// Incorrect
SELECT ProductId, Name FROM products

// Correct
SELECT productid, name FROM products
```

### Issue: "Connection refused"
**Solution:** PostgreSQL not running or wrong port.
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql
# or
docker ps | grep postgres

# Check port
netstat -an | grep 5432
```

### Issue: "SSL connection required"
**Solution:** Add SSL mode to connection string.
```json
"Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=yourpassword;SSL Mode=Disable"
```

### Issue: Transaction deadlock
**Solution:** Ensure proper transaction isolation and connection management.
- Each operation should use the same connection within a transaction
- Commit or rollback transactions promptly
- Avoid nested transactions

## Performance Benchmarking (Optional)

To compare SQL Server vs PostgreSQL performance:

```bash
# Use Apache Bench or similar tool
# Measure response times for operations
time dotnet run -- list

# Run multiple operations and measure
for i in {1..10}; do
  dotnet run -- add "Perf Test $i" 50.00 10 "Performance testing"
done
```

## Final Report Generation

After completing all tests, document results in the format:

```markdown
## Runtime Validation Results

### Exit Criterion 12: Database Connectivity
Status: PASS/FAIL
Evidence: [Connection log, screenshots, error messages]
Notes: [Any configuration changes needed]

### Exit Criterion 13: Database Operations  
Status: PASS/FAIL
Evidence: [Query results, operation logs]
Tested Operations:
- GetAllProductsAsync: PASS/FAIL
- GetProductByIdAsync: PASS/FAIL
- InsertProductAsync: PASS/FAIL
- UpdateProductAsync: PASS/FAIL
- DeleteProductAsync: PASS/FAIL
- GetProductsByPriceRangeAsync: PASS/FAIL
- GetLowStockProductsAsync: PASS/FAIL

### Exit Criterion 14: Transaction Atomicity
Status: PASS/FAIL
Evidence: [Transaction logs, rollback verification]
Tested Scenarios:
- Insert transaction rollback: PASS/FAIL
- Update transaction rollback: PASS/FAIL
- Delete transaction rollback: PASS/FAIL
- Successful transaction commit: PASS/FAIL

### Exit Criterion 15: Test Suite Execution
Status: PASS/FAIL/NOT_APPLICABLE
Evidence: [Test results, coverage report]
Notes: [If tests not created, document reason]
```

## Contact and Support

For issues or questions:
1. Check PostgreSQL logs: `/var/log/postgresql/postgresql-*.log`
2. Check application logs in console output
3. Review transformation artifacts in project root
4. Consult PostgreSQL documentation: https://www.postgresql.org/docs/

## Conclusion

This testing guide provides comprehensive instructions for validating the remaining exit criteria. Once all phases are completed successfully, the migration from SQL Server to PostgreSQL is fully validated and the application is ready for production deployment.
