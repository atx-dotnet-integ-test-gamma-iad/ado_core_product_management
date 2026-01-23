# Runtime Testing Guide

## Overview
This guide provides instructions for runtime testing of the migrated PostgreSQL application. The transformation has completed all static code migration tasks, but runtime testing requires a live PostgreSQL database environment.

## Prerequisites

### 1. PostgreSQL Database Setup
You need a PostgreSQL database instance (version 12 or later recommended) with the following schema:

#### Required Tables

```sql
-- Products table
CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Price DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL,
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);

-- ProductHistory table (for audit logging)
CREATE TABLE ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INT NOT NULL,
    Action VARCHAR(50) NOT NULL,
    OldPrice DECIMAL(18,2),
    NewPrice DECIMAL(18,2),
    OldStock INT,
    NewStock INT,
    ActionDate TIMESTAMP NOT NULL,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

-- ProductStats table (for aggregate statistics)
CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY,
    TotalProducts INT DEFAULT 0,
    AveragePrice DECIMAL(18,2) DEFAULT 0,
    LastUpdated TIMESTAMP
);

-- Initialize stats
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP);
```

#### Sample Data (Optional)

```sql
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES 
    ('Laptop', 'High performance laptop', 1299.99, 15),
    ('Mouse', 'Wireless mouse', 29.99, 50),
    ('Keyboard', 'Mechanical keyboard', 89.99, 30),
    ('Monitor', '27-inch 4K monitor', 449.99, 10),
    ('Headphones', 'Noise-cancelling headphones', 199.99, 25);

-- Update stats
UPDATE ProductStats
SET 
    TotalProducts = 5,
    AveragePrice = (1299.99 + 29.99 + 89.99 + 449.99 + 199.99) / 5,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;
```

### 2. Update Connection String
Edit `appsettings.json` or set environment variables with your PostgreSQL connection details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=YOUR_HOST;Database=YOUR_DATABASE;Username=YOUR_USER;Password=YOUR_PASSWORD;Port=5432"
  },
  "Environment": "Development"
}
```

Or use environment variables:
```bash
export ConnectionStrings__DevConnection="Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Port=5432"
```

## Testing Exit Criteria

### Criterion 12: Database Connectivity Testing

**Objective**: Verify the application successfully connects to PostgreSQL database

**Test Steps**:
1. Ensure PostgreSQL is running and accessible
2. Verify connection string is correct
3. Run the application:
   ```bash
   cd sourceCode
   dotnet run
   ```
4. Observe the startup logs for connection success
5. Select any menu option that requires database access

**Expected Result**: 
- No connection errors
- Application successfully opens connection to PostgreSQL
- No SQL Server specific error messages

**Pass Criteria**: Application connects without errors

---

### Criterion 13: Database Operations Testing

**Objective**: Verify all database operations execute successfully against PostgreSQL

**Test Cases**:

#### Test 13.1: GetAllProductsAsync
```bash
# Run application and select option to view all products
dotnet run
# Select: 1 (View All Products)
```
**Expected**: List of products with price categories and statistics

#### Test 13.2: GetProductByIdAsync
```bash
# Run application and select option to view product by ID
dotnet run
# Select: 2 (View Product by ID)
# Enter a valid ProductId
```
**Expected**: Single product with history and price change percentage

#### Test 13.3: InsertProductAsync
```bash
# Run application and select option to insert product
dotnet run
# Select: 3 (Insert New Product)
# Enter product details
```
**Expected**: 
- New product inserted
- ProductHistory record created with 'INSERT' action
- ProductStats updated with new totals

#### Test 13.4: UpdateProductAsync
```bash
# Run application and select option to update product
dotnet run
# Select: 4 (Update Product)
# Enter ProductId and new details
```
**Expected**:
- Product updated
- ProductHistory record created with 'UPDATE' action
- ProductStats updated with new averages

#### Test 13.5: DeleteProductAsync
```bash
# Run application and select option to delete product
dotnet run
# Select: 5 (Delete Product)
# Enter ProductId
```
**Expected**:
- Product deleted
- ProductHistory record created with 'DELETE' action
- ProductStats updated with decremented totals

#### Test 13.6: GetProductsByPriceRangeAsync
```bash
# Run application and select option to filter by price
dotnet run
# Select: 6 (View Products by Price Range)
# Enter min and max price
```
**Expected**: Products within price range with rank and percentile data

#### Test 13.7: GetLowStockProductsAsync
```bash
# Run application and select option to view low stock
dotnet run
# Select: 7 (View Low Stock Products)
# Enter threshold
```
**Expected**: Products with stock below threshold, with stock analysis

**Pass Criteria**: All 7 methods execute without errors and return expected results

---

### Criterion 14: Transaction Atomicity Testing

**Objective**: Verify transaction blocks maintain ACID properties

**Test Cases**:

#### Test 14.1: Successful Transaction Commit
1. Insert a new product (InsertProductAsync)
2. Verify all three operations completed:
   - Product inserted in Products table
   - History record in ProductHistory table
   - Stats updated in ProductStats table
3. Query database to confirm all changes persisted

**SQL Verification**:
```sql
-- Check product exists
SELECT * FROM Products WHERE ProductId = <new_id>;

-- Check history record
SELECT * FROM ProductHistory WHERE ProductId = <new_id> AND Action = 'INSERT';

-- Check stats updated
SELECT TotalProducts FROM ProductStats WHERE StatId = 1;
```

#### Test 14.2: Transaction Rollback on Error
1. Modify ProductRepository to intentionally cause an error after first operation
2. Execute UpdateProductAsync
3. Verify rollback occurred - no partial updates

**Simulated Error Test**:
- Temporarily rename ProductHistory table to cause FK constraint error
- Attempt update
- Verify original Product data unchanged

#### Test 14.3: Concurrent Transaction Testing
1. Start two application instances
2. Execute simultaneous updates on different products
3. Verify both transactions complete successfully
4. Verify ProductStats reflects both updates correctly

**Pass Criteria**: 
- Successful transactions commit all operations atomically
- Failed transactions rollback all operations
- Concurrent transactions don't corrupt data

---

### Criterion 15: Test Suite Execution

**Current Status**: No unit tests or integration tests exist in the codebase

**Options**:

#### Option A: Create Test Suite (Recommended)
Create a test project to validate functionality:

```bash
cd sourceCode
dotnet new xunit -o AdoCore.Tests
cd AdoCore.Tests
dotnet add reference ../AdoCore.csproj
dotnet add package Npgsql
dotnet add package Testcontainers.PostgreSql
```

Sample test structure:
```csharp
public class ProductRepositoryTests : IAsyncLifetime
{
    private PostgreSqlContainer _container;
    private ProductRepository _repository;

    [Fact]
    public async Task GetAllProductsAsync_ReturnsProducts()
    {
        // Arrange
        // Act
        var products = await _repository.GetAllProductsAsync();
        // Assert
        Assert.NotNull(products);
    }
    
    // Add tests for all CRUD operations
    // Add transaction tests
}
```

#### Option B: Manual Testing Documentation
If automated tests are not required, document manual testing results:
1. Execute all test cases from Criteria 12-14
2. Document results with screenshots/logs
3. Create test execution report

**Pass Criteria**: Either automated tests pass OR comprehensive manual testing documented

---

## Test Execution Checklist

- [ ] PostgreSQL database setup complete
- [ ] Schema and tables created
- [ ] Connection string configured
- [ ] Application compiles successfully
- [ ] Criterion 12: Database connectivity verified
- [ ] Criterion 13.1: GetAllProductsAsync tested
- [ ] Criterion 13.2: GetProductByIdAsync tested
- [ ] Criterion 13.3: InsertProductAsync tested
- [ ] Criterion 13.4: UpdateProductAsync tested
- [ ] Criterion 13.5: DeleteProductAsync tested
- [ ] Criterion 13.6: GetProductsByPriceRangeAsync tested
- [ ] Criterion 13.7: GetLowStockProductsAsync tested
- [ ] Criterion 14.1: Transaction commit tested
- [ ] Criterion 14.2: Transaction rollback tested
- [ ] Criterion 14.3: Concurrent transactions tested
- [ ] Criterion 15: Tests created or manual testing documented

## Common Issues and Troubleshooting

### Connection Issues
- **Error**: "Connection refused"
  - **Solution**: Check PostgreSQL is running, verify host and port
  
- **Error**: "password authentication failed"
  - **Solution**: Verify username/password in connection string

### SQL Errors
- **Error**: "relation does not exist"
  - **Solution**: Verify all tables created in correct database/schema

- **Error**: "syntax error near..."
  - **Solution**: Check PostgreSQL version compatibility

### Transaction Issues
- **Error**: "transaction already in progress"
  - **Solution**: Ensure proper transaction disposal in code

## Success Metrics

For the migration to be considered successful:

1. ✅ **Static Migration Complete**: All code changes done (CURRENT STATUS)
2. ⏳ **Runtime Connectivity**: Application connects to PostgreSQL (REQUIRES DATABASE)
3. ⏳ **Functional Correctness**: All operations execute successfully (REQUIRES DATABASE)
4. ⏳ **Data Integrity**: Transactions maintain atomicity (REQUIRES DATABASE)
5. ⏳ **Test Coverage**: Tests pass or manual testing documented (REQUIRES DATABASE)

## Next Steps

1. **Immediate**: Set up PostgreSQL test environment using provided schema
2. **Short-term**: Execute runtime tests following this guide
3. **Long-term**: Consider creating automated test suite for regression testing

## Support

For issues during runtime testing:
- Check PostgreSQL logs: `/var/log/postgresql/`
- Enable application logging to trace SQL execution
- Verify SQL statements match PostgreSQL syntax expectations
- Review `SECURITY_NOTES.md` for connection string best practices
