# Runtime Testing Guide for PostgreSQL Migration

## Overview
This document provides a comprehensive guide for runtime testing of the migrated ADO.NET application with PostgreSQL database.

## Prerequisites

### 1. PostgreSQL Database Setup
- PostgreSQL 12 or higher installed
- Access to create databases
- Client tools (psql or pgAdmin)

### 2. Database Schema Setup
```bash
# Connect to PostgreSQL as admin
psql -U postgres

# Create the database
CREATE DATABASE productmanagement;

# Connect to the database
\c productmanagement;

# Run the schema script
\i Database/Scripts/02_PostgreSQL_Schema.sql
```

### 3. Connection String Configuration

Update `appsettings.json` with appropriate PostgreSQL credentials:

**Option 1: Username/Password Authentication**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=your_username;Password=your_password",
    "ProdConnection": "Host=your_prod_host;Port=5432;Database=productmanagement;Username=your_username;Password=your_password"
  },
  "Environment": "Development"
}
```

**Option 2: Connection Pooling (Recommended for Production)**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=your_username;Password=your_password;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100",
    "ProdConnection": "Host=your_prod_host;Port=5432;Database=productmanagement;Username=your_username;Password=your_password;SSL Mode=Require;Pooling=true"
  },
  "Environment": "Development"
}
```

**Note**: Remove `Integrated Security=true` as it's not supported by PostgreSQL. Use proper authentication instead.

## Runtime Test Plan

### Phase 1: Connection Testing
**Objective**: Verify successful database connection

**Test Steps**:
1. Update connection string with valid credentials
2. Run the application
3. Verify connection is established without errors
4. Check PostgreSQL logs for successful connection

**Expected Results**:
- Application starts without connection errors
- Database connection pool initialized
- No authentication failures in logs

**Success Criteria**: Application connects to PostgreSQL database successfully

---

### Phase 2: Basic CRUD Operations Testing

#### Test 2.1: GetAllProductsAsync()
**SQL Statement**: CTE with window functions (AVG OVER, COUNT OVER)

**Test Steps**:
```csharp
var repository = new ProductRepository(configuration);
var products = await repository.GetAllProductsAsync();
```

**Expected Results**:
- Returns list of 18 products from sample data
- Window functions calculate average price correctly
- Products categorized as 'Above Average', 'Below Average', or 'Average'
- Results ordered by price category and name

**Validation**:
- Count of products: 18
- Products with price > average marked as 'Above Average'
- No null values in required fields
- PricePercentageOfAverage calculated correctly

---

#### Test 2.2: GetProductByIdAsync()
**SQL Statement**: CTE with LAG window function

**Test Steps**:
```csharp
var repository = new ProductRepository(configuration);
var product = await repository.GetProductByIdAsync(1); // ProBook X1
```

**Expected Results**:
- Returns Product with ProductId = 1
- Name: "ProBook X1"
- Price: 1299.99
- StockQuantity: 15
- No PreviousPrice (first product, no history yet)

**Validation**:
- Product object not null
- All properties populated correctly
- LAG function returns NULL for first product (expected)

---

#### Test 2.3: InsertProductAsync()
**SQL Statement**: INSERT with RETURNING clause + multi-statement transaction

**Test Steps**:
```csharp
var newProduct = new Product
{
    Name = "Test Laptop",
    Description = "Test product for migration",
    Price = 1500.00m,
    StockQuantity = 10
};

var repository = new ProductRepository(configuration);
int newProductId = await repository.InsertProductAsync(newProduct);
```

**Expected Results**:
- Returns new ProductId (likely 19)
- Product inserted into Products table
- ProductHistory record created with Action='INSERT'
- ProductStats.TotalProducts incremented by 1
- ProductStats.AveragePrice recalculated

**Validation**:
```sql
-- Verify product inserted
SELECT * FROM Products WHERE ProductId = [newProductId];

-- Verify history logged
SELECT * FROM ProductHistory WHERE ProductId = [newProductId] AND Action = 'INSERT';

-- Verify stats updated
SELECT TotalProducts, AveragePrice FROM ProductStats WHERE StatId = 1;
```

**Critical**: Verify RETURNING clause returns the correct ProductId (not null, not 0)

---

#### Test 2.4: UpdateProductAsync()
**SQL Statement**: Multi-statement transaction with SELECT + UPDATE + INSERT + UPDATE

**Test Steps**:
```csharp
var repository = new ProductRepository(configuration);
var product = await repository.GetProductByIdAsync(1);
product.Price = 1399.99m; // Update price
product.StockQuantity = 12; // Update stock

await repository.UpdateProductAsync(product);
```

**Expected Results**:
- Product updated in Products table
- ModifiedDate updated to CURRENT_TIMESTAMP
- ProductHistory record created with Action='UPDATE'
- OldPrice and OldStock captured correctly
- ProductStats.AveragePrice recalculated

**Validation**:
```sql
-- Verify product updated
SELECT Price, StockQuantity, ModifiedDate FROM Products WHERE ProductId = 1;

-- Verify history logged
SELECT OldPrice, NewPrice, OldStock, NewStock 
FROM ProductHistory 
WHERE ProductId = 1 AND Action = 'UPDATE'
ORDER BY ActionDate DESC
LIMIT 1;

-- Verify ModifiedDate is recent
SELECT ModifiedDate FROM Products WHERE ProductId = 1;
```

---

#### Test 2.5: DeleteProductAsync()
**SQL Statement**: Multi-statement transaction with SELECT + INSERT + DELETE + UPDATE

**Test Steps**:
```csharp
var repository = new ProductRepository(configuration);
await repository.DeleteProductAsync(19); // Delete test product
```

**Expected Results**:
- Product removed from Products table
- ProductHistory record created with Action='DELETE'
- OldPrice and OldStock captured, NewPrice and NewStock are NULL
- ProductStats.TotalProducts decremented by 1
- ProductStats.AveragePrice recalculated

**Validation**:
```sql
-- Verify product deleted
SELECT * FROM Products WHERE ProductId = 19; -- Should return no rows

-- Verify history logged
SELECT OldPrice, NewPrice, OldStock, NewStock 
FROM ProductHistory 
WHERE ProductId = 19 AND Action = 'DELETE';

-- Verify stats updated
SELECT TotalProducts FROM ProductStats WHERE StatId = 1;
```

---

### Phase 3: Complex Query Testing

#### Test 3.1: GetProductsByPriceRangeAsync()
**SQL Statement**: CTE with RANK and PERCENT_RANK window functions

**Test Steps**:
```csharp
var repository = new ProductRepository(configuration);
var products = await repository.GetProductsByPriceRangeAsync(100m, 500m);
```

**Expected Results**:
- Returns products with prices between $100 and $500
- Products ranked by price (PriceRank)
- Products categorized by percentile: 'Budget', 'Mid-Range', 'Premium'
- Ordered by PriceRank

**Validation**:
- All returned products have price between 100 and 500
- PriceRank values are sequential (1, 2, 3, ...)
- PriceSegment correctly assigned based on percentile

---

#### Test 3.2: GetLowStockProductsAsync()
**SQL Statement**: CTE with AVG, MIN, MAX window functions

**Test Steps**:
```csharp
var repository = new ProductRepository(configuration);
var products = await repository.GetLowStockProductsAsync(10);
```

**Expected Results**:
- Returns products with StockQuantity <= 10
- Window functions calculate AvgStock, MinStock, MaxStock
- StockStatus categorized: 'Critical', 'Low', 'Adequate'
- StockPercentageOfAverage calculated
- Ordered by StockQuantity ascending

**Validation**:
- All products have StockQuantity <= 10
- StockStatus matches the threshold logic
- StockPercentageOfAverage is reasonable (0-100%)

---

### Phase 4: Transaction Atomicity Testing
**Objective**: Verify transaction rollback on errors

#### Test 4.1: Insert Transaction Rollback
**Test Steps**:
```csharp
var repository = new ProductRepository(configuration);

// Create product with invalid data to force error after first INSERT
var invalidProduct = new Product
{
    Name = "Test Product",
    Description = null,
    Price = -100m, // This might pass, but we can force error in history insert
    StockQuantity = 5
};

try
{
    // Temporarily modify ProductHistory to have a constraint that will fail
    // OR manually interrupt the transaction
    await repository.InsertProductAsync(invalidProduct);
}
catch (Exception ex)
{
    Console.WriteLine($"Expected error: {ex.Message}");
}

// Verify NO product was inserted (transaction rolled back)
```

**Expected Results**:
- Exception thrown during transaction
- NO product inserted into Products table
- NO history record created
- ProductStats unchanged
- Database in consistent state

**Validation**:
```sql
-- Verify no orphaned records
SELECT COUNT(*) FROM Products WHERE Name = 'Test Product'; -- Should be 0
SELECT COUNT(*) FROM ProductHistory WHERE NewPrice < 0; -- Should be 0
```

---

#### Test 4.2: Update Transaction Rollback
**Test Steps**:
1. Get existing product
2. Modify price
3. Force error during transaction (e.g., invalid foreign key)
4. Verify original values preserved

**Expected Results**:
- Transaction rolled back
- Original product values unchanged
- No history record created
- ProductStats unchanged

---

#### Test 4.3: Delete Transaction Rollback
**Test Steps**:
1. Select product to delete
2. Start delete operation
3. Force error during transaction
4. Verify product still exists

**Expected Results**:
- Transaction rolled back
- Product still exists in Products table
- No history record created
- ProductStats unchanged

---

### Phase 5: Concurrency Testing
**Objective**: Test transaction isolation and concurrent access

#### Test 5.1: Concurrent Updates
**Test Steps**:
```csharp
// Simulate two concurrent updates to same product
var task1 = Task.Run(async () => {
    var repo = new ProductRepository(configuration);
    var product = await repo.GetProductByIdAsync(1);
    product.Price = 1500m;
    await repo.UpdateProductAsync(product);
});

var task2 = Task.Run(async () => {
    var repo = new ProductRepository(configuration);
    var product = await repo.GetProductByIdAsync(1);
    product.StockQuantity = 20;
    await repo.UpdateProductAsync(product);
});

await Task.WhenAll(task1, task2);
```

**Expected Results**:
- Both transactions complete
- Final state reflects both updates OR one update (depending on isolation level)
- No lost updates
- Both updates logged in ProductHistory

---

### Phase 6: Performance Testing

#### Test 6.1: Query Performance
**Test Steps**:
1. Measure execution time for each query method
2. Compare with SQL Server baseline (if available)
3. Check for missing indexes

**Expected Results**:
- Query times within acceptable range (<100ms for simple queries)
- Window function queries complete in reasonable time (<500ms)
- No significant performance degradation vs SQL Server

**Tools**:
```csharp
var stopwatch = Stopwatch.StartNew();
var products = await repository.GetAllProductsAsync();
stopwatch.Stop();
Console.WriteLine($"Query took {stopwatch.ElapsedMilliseconds}ms");
```

---

#### Test 6.2: Load Testing
**Test Steps**:
1. Execute 1000 concurrent reads
2. Execute 100 concurrent inserts
3. Execute 100 concurrent updates
4. Monitor PostgreSQL connection pool

**Expected Results**:
- All operations complete successfully
- Connection pool handles load efficiently
- No connection leaks
- No deadlocks

---

## Test Execution Checklist

- [ ] PostgreSQL database installed and running
- [ ] Database schema created using 02_PostgreSQL_Schema.sql
- [ ] Connection string updated with valid credentials
- [ ] Sample data loaded (18 products)
- [ ] ProductStats initialized
- [ ] Phase 1: Connection testing passed
- [ ] Phase 2: CRUD operations tested
  - [ ] GetAllProductsAsync() - Window functions work
  - [ ] GetProductByIdAsync() - LAG function works
  - [ ] InsertProductAsync() - RETURNING clause works
  - [ ] UpdateProductAsync() - Multi-statement transaction works
  - [ ] DeleteProductAsync() - Transaction works
- [ ] Phase 3: Complex queries tested
  - [ ] GetProductsByPriceRangeAsync() - RANK functions work
  - [ ] GetLowStockProductsAsync() - Multiple window functions work
- [ ] Phase 4: Transaction rollback tested
  - [ ] Insert rollback works
  - [ ] Update rollback works
  - [ ] Delete rollback works
- [ ] Phase 5: Concurrency tested
  - [ ] Concurrent updates handled correctly
  - [ ] No lost updates or deadlocks
- [ ] Phase 6: Performance tested
  - [ ] Query performance acceptable
  - [ ] Load testing passed

---

## Known Issues and Workarounds

### Issue 1: Integrated Security not supported
**Symptom**: Connection fails with "Integrated Security=true"
**Solution**: Use Username/Password authentication in connection string

### Issue 2: Case sensitivity
**Symptom**: Column names not found
**Solution**: PostgreSQL is case-sensitive. Ensure all column names match schema exactly.

### Issue 3: Boolean vs Bit
**Symptom**: Bit type errors
**Solution**: Schema already uses BOOLEAN (not BIT). Verified in 02_PostgreSQL_Schema.sql

### Issue 4: SERIAL vs IDENTITY
**Symptom**: Auto-increment not working
**Solution**: Schema uses SERIAL (PostgreSQL equivalent of IDENTITY). Already implemented.

---

## Success Criteria

✅ **Connection Established**: Application connects to PostgreSQL database without errors

✅ **All 7 SQL Statements Execute**: Each repository method completes successfully
   - GetAllProductsAsync() - CTE with window functions
   - GetProductByIdAsync() - CTE with LAG
   - InsertProductAsync() - RETURNING clause
   - UpdateProductAsync() - Multi-statement transaction
   - DeleteProductAsync() - Multi-statement transaction
   - GetProductsByPriceRangeAsync() - RANK functions
   - GetLowStockProductsAsync() - Multiple window functions

✅ **Data Integrity Maintained**: 
   - Products inserted correctly
   - History tracked accurately
   - Statistics updated properly

✅ **Transaction Atomicity Verified**:
   - Rollback works on errors
   - No partial updates
   - Database remains consistent

✅ **No Runtime Errors**: Application runs without syntax errors or runtime exceptions

✅ **Window Functions Work**: All window functions (AVG OVER, LAG OVER, RANK OVER, etc.) return correct results

✅ **RETURNING Clause Works**: InsertProductAsync returns correct ProductId

✅ **CURRENT_TIMESTAMP Works**: All timestamps use PostgreSQL CURRENT_TIMESTAMP

---

## Reporting Results

After completing runtime testing, document the following:

1. **Test Execution Summary**:
   - Total tests executed
   - Tests passed
   - Tests failed
   - Tests skipped (with reason)

2. **Performance Metrics**:
   - Average query execution time
   - Connection pool statistics
   - Resource usage (CPU, memory)

3. **Issues Discovered**:
   - Description of any failures
   - Stack traces or error messages
   - Steps to reproduce

4. **Recommendations**:
   - Performance optimizations needed
   - Index tuning suggestions
   - Connection string improvements

---

## Conclusion

This comprehensive runtime testing plan covers all aspects of the PostgreSQL migration:
- Connection establishment
- CRUD operations
- Complex queries with window functions
- Transaction atomicity
- Concurrency handling
- Performance validation

Following this plan will provide confidence that the migration from SQL Server to PostgreSQL is complete and successful.
