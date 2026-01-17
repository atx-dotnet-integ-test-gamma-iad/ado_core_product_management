# Runtime Validation Guide for ADO.NET PostgreSQL Migration

## Overview
This guide provides step-by-step instructions for completing the runtime validation of criteria 12-15, which could not be validated during the build-time transformation phase.

## Current Status
- **Build-time Validation**: 12/16 criteria PASSED (100% complete)
- **Runtime Validation**: 0/4 criteria validated (requires live PostgreSQL database)

## Failed Criteria Requiring Runtime Validation

### Criterion 12: Application successfully connects to PostgreSQL database
**Status**: FAIL (requires runtime testing)  
**Why Failed**: No live PostgreSQL database available in build environment

### Criterion 13: All database operations execute successfully against PostgreSQL database
**Status**: FAIL (requires runtime testing)  
**Why Failed**: Cannot test CRUD operations without live database

### Criterion 14: Transaction blocks maintain atomicity when executed against PostgreSQL
**Status**: FAIL (requires runtime testing)  
**Why Failed**: Cannot test COMMIT/ROLLBACK behavior without live database

### Criterion 15: Application passes all existing unit tests and integration tests
**Status**: FAIL (no tests exist)  
**Why Failed**: CLI application has no unit or integration tests

## Prerequisites for Runtime Validation

### 1. PostgreSQL Installation
Ensure PostgreSQL 12+ is installed and running:
```bash
# Check PostgreSQL version
psql --version

# Check if PostgreSQL service is running
# Linux/Mac:
sudo systemctl status postgresql
# or
pg_ctl status

# Windows:
# Check Services panel for "postgresql-x64-XX" service
```

### 2. Database Setup
The migration includes a PostgreSQL setup script that must be executed:

**Location**: `Database/Scripts/01_PostgreSQL_Setup.sql`

**Execute the script**:
```bash
# Method 1: Using psql command line
psql -U postgres -d postgres -f Database/Scripts/01_PostgreSQL_Setup.sql

# Method 2: Using psql interactive
psql -U postgres
# Then in psql:
# CREATE DATABASE "ProductManagement";
# \c ProductManagement
# \i Database/Scripts/01_PostgreSQL_Setup.sql
```

**The script creates**:
- Schema: `productmanagement_dbo`
- Tables: `categories`, `suppliers`, `products`, `producthistory`, `productstats`
- Sample data: 20 categories, 8 suppliers, 18 products
- Indexes and constraints
- Trigger for automatic history tracking

### 3. Connection String Configuration
The application is pre-configured with PostgreSQL connection strings in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Timeout=30",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Timeout=30"
  }
}
```

**Update if needed**:
- Change `Host` if PostgreSQL is on a different machine
- Change `Port` if using non-default port
- Change `Username` and `Password` to match your PostgreSQL credentials
- Change `Database` if you used a different database name

## Runtime Validation Test Plan

### Test 1: Database Connection (Criterion 12)

**Objective**: Verify the application can successfully connect to PostgreSQL

**Steps**:
1. Ensure PostgreSQL database is running with schema created
2. Run the application:
   ```bash
   cd sourceCode
   dotnet run
   ```
3. Select option "1" from the menu to view all products
4. If products are displayed, connection is successful

**Expected Result**:
- Application connects without errors
- Product list is displayed
- No connection timeout or authentication errors

**Success Criteria**:
- ✅ No connection exceptions
- ✅ Data retrieved from PostgreSQL database
- ✅ Connection pooling working correctly

---

### Test 2: SELECT Operations (Part of Criterion 13)

**Objective**: Verify all SELECT queries execute correctly

**Test Cases**:

#### 2.1 GetAllProductsAsync (with CTE and Window Functions)
```bash
# In application menu, select: 1
# Expected: List of all 18 products with price categories
```
**Validates**:
- CTE (WITH ProductStats)
- Window functions (AVG OVER, COUNT OVER)
- CASE expressions
- Complex JOINs
- ORDER BY with CASE

#### 2.2 GetProductByIdAsync (with LAG Window Function)
```bash
# In application menu, select: 2
# Enter ProductId: 1
# Expected: Product details with price history comparison
```
**Validates**:
- LAG window function
- LEFT JOIN with CTE
- Parameter binding (@ProductId)
- Complex calculated fields

#### 2.3 GetProductsByPriceRangeAsync (with RANK and PERCENT_RANK)
```bash
# In application menu, select: 6
# Enter MinPrice: 100
# Enter MaxPrice: 500
# Expected: Products in range with price rankings and segments
```
**Validates**:
- RANK() window function
- PERCENT_RANK() window function
- BETWEEN clause with parameters
- Price segmentation logic

#### 2.4 GetLowStockProductsAsync (with Multiple Window Functions)
```bash
# In application menu, select: 7
# Enter Threshold: 10
# Expected: Products with stock <= 10, with stock analysis
```
**Validates**:
- Multiple window functions (AVG, MIN, MAX OVER)
- Stock status categorization
- Percentage calculations

**Success Criteria for Test 2**:
- ✅ All SELECT queries return correct results
- ✅ Window functions produce expected rankings and aggregations
- ✅ CTEs execute without errors
- ✅ Parameter binding works correctly
- ✅ No data type conversion errors

---

### Test 3: INSERT Operations (Part of Criterion 13)

**Objective**: Verify INSERT with RETURNING clause works correctly

**Test Case**: InsertProductAsync

```bash
# In application menu, select: 3
# Enter Product Name: Test Laptop
# Enter Description: Test description for validation
# Enter Price: 1299.99
# Enter Stock Quantity: 15
```

**Expected Result**:
- New product inserted successfully
- Product ID returned via RETURNING clause
- ProductHistory record created (via trigger or application code)
- ProductStats updated with new totals

**Validation Queries** (run in psql):
```sql
-- Verify product was inserted
SELECT * FROM productmanagement_dbo.products 
WHERE name = 'Test Laptop';

-- Verify history record was created
SELECT * FROM productmanagement_dbo.producthistory 
WHERE action = 'INSERT' 
ORDER BY actiondate DESC LIMIT 1;

-- Verify stats were updated
SELECT * FROM productmanagement_dbo.productstats 
WHERE statid = 1;
```

**Success Criteria**:
- ✅ Product inserted successfully
- ✅ RETURNING clause returns new productid
- ✅ History tracking works
- ✅ Statistics updated correctly
- ✅ No SCOPE_IDENTITY() errors (converted to RETURNING)

---

### Test 4: UPDATE Operations (Part of Criterion 13 & Criterion 14)

**Objective**: Verify UPDATE with transaction management works correctly

**Test Case**: UpdateProductAsync

```bash
# In application menu, select: 4
# Enter ProductId: 1 (or ID from Test 3)
# Enter Product Name: Updated Laptop
# Enter Description: Updated description
# Enter Price: 1399.99
# Enter Stock Quantity: 12
```

**Expected Result**:
- Product updated successfully
- ProductHistory record created with old and new values
- ProductStats recalculated with new price
- Transaction commits successfully

**Validation Queries**:
```sql
-- Verify product was updated
SELECT * FROM productmanagement_dbo.products 
WHERE productid = 1;

-- Verify history shows UPDATE action
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = 1 AND action = 'UPDATE'
ORDER BY actiondate DESC LIMIT 1;

-- Check modifieddate was updated
SELECT productid, name, modifieddate 
FROM productmanagement_dbo.products 
WHERE productid = 1;
```

**Success Criteria**:
- ✅ Product updated successfully
- ✅ Old values captured before update
- ✅ History record includes both old and new values
- ✅ ModifiedDate updated to CURRENT_TIMESTAMP
- ✅ Transaction completed atomically
- ✅ No embedded transaction syntax errors (BEGIN TRANSACTION/COMMIT removed)

---

### Test 5: DELETE Operations (Part of Criterion 13 & Criterion 14)

**Objective**: Verify DELETE with transaction management works correctly

**Test Case**: DeleteProductAsync

```bash
# In application menu, select: 5
# Enter ProductId: [ID from Test 3]
```

**Expected Result**:
- Product deleted successfully
- ProductHistory record created with DELETE action and old values
- ProductStats decremented
- Transaction commits successfully

**Validation Queries**:
```sql
-- Verify product was deleted
SELECT COUNT(*) FROM productmanagement_dbo.products 
WHERE productid = [test_product_id];
-- Should return 0

-- Verify history shows DELETE action
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = [test_product_id] AND action = 'DELETE';

-- Verify stats were decremented
SELECT totalproducts FROM productmanagement_dbo.productstats 
WHERE statid = 1;
```

**Success Criteria**:
- ✅ Product deleted successfully
- ✅ History record created before deletion
- ✅ Statistics updated correctly
- ✅ Transaction completed atomically
- ✅ Foreign key constraints respected

---

### Test 6: Transaction Atomicity (Criterion 14)

**Objective**: Verify transactions maintain atomicity with COMMIT and ROLLBACK

**Test Case 6.1**: Successful Transaction (from Tests 3, 4, 5 above)
- All multi-statement operations should complete fully or not at all
- ProductHistory and ProductStats should stay in sync with Products

**Test Case 6.2**: Rollback on Error (Manual Testing Required)

This requires code modification to force an error mid-transaction:

```csharp
// Temporary test in ProductRepository.cs - UpdateProductAsync method
// Add after the UPDATE statement but before commit:
throw new Exception("Forced error to test rollback");
```

**Steps**:
1. Temporarily add the exception to force rollback
2. Attempt an update operation
3. Verify no changes persisted (transaction rolled back)
4. Remove the exception

**Expected Result**:
- Transaction rolls back on error
- No partial updates in database
- Product, ProductHistory, and ProductStats remain consistent
- No orphaned records

**Validation**:
```sql
-- Check that no partial updates occurred
-- Product should have original values
-- History should not have incomplete records
SELECT * FROM productmanagement_dbo.products WHERE productid = [test_id];
SELECT * FROM productmanagement_dbo.producthistory WHERE productid = [test_id] ORDER BY actiondate DESC;
```

**Success Criteria**:
- ✅ NpgsqlTransaction.BeginTransactionAsync() works correctly
- ✅ NpgsqlTransaction.CommitAsync() persists all changes
- ✅ NpgsqlTransaction.RollbackAsync() reverts all changes on error
- ✅ No partial transaction commits
- ✅ Database consistency maintained

---

### Test 7: Integration Test Development (Criterion 15)

**Current State**: No unit tests or integration tests exist in the project

**Options**:

#### Option A: Accept Manual Testing as Sufficient
- Document all manual test results from Tests 1-6
- Create a test results report
- Mark Criterion 15 as "Not Applicable - Manual Testing Completed"

#### Option B: Develop Integration Tests (Recommended for Production)

Create integration tests using xUnit or NUnit:

```bash
# Add test project
dotnet new xunit -n AdoCore.IntegrationTests
dotnet add AdoCore.IntegrationTests reference AdoCore.csproj
dotnet add AdoCore.IntegrationTests package Npgsql
```

**Sample Test Structure**:
```csharp
public class ProductRepositoryIntegrationTests : IDisposable
{
    private readonly ProductRepository _repository;
    private readonly string _testConnectionString;
    
    [Fact]
    public async Task GetAllProductsAsync_ReturnsProducts()
    {
        // Arrange
        // Act
        var products = await _repository.GetAllProductsAsync();
        // Assert
        Assert.NotEmpty(products);
        Assert.All(products, p => Assert.NotNull(p.Name));
    }
    
    [Fact]
    public async Task InsertProductAsync_ReturnsNewProductId()
    {
        // Arrange
        var product = new Product { Name = "Test", Price = 100, StockQuantity = 10 };
        // Act
        var newId = await _repository.InsertProductAsync(product);
        // Assert
        Assert.True(newId > 0);
    }
    
    // Add tests for Update, Delete, Transactions, etc.
}
```

**Success Criteria for Option B**:
- ✅ All CRUD operations have integration tests
- ✅ Transaction tests verify atomicity
- ✅ All tests pass against PostgreSQL database
- ✅ Tests can run in CI/CD pipeline

---

## Validation Checklist

Use this checklist to track validation progress:

### Criterion 12: Database Connection
- [ ] PostgreSQL database created and running
- [ ] Schema `productmanagement_dbo` created
- [ ] Tables created successfully
- [ ] Application connects without errors
- [ ] Connection string configuration correct
- [ ] Connection pooling working

### Criterion 13: Database Operations
**SELECT Operations:**
- [ ] GetAllProductsAsync with CTEs and window functions
- [ ] GetProductByIdAsync with LAG window function
- [ ] GetProductsByPriceRangeAsync with RANK and PERCENT_RANK
- [ ] GetLowStockProductsAsync with multiple window functions

**INSERT Operations:**
- [ ] InsertProductAsync with RETURNING clause
- [ ] ProductHistory record created
- [ ] ProductStats updated

**UPDATE Operations:**
- [ ] UpdateProductAsync executes successfully
- [ ] Old values captured correctly
- [ ] ProductHistory updated
- [ ] ModifiedDate updated

**DELETE Operations:**
- [ ] DeleteProductAsync executes successfully
- [ ] ProductHistory records deletion
- [ ] ProductStats decremented

### Criterion 14: Transaction Atomicity
- [ ] Successful transactions commit all changes
- [ ] Failed transactions rollback completely
- [ ] No partial transaction commits
- [ ] Database consistency maintained
- [ ] NpgsqlTransaction APIs work correctly

### Criterion 15: Tests
**Option A - Manual Testing:**
- [ ] All manual tests documented
- [ ] Test results recorded
- [ ] Edge cases tested

**Option B - Integration Tests:**
- [ ] Integration test project created
- [ ] Tests written for all operations
- [ ] All tests pass
- [ ] Tests integrated into build process

---

## Validation Report Template

After completing runtime validation, document results using this template:

```
RUNTIME VALIDATION RESULTS
Date: [Date]
Tester: [Name]
Environment: [PostgreSQL version, OS, etc.]

CRITERION 12: DATABASE CONNECTION
Status: [PASS/FAIL]
Evidence: [Description of test results]
Notes: [Any issues or observations]

CRITERION 13: DATABASE OPERATIONS
Status: [PASS/FAIL]
SELECT Operations: [PASS/FAIL] - [Details]
INSERT Operations: [PASS/FAIL] - [Details]
UPDATE Operations: [PASS/FAIL] - [Details]
DELETE Operations: [PASS/FAIL] - [Details]
Notes: [Any issues or observations]

CRITERION 14: TRANSACTION ATOMICITY
Status: [PASS/FAIL]
COMMIT behavior: [PASS/FAIL] - [Details]
ROLLBACK behavior: [PASS/FAIL] - [Details]
Notes: [Any issues or observations]

CRITERION 15: TESTS
Status: [PASS/FAIL/NOT_APPLICABLE]
Approach: [Manual Testing / Integration Tests]
Results: [Details]
Notes: [Any issues or observations]

OVERALL RUNTIME VALIDATION STATUS: [PASS/FAIL]
OVERALL TRANSFORMATION STATUS: [COMPLETE/INCOMPLETE]
```

---

## Troubleshooting Common Issues

### Issue 1: Connection Failed
**Error**: "Could not connect to server" or "Connection refused"

**Solutions**:
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check port 5432 is listening: `netstat -an | grep 5432`
- Verify connection string in appsettings.json
- Check PostgreSQL pg_hba.conf allows local connections
- Test connection with psql: `psql -U postgres -d ProductManagement`

### Issue 2: Authentication Failed
**Error**: "password authentication failed for user"

**Solutions**:
- Update password in appsettings.json
- Verify user exists: `psql -U postgres -c "\du"`
- Check pg_hba.conf authentication method
- Reset password if needed: `ALTER USER postgres PASSWORD 'newpassword';`

### Issue 3: Schema Not Found
**Error**: "schema productmanagement_dbo does not exist"

**Solutions**:
- Run the PostgreSQL setup script
- Verify schema exists: `psql -U postgres -d ProductManagement -c "\dn"`
- Check search_path in connection string

### Issue 4: Window Functions Not Working
**Error**: "window function call requires an OVER clause"

**Solutions**:
- Verify PostgreSQL version >= 9.3 (window functions)
- Check SQL syntax matches PostgreSQL conventions
- Review converted_statements.sql for correct syntax

### Issue 5: RETURNING Clause Not Working
**Error**: "syntax error at or near 'RETURNING'"

**Solutions**:
- Verify using PostgreSQL 8.2+
- Check INSERT statement includes RETURNING clause
- Verify command execution captures returned value

---

## Next Steps After Validation

1. **If All Tests Pass**:
   - Update validation_summary.md with PASS status for criteria 12-15
   - Mark overall transformation status as COMPLETE
   - Proceed to production deployment planning

2. **If Some Tests Fail**:
   - Document failures in detail
   - Analyze root cause (conversion error vs. environmental issue)
   - Fix issues and re-test
   - Update validation_summary.md

3. **For Production Deployment**:
   - Create production PostgreSQL database
   - Run setup script in production
   - Update production connection strings
   - Perform smoke testing
   - Monitor application logs
   - Set up database backups

---

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- Window Functions Guide: https://www.postgresql.org/docs/current/tutorial-window.html
- Transaction Management: https://www.postgresql.org/docs/current/tutorial-transactions.html

---

## Contact and Support

For issues or questions regarding this migration:
- Review dms_conversion_log.txt for SQL conversion details
- Review sql_equivalency_validation_report.json for statement analysis
- Consult AWS DMS documentation for schema transformation guidance
