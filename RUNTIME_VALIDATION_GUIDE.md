# Runtime Validation Guide for AdoCore PostgreSQL Migration

## Overview
This guide provides step-by-step instructions to complete the runtime validation of the migrated AdoCore application. The code-level migration is 100% complete. This guide addresses the 4 remaining exit criteria (12-15) that require a live PostgreSQL database.

## Prerequisites

### Software Requirements
- PostgreSQL 12 or higher installed and running
- .NET 9.0 SDK installed
- PostgreSQL client tools (psql or pgAdmin)

### Connection String
Update the connection strings in `appsettings.json` to match your PostgreSQL instance:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=YOUR_PASSWORD",
    "ProdConnection": "Host=your_prod_host;Database=productmanagement;Username=postgres;Password=YOUR_PASSWORD"
  },
  "Environment": "Development"
}
```

## Step 1: Database Setup

### 1.1 Install PostgreSQL
If PostgreSQL is not installed:
- **Windows**: Download from https://www.postgresql.org/download/windows/
- **macOS**: `brew install postgresql@16`
- **Linux**: `sudo apt-get install postgresql postgresql-contrib`

### 1.2 Start PostgreSQL Service
- **Windows**: Service should start automatically
- **macOS**: `brew services start postgresql@16`
- **Linux**: `sudo systemctl start postgresql`

### 1.3 Create Database and Schema
Execute the provided PostgreSQL setup script:

```bash
# Connect as postgres superuser and run the setup script
psql -U postgres -d postgres -f Database/Scripts/01_PostgreSQL_Setup.sql
```

**Alternative method using pgAdmin:**
1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" → "Create" → "Database"
3. Name: `productmanagement`
4. Open Query Tool and paste the contents of `01_PostgreSQL_Setup.sql`
5. Execute the script

### 1.4 Verify Database Setup
```sql
-- Connect to the database
\c productmanagement

-- Verify schema
\dn

-- Verify tables
\dt productmanagement_dbo.*

-- Check data
SELECT COUNT(*) FROM productmanagement_dbo.products;
SELECT COUNT(*) FROM productmanagement_dbo.categories;
SELECT COUNT(*) FROM productmanagement_dbo.suppliers;
SELECT * FROM productmanagement_dbo.productstats;
```

Expected results:
- 18 products
- 20 categories
- 8 suppliers
- 1 stats record

## Step 2: Exit Criterion 12 - Database Connectivity Testing

### 2.1 Update Connection String
Edit `appsettings.json` with your PostgreSQL credentials:
- Host: Your PostgreSQL server address (default: localhost)
- Database: productmanagement
- Username: Your PostgreSQL username (default: postgres)
- Password: Your PostgreSQL password

### 2.2 Test Connection
Run the application:

```bash
cd sourceCode
dotnet run
```

### 2.3 Verify Connection
Check the console output for successful connection messages. If connection fails:
- Verify PostgreSQL is running: `pg_isready`
- Check connection string format
- Verify user permissions: `psql -U postgres -d productmanagement`
- Check PostgreSQL logs for authentication errors

### 2.4 Connection Test Checklist
- [ ] Application starts without connection errors
- [ ] NpgsqlConnection.OpenAsync() succeeds
- [ ] Connection state management works correctly
- [ ] No authentication errors in logs
- [ ] Both DevConnection and ProdConnection formats are valid

**Status:** Pass this criterion when connection succeeds ✓

---

## Step 3: Exit Criterion 13 - Database Operations Testing

Test each method in ProductRepository.cs to ensure all CRUD operations work correctly.

### 3.1 Test GetAllProductsAsync
**What it tests:** CTE with window functions (AVG, COUNT OVER)

```bash
# The CLI should display all products with price categories
# Expected: 18 products with "Above Average", "Below Average", or "Average" categories
```

**Validation checklist:**
- [ ] All 18 products returned
- [ ] Price categories calculated correctly
- [ ] PricePercentageOfAverage values are accurate
- [ ] ORDER BY with CASE expression works
- [ ] No SQL syntax errors

### 3.2 Test GetProductByIdAsync
**What it tests:** LAG window function with LEFT JOIN

```bash
# Get a specific product (e.g., ProductId = 1)
# Expected: Product details with previous price/stock if modified
```

**Validation checklist:**
- [ ] Product retrieved successfully
- [ ] LAG function returns NULL for first record (no previous values)
- [ ] PriceChangePercentage calculated correctly if previous data exists
- [ ] Parameter binding works (@ProductId)
- [ ] No SQL syntax errors

### 3.3 Test InsertProductAsync
**What it tests:** RETURNING clause, multi-statement transaction

**Test Case:**
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

**Validation checklist:**
- [ ] Product inserted successfully
- [ ] RETURNING clause returns correct productid
- [ ] ProductHistory record created with action='INSERT'
- [ ] ProductStats updated (totalproducts incremented, averageprice recalculated)
- [ ] Transaction commits successfully
- [ ] Rollback works if any statement fails

### 3.4 Test UpdateProductAsync
**What it tests:** Multi-statement transaction, old value capture

**Test Case:**
```csharp
var product = await repository.GetProductByIdAsync(1);
product.Price = 1399.99m;
product.StockQuantity = 20;
await repository.UpdateProductAsync(product);
```

**Validation checklist:**
- [ ] Product updated successfully
- [ ] Old values captured correctly
- [ ] ModifiedDate set to CURRENT_TIMESTAMP
- [ ] ProductHistory record created with action='UPDATE'
- [ ] ProductStats averageprice recalculated correctly
- [ ] Transaction commits successfully
- [ ] Rollback works if any statement fails

### 3.5 Test DeleteProductAsync
**What it tests:** Multi-statement transaction, CASE expression in UPDATE

**Test Case:**
```csharp
await repository.DeleteProductAsync(18); // Delete last product
```

**Validation checklist:**
- [ ] Product deleted successfully
- [ ] ProductHistory record created with action='DELETE' before deletion
- [ ] ProductStats totalproducts decremented
- [ ] ProductStats averageprice recalculated with CASE logic
- [ ] CASE expression handles totalproducts > 1 correctly
- [ ] CASE expression sets averageprice to 0 when last product deleted
- [ ] Transaction commits successfully
- [ ] Rollback works if any statement fails

### 3.6 Test GetProductsByPriceRangeAsync
**What it tests:** RANK() and PERCENT_RANK() window functions

**Test Case:**
```csharp
var products = await repository.GetProductsByPriceRangeAsync(100m, 500m);
```

**Validation checklist:**
- [ ] Products in price range returned
- [ ] RANK() assigns correct sequential ranks
- [ ] PERCENT_RANK() calculates percentiles correctly
- [ ] Price segments ('Budget', 'Mid-Range', 'Premium') assigned correctly
- [ ] ORDER BY pricerank works correctly
- [ ] Parameter binding works (@MinPrice, @MaxPrice)
- [ ] No SQL syntax errors

### 3.7 Test GetLowStockProductsAsync
**What it tests:** AVG, MIN, MAX window functions

**Test Case:**
```csharp
var lowStockProducts = await repository.GetLowStockProductsAsync(10);
```

**Validation checklist:**
- [ ] Products with stockquantity <= threshold returned
- [ ] AVG(stockquantity) OVER() calculated correctly
- [ ] MIN/MAX window functions work correctly
- [ ] Stock status ('Critical', 'Low', 'Adequate') assigned correctly
- [ ] StockPercentageOfAverage calculated correctly
- [ ] Parameter binding works (@Threshold)
- [ ] No SQL syntax errors

**Status:** Pass this criterion when all 7 operations succeed ✓

---

## Step 4: Exit Criterion 14 - Transaction Atomicity Testing

Test that transactions maintain atomicity (all-or-nothing behavior).

### 4.1 Test Successful Transaction Commit
**Test:** Insert a product and verify all 3 statements execute

```csharp
var product = new Product { Name = "Commit Test", Price = 199.99m, StockQuantity = 10 };
int id = await repository.InsertProductAsync(product);
```

**Validation:**
- [ ] Product exists in products table
- [ ] History record exists in producthistory table
- [ ] Stats updated in productstats table
- [ ] All 3 changes committed together

### 4.2 Test Transaction Rollback - InsertProductAsync
**Test:** Simulate failure in second statement (history insert)

**Approach:**
1. Temporarily modify the code to throw an exception after the product insert
2. Run InsertProductAsync
3. Verify rollback

**Expected Result:**
- [ ] No product inserted (first statement rolled back)
- [ ] No history record created
- [ ] Stats unchanged
- [ ] Database in consistent state

### 4.3 Test Transaction Rollback - UpdateProductAsync
**Test:** Simulate failure in statistics update

**Approach:**
1. Temporarily modify the code to throw an exception in stats update
2. Run UpdateProductAsync
3. Verify rollback

**Expected Result:**
- [ ] Product NOT updated (changes rolled back)
- [ ] No history record created
- [ ] Stats unchanged
- [ ] Database in consistent state

### 4.4 Test Transaction Rollback - DeleteProductAsync
**Test:** Simulate failure after history insert but before delete

**Approach:**
1. Temporarily modify the code to throw an exception after history insert
2. Run DeleteProductAsync
3. Verify rollback

**Expected Result:**
- [ ] Product still exists (not deleted)
- [ ] No history record created (rolled back)
- [ ] Stats unchanged
- [ ] Database in consistent state

### 4.5 Test Concurrent Transaction Isolation
**Test:** Run multiple transactions concurrently

**Validation:**
- [ ] Transactions don't interfere with each other
- [ ] No deadlocks occur
- [ ] Database remains consistent
- [ ] All transactions complete successfully or rollback cleanly

**Status:** Pass this criterion when all atomicity tests succeed ✓

---

## Step 5: Exit Criterion 15 - Automated Test Suite

### Current Status
**No automated test suite exists in the original codebase.**

### Options

#### Option A: Mark as N/A (Not Applicable)
Since no test suite existed in the original SQL Server codebase, this criterion can be marked as N/A. The migration did not remove or break any existing tests.

#### Option B: Create New Test Suite (Recommended)
Although not required, creating integration tests is highly recommended for production use.

**Recommended Test Structure:**
```
AdoCore.Tests/
├── AdoCore.Tests.csproj
├── Integration/
│   ├── DatabaseFixture.cs          # Setup/teardown for test database
│   ├── ProductRepositoryTests.cs   # Test all CRUD operations
│   └── TransactionTests.cs         # Test transaction atomicity
└── appsettings.Test.json           # Test database connection
```

**Key Tests to Create:**
1. Connection management tests
2. All 7 CRUD operation tests
3. Transaction commit/rollback tests
4. Window function calculation validation tests
5. Error handling and exception tests
6. Concurrent operation tests

**Test Framework Recommendations:**
- xUnit or NUnit for test framework
- FluentAssertions for assertion library
- Testcontainers for PostgreSQL container (isolated test database)

**Sample Test:**
```csharp
[Fact]
public async Task InsertProductAsync_Should_Return_New_ProductId()
{
    // Arrange
    var repository = new ProductRepository(_testConfiguration);
    var product = new Product 
    { 
        Name = "Test Product", 
        Price = 99.99m, 
        StockQuantity = 10 
    };

    // Act
    int newId = await repository.InsertProductAsync(product);

    // Assert
    newId.Should().BeGreaterThan(0);
    var inserted = await repository.GetProductByIdAsync(newId);
    inserted.Should().NotBeNull();
    inserted.Name.Should().Be("Test Product");
}
```

**Status:** Mark as N/A or PASS after creating test suite ✓

---

## Validation Checklist Summary

### Exit Criterion 12: Database Connectivity
- [ ] PostgreSQL database created and running
- [ ] Connection string configured correctly
- [ ] Application connects successfully
- [ ] No authentication errors
- [ ] Connection state management works

**Result:** ☐ PASS ☐ FAIL

---

### Exit Criterion 13: Database Operations
- [ ] GetAllProductsAsync works correctly
- [ ] GetProductByIdAsync works correctly
- [ ] InsertProductAsync works correctly
- [ ] UpdateProductAsync works correctly
- [ ] DeleteProductAsync works correctly
- [ ] GetProductsByPriceRangeAsync works correctly
- [ ] GetLowStockProductsAsync works correctly

**Result:** ☐ PASS ☐ FAIL

---

### Exit Criterion 14: Transaction Atomicity
- [ ] Successful commits work correctly
- [ ] Rollback on InsertProductAsync failure
- [ ] Rollback on UpdateProductAsync failure
- [ ] Rollback on DeleteProductAsync failure
- [ ] No partial updates occur on failure
- [ ] Database consistency maintained

**Result:** ☐ PASS ☐ FAIL

---

### Exit Criterion 15: Automated Tests
- [ ] Test suite exists and runs
- [ ] All tests pass against PostgreSQL

**OR**

- [ ] Marked as N/A (no original test suite)

**Result:** ☐ PASS ☐ FAIL ☐ N/A

---

## Common Issues and Troubleshooting

### Issue: Connection Refused
**Cause:** PostgreSQL not running or wrong host/port
**Solution:**
```bash
# Check if PostgreSQL is running
pg_isready

# Start PostgreSQL
# macOS: brew services start postgresql@16
# Linux: sudo systemctl start postgresql
```

### Issue: Authentication Failed
**Cause:** Wrong username/password or missing pg_hba.conf entry
**Solution:**
```bash
# Check pg_hba.conf for authentication rules
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Add or modify line:
# local   all   postgres   trust
# host    all   all        127.0.0.1/32   md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Issue: Schema Not Found
**Cause:** Script not executed or executed on wrong database
**Solution:**
```sql
-- Connect to correct database
\c productmanagement

-- Verify schema exists
\dn

-- If missing, run the setup script again
\i Database/Scripts/01_PostgreSQL_Setup.sql
```

### Issue: RETURNING Clause Not Working
**Cause:** Incorrect SQL syntax or Npgsql version issue
**Solution:**
- Verify Npgsql package version is 8.0.5 or higher
- Check that ExecuteScalarAsync() is used for RETURNING queries
- Verify parameter names match exactly (@Name, not @name)

### Issue: Window Functions Return Wrong Results
**Cause:** Data set differences or NULLS FIRST/LAST behavior
**Solution:**
- Verify data matches expected test data
- Check for NULL values in calculations
- Review NULLS FIRST ordering (PostgreSQL default differs from SQL Server)
- Test with known data sets

### Issue: Transaction Deadlock
**Cause:** Concurrent transactions accessing same rows
**Solution:**
- Implement retry logic for deadlock exceptions
- Use shorter transactions
- Consider row-level locking if needed
- Review transaction isolation level

---

## Performance Validation (Optional but Recommended)

### Query Performance Testing
Compare execution times between SQL Server and PostgreSQL:

1. **Enable query timing in psql:**
   ```sql
   \timing on
   ```

2. **Test each query:**
   ```sql
   EXPLAIN ANALYZE 
   SELECT ... FROM productmanagement_dbo.products ...;
   ```

3. **Look for:**
   - Seq Scan vs Index Scan
   - Join strategies
   - Window function performance
   - Overall execution time

### Performance Optimization Tips
- Create indexes on frequently queried columns
- Analyze tables after data loads: `ANALYZE productmanagement_dbo.products;`
- Consider materialized views for complex CTEs
- Use `EXPLAIN ANALYZE` to identify slow queries
- Monitor with pg_stat_statements extension

---

## Final Validation Report Template

After completing all testing, document your results:

```markdown
# Runtime Validation Results

**Date:** [Date]
**Validator:** [Your Name]
**PostgreSQL Version:** [Version]

## Exit Criterion 12: Database Connectivity
**Status:** PASS / FAIL
**Notes:** [Any issues encountered and how resolved]

## Exit Criterion 13: Database Operations
**Status:** PASS / FAIL
**Operations Tested:**
- GetAllProductsAsync: PASS / FAIL
- GetProductByIdAsync: PASS / FAIL
- InsertProductAsync: PASS / FAIL
- UpdateProductAsync: PASS / FAIL
- DeleteProductAsync: PASS / FAIL
- GetProductsByPriceRangeAsync: PASS / FAIL
- GetLowStockProductsAsync: PASS / FAIL

**Notes:** [Any issues or observations]

## Exit Criterion 14: Transaction Atomicity
**Status:** PASS / FAIL
**Tests Performed:**
- Successful commits: PASS / FAIL
- Rollback on failure: PASS / FAIL
- Database consistency: PASS / FAIL

**Notes:** [Any issues or observations]

## Exit Criterion 15: Automated Tests
**Status:** PASS / FAIL / N/A
**Notes:** [Test suite status and results]

## Overall Runtime Validation Status
**Result:** COMPLETE / INCOMPLETE
**Pass Rate:** X/4 criteria passed

## Recommendations
[Any recommendations for production deployment]
```

---

## Contact and Support

For issues with:
- **PostgreSQL setup:** https://www.postgresql.org/support/
- **Npgsql driver:** https://www.npgsql.org/doc/
- **.NET runtime:** https://docs.microsoft.com/en-us/dotnet/

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- AWS DMS Best Practices: https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html
- SQL Server to PostgreSQL Migration Guide: https://wiki.postgresql.org/wiki/Converting_from_other_Databases_to_PostgreSQL
