# Runtime Testing and Validation Guide

## Purpose
This guide provides step-by-step instructions for validating the SQL Server to PostgreSQL migration once a PostgreSQL database environment is available.

## Prerequisites Checklist
- [ ] PostgreSQL 12+ installed and running
- [ ] ProductManagement database created
- [ ] Schema and sample data loaded (see POSTGRESQL_SETUP_GUIDE.md)
- [ ] Application built successfully (`dotnet build`)
- [ ] Connection string updated in appsettings.json

## Exit Criteria 12: Database Connectivity Testing

### Objective
Verify the application successfully connects to the PostgreSQL database.

### Test Steps

1. **Verify PostgreSQL is accessible:**
   ```bash
   psql -U postgres -d ProductManagement -c "SELECT version();"
   ```
   Expected: PostgreSQL version information displayed

2. **Test connection from application host:**
   ```bash
   psql -U productapp -h localhost -d ProductManagement -c "SELECT COUNT(*) FROM Products;"
   ```
   Expected: Returns count of 18 products

3. **Run the application:**
   ```bash
   cd sourceCode
   dotnet run
   ```
   Expected: Application starts without connection errors

4. **Verify connection in application:**
   - Application should display main menu
   - No connection errors in console
   - Application should not crash on startup

### Success Criteria
✅ **PASS** if:
- PostgreSQL connection established without errors
- Application displays interactive menu
- No connection timeout or authentication errors

❌ **FAIL** if:
- Connection timeout errors
- Authentication failures
- Network connectivity issues
- Database does not exist errors

### Common Issues and Solutions

**Issue:** "password authentication failed"
**Solution:** 
- Verify connection string username/password
- Check pg_hba.conf authentication configuration
- Ensure user exists in PostgreSQL

**Issue:** "could not connect to server"
**Solution:**
- Verify PostgreSQL service running: `systemctl status postgresql`
- Check firewall rules for port 5432
- Verify Host parameter in connection string

**Issue:** "database 'ProductManagement' does not exist"
**Solution:**
- Create database: `CREATE DATABASE "ProductManagement";`
- Execute schema setup script

---

## Exit Criteria 13: Database Operations Testing

### Objective
Verify all database operations (SELECT, INSERT, UPDATE, DELETE) execute successfully against PostgreSQL.

### Test 1: SELECT Operations

#### Test 1.1: GetAllProductsAsync
```
Menu Option: 1 - Get All Products
Expected Result: Display all 18 products with CTE and window functions
```

**Validation:**
1. Select option 1 from menu
2. Verify 18 products are displayed
3. Verify PriceCategory field calculated correctly
4. Verify products sorted by price category and name

**SQL Statement Being Tested:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.*, CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' ... END
FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
```

**Success Criteria:**
- ✅ All 18 products retrieved
- ✅ Window functions calculate correctly
- ✅ CTE executes without errors
- ✅ CASE expression produces correct categories

#### Test 1.2: GetProductByIdAsync
```
Menu Option: 2 - Get Product By ID
Test ID: 1
Expected: Display product details with price change history
```

**Validation:**
1. Select option 2
2. Enter ProductId: 1
3. Verify product details displayed
4. Verify LAG window function calculates previous price/stock

**SQL Statement Being Tested:**
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice, ...
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.*, ph.PreviousPrice, ... FROM Products p LEFT JOIN ProductHistory ph ...
```

**Success Criteria:**
- ✅ Product details retrieved correctly
- ✅ LAG window function works
- ✅ Parameter binding (@ProductId) functions correctly
- ✅ LEFT JOIN returns results even with no history

#### Test 1.3: GetProductsByPriceRangeAsync
```
Menu Option: 6 - Get Products by Price Range
Test Range: Min=100, Max=500
Expected: Products filtered and ranked by price
```

**Validation:**
1. Select option 6
2. Enter MinPrice: 100
3. Enter MaxPrice: 500
4. Verify products within range displayed
5. Verify RANK and PERCENT_RANK calculated

**SQL Statement Being Tested:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
    PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' ... END
```

**Success Criteria:**
- ✅ Only products within price range returned
- ✅ RANK() function produces sequential ranks
- ✅ PERCENT_RANK() produces values between 0 and 1
- ✅ Price segments calculated correctly

#### Test 1.4: GetLowStockProductsAsync
```
Menu Option: 7 - Get Low Stock Products
Test Threshold: 15
Expected: Products with stock <= 15
```

**Validation:**
1. Select option 7
2. Enter threshold: 15
3. Verify only low-stock products displayed
4. Verify stock analysis calculations correct

**SQL Statement Being Tested:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock, MIN(...), MAX(...)
    FROM Products p
)
SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' ... END
WHERE StockQuantity <= @Threshold
```

**Success Criteria:**
- ✅ Only products with StockQuantity <= threshold returned
- ✅ Window functions calculate average stock correctly
- ✅ Stock status categories assigned correctly
- ✅ Percentage calculations accurate

### Test 2: INSERT Operations

#### Test 2.1: InsertProductAsync
```
Menu Option: 3 - Insert Product
Test Data:
  Name: "Test Product PostgreSQL"
  Description: "Testing INSERT with RETURNING clause"
  Price: 99.99
  Stock: 50
```

**Validation:**
1. Select option 3
2. Enter product details
3. Verify new ProductId returned
4. Query database to confirm insert:
   ```sql
   SELECT * FROM Products WHERE Name = 'Test Product PostgreSQL';
   ```
5. Verify ProductHistory record created:
   ```sql
   SELECT * FROM ProductHistory WHERE Action = 'INSERT' ORDER BY ActionDate DESC LIMIT 1;
   ```
6. Verify ProductStats updated:
   ```sql
   SELECT TotalProducts FROM ProductStats;
   ```

**Critical SQL Feature Being Tested:**
```sql
WITH inserted_product AS (
    INSERT INTO Products (...) VALUES (...) RETURNING ProductId
)
INSERT INTO ProductHistory (ProductId, ...)
SELECT ProductId, 'INSERT', ... FROM inserted_product;
```

**Success Criteria:**
- ✅ Product inserted successfully
- ✅ RETURNING clause returns new ProductId
- ✅ ProductHistory audit record created automatically
- ✅ ProductStats TotalProducts incremented
- ✅ Transaction commits successfully
- ✅ NOW() function records correct timestamp

### Test 3: UPDATE Operations

#### Test 3.1: UpdateProductAsync
```
Menu Option: 4 - Update Product
Test ProductId: (use ID from insert test above)
Updated Data:
  Name: "Test Product Updated"
  Price: 89.99
  Stock: 45
```

**Validation:**
1. Select option 4
2. Enter ProductId of test product
3. Enter updated details
4. Verify update confirmation
5. Query to confirm update:
   ```sql
   SELECT * FROM Products WHERE ProductId = <test_id>;
   ```
6. Verify ProductHistory has UPDATE record:
   ```sql
   SELECT * FROM ProductHistory 
   WHERE ProductId = <test_id> AND Action = 'UPDATE' 
   ORDER BY ActionDate DESC LIMIT 1;
   ```
7. Verify old and new values recorded correctly
8. Verify ModifiedDate updated to NOW()

**Critical SQL Feature Being Tested:**
```sql
BEGIN;
    WITH old_values AS (SELECT Price as OldPrice, StockQuantity as OldStock ...)
    UPDATE Products SET ... ModifiedDate = NOW() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (...) SELECT ... FROM old_values;
    UPDATE ProductStats ...;
COMMIT;
```

**Success Criteria:**
- ✅ Product updated successfully
- ✅ CTE captures old values before update
- ✅ ProductHistory records old and new values
- ✅ ProductStats AveragePrice recalculated
- ✅ Transaction maintains atomicity
- ✅ ModifiedDate set to current timestamp

### Test 4: DELETE Operations

#### Test 4.1: DeleteProductAsync
```
Menu Option: 5 - Delete Product
Test ProductId: (use ID from previous tests)
```

**Validation:**
1. Select option 5
2. Enter ProductId of test product
3. Verify deletion confirmation
4. Query to confirm deletion:
   ```sql
   SELECT * FROM Products WHERE ProductId = <test_id>;
   ```
   Expected: No rows returned
5. Verify ProductHistory has DELETE record:
   ```sql
   SELECT * FROM ProductHistory 
   WHERE ProductId = <test_id> AND Action = 'DELETE' 
   ORDER BY ActionDate DESC LIMIT 1;
   ```
6. Verify ProductStats updated:
   ```sql
   SELECT TotalProducts FROM ProductStats;
   ```

**Critical SQL Feature Being Tested:**
```sql
BEGIN;
    WITH old_values AS (SELECT Price as OldPrice, StockQuantity as OldStock ...)
    INSERT INTO ProductHistory (...) SELECT ... FROM old_values;
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1, ...;
COMMIT;
```

**Success Criteria:**
- ✅ Product deleted successfully
- ✅ CTE captures values before deletion
- ✅ ProductHistory records final state before deletion
- ✅ ProductStats decremented correctly
- ✅ Transaction maintains atomicity
- ✅ All statements execute in correct order

---

## Exit Criteria 14: Transaction Atomicity Testing

### Objective
Verify transaction blocks maintain ACID properties when executed against PostgreSQL.

### Test 1: Successful Transaction Commit

**Scenario:** Insert product with all transaction steps succeeding

1. Note current ProductStats values:
   ```sql
   SELECT * FROM ProductStats;
   ```

2. Insert a new product using the application (Option 3)

3. Verify all transaction steps completed:
   ```sql
   -- Verify product inserted
   SELECT COUNT(*) FROM Products WHERE Name = 'Test Product PostgreSQL';
   
   -- Verify history record
   SELECT COUNT(*) FROM ProductHistory WHERE Action = 'INSERT' 
   AND ProductId = (SELECT ProductId FROM Products WHERE Name = 'Test Product PostgreSQL');
   
   -- Verify stats updated
   SELECT TotalProducts FROM ProductStats;
   ```

**Success Criteria:**
- ✅ All three operations completed
- ✅ Product exists in Products table
- ✅ History record exists in ProductHistory
- ✅ Statistics updated in ProductStats
- ✅ All changes committed together

### Test 2: Transaction Rollback on Error

**Scenario:** Simulate error during transaction to verify rollback

**Manual Test Using psql:**

```sql
-- Start transaction
BEGIN;

-- Insert product (should succeed)
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ('Rollback Test', 'Testing rollback', 99.99, 10)
RETURNING ProductId;
-- Note the returned ProductId

-- Insert history (should succeed)
INSERT INTO ProductHistory (ProductId, Action, NewPrice, NewStock, ActionDate)
VALUES (<returned_id>, 'INSERT', 99.99, 10, NOW());

-- Intentionally cause error (invalid data type)
UPDATE ProductStats SET TotalProducts = 'invalid_number' WHERE StatId = 1;

-- Transaction should fail here, rollback all changes
ROLLBACK;

-- Verify product was NOT inserted
SELECT COUNT(*) FROM Products WHERE Name = 'Rollback Test';
-- Expected: 0

-- Verify history was NOT inserted
SELECT COUNT(*) FROM ProductHistory WHERE Action = 'INSERT' 
AND ProductId = <returned_id>;
-- Expected: 0
```

**Success Criteria:**
- ✅ Transaction fails on error
- ✅ All changes rolled back
- ✅ No partial data committed
- ✅ Database remains consistent
- ✅ ProductStats unchanged

### Test 3: Concurrent Transaction Isolation

**Scenario:** Verify transactions don't interfere with each other

**Terminal 1:**
```sql
BEGIN;
SELECT * FROM Products WHERE ProductId = 1 FOR UPDATE;
-- Update price
UPDATE Products SET Price = 1500.00 WHERE ProductId = 1;
-- Don't commit yet, wait 30 seconds
COMMIT;
```

**Terminal 2 (simultaneously):**
```sql
-- Try to read the same product
SELECT Price FROM Products WHERE ProductId = 1;
-- Should see original price until Terminal 1 commits
```

**Success Criteria:**
- ✅ Read sees original value until commit
- ✅ No dirty reads occur
- ✅ Transaction isolation maintained
- ✅ Both transactions complete successfully

### Test 4: Transaction Atomicity in Application

**Test InsertProductAsync atomicity:**

1. Temporarily disable PostgreSQL foreign key constraint:
   ```sql
   ALTER TABLE ProductHistory DROP CONSTRAINT FK_ProductHistory_Products;
   ```

2. Try to insert product through application

3. Application should handle gracefully if any step fails

4. Restore constraint:
   ```sql
   ALTER TABLE ProductHistory 
   ADD CONSTRAINT FK_ProductHistory_Products 
   FOREIGN KEY (ProductId) REFERENCES Products (ProductId);
   ```

**Test UpdateProductAsync atomicity:**

Similar test for update operations to ensure partial updates don't occur.

**Test DeleteProductAsync atomicity:**

Similar test for delete operations to ensure audit trail maintained even if delete fails.

---

## Exit Criteria 15: Unit and Integration Tests

### Current Status
❌ **FAIL** - No unit test project exists in the repository

### Analysis
The original application did not include any test projects or test files. A search for test files yielded:
- No *Test.cs files found
- No *test.csproj files found
- No test directory present

### Recommendation
This exit criterion **cannot be met** because:
1. No tests existed in the original SQL Server application
2. The migration scope is to convert existing application, not create new tests
3. Creating tests would be outside the migration scope

### Future Enhancement (Optional)
Consider creating a test suite for the migrated application:

**Suggested Test Project Structure:**
```
AdoCore.Tests/
├── AdoCore.Tests.csproj
├── Unit/
│   ├── ProductRepositoryTests.cs
│   └── ModelTests.cs
├── Integration/
│   ├── DatabaseConnectionTests.cs
│   ├── CrudOperationsTests.cs
│   └── TransactionTests.cs
└── Fixtures/
    └── PostgreSqlTestFixture.cs
```

**Sample Test (for future implementation):**
```csharp
[Fact]
public async Task GetAllProductsAsync_ShouldReturn18Products()
{
    // Arrange
    var repository = new ProductRepository(connectionString);
    
    // Act
    var products = await repository.GetAllProductsAsync();
    
    // Assert
    Assert.Equal(18, products.Count);
}
```

---

## Complete Validation Checklist

### Code Migration Validation (Completed)
- [x] SQL Server packages replaced with Npgsql
- [x] All SqlConnection/SqlCommand replaced with NpgsqlConnection/NpgsqlCommand
- [x] All SQL statements processed through DMS MCP tool
- [x] Complete statement catalog created
- [x] All statements validated through SQL Equivalency tool
- [x] Equivalency validation report generated
- [x] No agent judgment used for equivalency
- [x] DMS failures documented
- [x] Connection strings updated to PostgreSQL format
- [x] Transaction syntax updated (BEGIN/COMMIT/ROLLBACK)
- [x] Application compiles without errors

### Runtime Validation (Requires PostgreSQL Instance)
- [ ] Application connects to PostgreSQL successfully (Criterion 12)
- [ ] SELECT operations execute correctly
  - [ ] GetAllProductsAsync with CTE and window functions
  - [ ] GetProductByIdAsync with LAG function
  - [ ] GetProductsByPriceRangeAsync with RANK/PERCENT_RANK
  - [ ] GetLowStockProductsAsync with window aggregates
- [ ] INSERT operation with RETURNING clause works
- [ ] UPDATE operation with CTE and NOW() works
- [ ] DELETE operation with CTE and transaction works
- [ ] Transaction atomicity verified (Criterion 14)
  - [ ] Successful commits work correctly
  - [ ] Rollbacks undo all changes
  - [ ] Isolation prevents dirty reads
- [ ] ProductHistory audit trail functioning
- [ ] ProductStats maintained correctly
- [ ] All parameterized queries working
- [ ] All data types convert correctly
- [ ] All functions (NOW(), ROUND(), etc.) work as expected

### Test Suite Validation (Not Applicable)
- [N/A] Unit tests (no tests exist in original application)
- [N/A] Integration tests (no tests exist in original application)

---

## Reporting Results

After completing all runtime tests, document results in this format:

### Test Execution Summary

**Date:** [Date tests performed]
**Environment:** [PostgreSQL version, OS, .NET version]
**Tester:** [Name]

**Exit Criterion 12 - Database Connectivity:**
- Status: [PASS/FAIL]
- Evidence: [Screenshot/log output]
- Issues: [None or description]

**Exit Criterion 13 - Database Operations:**
- SELECT operations: [PASS/FAIL] - [X/4 tests passed]
- INSERT operations: [PASS/FAIL]
- UPDATE operations: [PASS/FAIL]
- DELETE operations: [PASS/FAIL]
- Evidence: [Screenshots/logs]
- Issues: [None or descriptions]

**Exit Criterion 14 - Transaction Atomicity:**
- Commit test: [PASS/FAIL]
- Rollback test: [PASS/FAIL]
- Isolation test: [PASS/FAIL]
- Evidence: [SQL query results]
- Issues: [None or descriptions]

**Exit Criterion 15 - Test Suite:**
- Status: FAIL (No test suite exists in original application)
- Reason: Not applicable - no tests to migrate

**Overall Migration Status:**
- Code migration: COMPLETE (12/12 criteria passed)
- Runtime validation: [PASS/FAIL] ([X/3] runtime criteria passed)
- Recommendation: [Ready for production / Needs fixes / etc.]

---

## Troubleshooting Common Issues

### SELECT Operation Failures

**Issue:** Window functions returning unexpected results
**Check:**
- PostgreSQL version >= 12 (window functions fully supported)
- OVER() clause syntax correct
- Partition and order clauses properly specified

**Issue:** CTE not found
**Check:**
- CTE syntax: WITH ... AS (...) SELECT ...
- CTE referenced in main query
- No semicolon before WITH

### INSERT Operation Failures

**Issue:** RETURNING clause not working
**Check:**
- PostgreSQL syntax: RETURNING column_name
- Not using OUTPUT clause (SQL Server syntax)
- Variable assignment in application code

**Issue:** ProductHistory not updated
**Check:**
- Trigger function exists: `\df trg_products_history`
- Trigger enabled: `\dS Products`
- Transaction completed successfully

### UPDATE/DELETE Operation Failures

**Issue:** CTE with old_values not working
**Check:**
- CTE must be within same transaction
- CTE executes before main UPDATE/DELETE
- CTE result used in subsequent statement

### Transaction Failures

**Issue:** Transaction not rolling back on error
**Check:**
- BEGIN statement executed
- Exception handling in application
- ROLLBACK called in catch block

**Issue:** Partial commits occurring
**Check:**
- All statements within same transaction block
- No implicit commits between statements
- Connection remains open throughout transaction

---

## Success Indicators

The migration is **successful** when:

✅ All 18 sample products load correctly
✅ Complex queries with CTEs and window functions execute without errors
✅ INSERT returns new ID correctly using RETURNING clause
✅ UPDATE and DELETE maintain audit trail in ProductHistory
✅ ProductStats stays synchronized with Products table
✅ Transactions commit/rollback atomically
✅ NOW() function produces correct timestamps
✅ All data types (DECIMAL, INTEGER, VARCHAR, TIMESTAMP) work correctly
✅ Parameterized queries prevent SQL injection
✅ Application runs stable under normal load
✅ No data loss or corruption occurs
✅ Performance is acceptable for application requirements

When all runtime tests pass, the migration from SQL Server to PostgreSQL is **complete and validated**.
