# Database Testing Guide

This guide provides step-by-step instructions for validating the migration from SQL Server to PostgreSQL.

## Prerequisites

1. PostgreSQL 12+ installed and running
2. .NET 9.0 SDK installed
3. Database administrator access to PostgreSQL
4. Connection to PostgreSQL server (default: localhost:5432)

## Testing Roadmap

The following tests must be performed to validate exit criteria 12-15:

### Exit Criterion 12: Application Successfully Connects to PostgreSQL Database

**Objective**: Verify that the application can establish a connection to the PostgreSQL database.

**Steps**:

1. **Setup PostgreSQL Database**
   ```bash
   # Start PostgreSQL service
   sudo systemctl start postgresql
   
   # Connect to PostgreSQL
   psql -U postgres
   ```

2. **Run Database Setup Script**
   ```bash
   cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/Database
   psql -U postgres -f setup_scripts.sql
   ```

3. **Update Connection String** (if needed)
   Edit `appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;"
     }
   }
   ```

4. **Test Connection**
   ```bash
   cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
   dotnet run
   ```
   
   **Expected Result**: Application starts without connection errors and displays menu.

5. **Document Results**
   - ✅ Connection successful → Mark criterion as PASS
   - ❌ Connection failed → Document error message, mark as FAIL

---

### Exit Criterion 13: All Database Operations Execute Successfully

**Objective**: Verify that all CRUD operations work correctly against PostgreSQL.

**Operations to Test**:

1. **GetAllProductsAsync** - Complex CTE query
   ```bash
   # In application menu, select option to view all products
   ```
   **Verification**: 
   - Products list displayed
   - No SQL syntax errors
   - Data retrieved correctly

2. **GetProductByIdAsync** - Single record retrieval
   ```bash
   # Select option to view product by ID, enter ID: 1
   ```
   **Verification**:
   - Product details displayed
   - Correct product returned

3. **InsertProductAsync** - INSERT with RETURNING clause
   ```bash
   # Select option to add new product
   # Enter: Name="Test Product", Price=99.99, Stock=100
   ```
   **Verification**:
   - New product ID returned
   - Product inserted successfully
   - RETURNING clause works

4. **UpdateProductAsync** - UPDATE operation
   ```bash
   # Select option to update product
   # Enter product ID and new values
   ```
   **Verification**:
   - Update successful message
   - Changes reflected in database

5. **DeleteProductAsync** - DELETE operation
   ```bash
   # Select option to delete product
   # Enter product ID to delete
   ```
   **Verification**:
   - Delete successful message
   - Product removed from database

6. **GetProductsByPriceRangeAsync** - Range query with window functions
   ```bash
   # Select option to search by price range
   # Enter min=10, max=100
   ```
   **Verification**:
   - Products within range returned
   - Window functions calculate correctly
   - No SQL errors

7. **GetLowStockProductsAsync** - Filtered query with multiple conditions
   ```bash
   # Select option to view low stock products
   # Enter threshold: 20
   ```
   **Verification**:
   - Products with stock <= 20 returned
   - Query executes without errors

**Document Results**:
- Create a test results table with each operation's status
- Take screenshots or save output logs
- Mark criterion as PASS if all 7 operations succeed

---

### Exit Criterion 14: Transaction Blocks Maintain Atomicity

**Objective**: Verify that PostgreSQL transactions commit and rollback correctly.

**Test Cases**:

1. **Transaction Commit Test**
   ```bash
   # Use ExecuteInTransactionAsync to insert multiple products
   # Verify both products are inserted
   ```
   
   **Verification Steps**:
   - Insert 2 products in a transaction
   - Commit transaction
   - Query database to verify both products exist
   - **Expected**: Both products persisted

2. **Transaction Rollback Test**
   ```bash
   # Use ExecuteInTransactionAsync with forced error
   # Verify no products are inserted
   ```
   
   **Verification Steps**:
   - Start transaction
   - Insert product A
   - Insert product B
   - Force an error (e.g., invalid data)
   - Rollback transaction
   - Query database to verify neither product exists
   - **Expected**: Neither product persisted (atomicity maintained)

3. **Concurrent Transaction Test**
   ```bash
   # Run two transactions simultaneously
   # Verify isolation and consistency
   ```
   
   **Verification Steps**:
   - Start transaction T1 (update product 1)
   - Start transaction T2 (update product 1)
   - Commit T1
   - Verify T2 waits or fails appropriately
   - **Expected**: No lost updates, isolation maintained

**SQL Verification Queries**:
```sql
-- Check transaction history
SELECT * FROM public."ProductHistory" 
ORDER BY "ChangedDate" DESC 
LIMIT 10;

-- Verify data consistency
SELECT COUNT(*) FROM public."Products";
```

**Document Results**:
- Record transaction test outcomes
- Save PostgreSQL logs showing transaction behavior
- Mark criterion as PASS if atomicity is maintained

---

### Exit Criterion 15: Application Passes All Tests

**Objective**: Execute test suite and verify all tests pass.

**Steps**:

1. **Enable Tests**
   ```bash
   cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/AdoCore.Tests
   ```
   
   Edit `ProductRepositoryTests.cs` and remove `Skip` attributes from tests.

2. **Run Test Suite**
   ```bash
   dotnet test --verbosity detailed
   ```

3. **Run Individual Tests**
   ```bash
   # Test each operation separately
   dotnet test --filter "GetAllProductsAsync_ShouldReturnProducts"
   dotnet test --filter "InsertProductAsync_WithValidProduct_ShouldReturnNewId"
   dotnet test --filter "UpdateProductAsync_WithValidProduct_ShouldReturnTrue"
   dotnet test --filter "DeleteProductAsync_WithValidId_ShouldReturnTrue"
   dotnet test --filter "ExecuteInTransactionAsync_WithCommit_ShouldPersistChanges"
   dotnet test --filter "ExecuteInTransactionAsync_WithException_ShouldRollback"
   ```

4. **Generate Test Report**
   ```bash
   dotnet test --logger "trx;LogFileName=test_results.trx"
   dotnet test --logger "html;LogFileName=test_results.html"
   ```

**Document Results**:
- Save test output to file
- Record number of passed/failed tests
- Investigate any failures
- Mark criterion as PASS if all tests pass

---

## SQL Equivalency Investigation (Required)

5 SQL statements were marked as ERROR by the SQL Equivalency tool due to complexity (CTEs, window functions). These require manual validation:

### Statement 1: GetAllProductsAsync - CTE with Window Functions
```sql
-- SQL Server Version
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT /* ... */

-- PostgreSQL Version  
WITH ProductStats AS (
    SELECT 
        "ProductId",
        AVG("Price") OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM public."Products"
)
SELECT /* ... */
```

**Manual Test**:
1. Execute both queries against sample datasets
2. Compare result sets (row counts, values, column order)
3. Verify calculations match
4. Document equivalency determination

### Statements 2-5: Similar Complex Queries

Repeat the manual test process for each remaining ERROR statement.

**Equivalency Verification Checklist**:
- [ ] Same number of rows returned
- [ ] Same column names and types
- [ ] Same data values
- [ ] Same calculated fields (AVG, COUNT, etc.)
- [ ] Same ordering (if ORDER BY present)

---

## Final Validation Report

After completing all tests, create a summary document:

### Template:

```markdown
# PostgreSQL Migration Validation Report
Date: [Date]
Tester: [Name]

## Exit Criterion 12: Database Connectivity
Status: [PASS/FAIL]
Evidence: [Description]
Issues: [Any issues encountered]

## Exit Criterion 13: Database Operations
Status: [PASS/FAIL]
Evidence: [Test results for all 7 operations]
Issues: [Any issues encountered]

## Exit Criterion 14: Transaction Atomicity
Status: [PASS/FAIL]
Evidence: [Transaction test results]
Issues: [Any issues encountered]

## Exit Criterion 15: Test Suite
Status: [PASS/FAIL]
Evidence: [X of Y tests passed]
Issues: [Any failures]

## SQL Equivalency Investigation
- Statement 1: [EQUIVALENT/NOT_EQUIVALENT]
- Statement 2: [EQUIVALENT/NOT_EQUIVALENT]
- Statement 3: [EQUIVALENT/NOT_EQUIVALENT]
- Statement 4: [EQUIVALENT/NOT_EQUIVALENT]
- Statement 5: [EQUIVALENT/NOT_EQUIVALENT]

## Overall Assessment
Status: [PASS/FAIL]
Recommendation: [Ready for production / Needs fixes]
```

---

## Troubleshooting Common Issues

### Issue 1: Connection Timeout
**Symptom**: `Npgsql.NpgsqlException: connection timeout`
**Solution**: 
- Check PostgreSQL is running: `sudo systemctl status postgresql`
- Verify port 5432 is open: `netstat -an | grep 5432`
- Check firewall rules

### Issue 2: Authentication Failed
**Symptom**: `password authentication failed for user`
**Solution**:
- Verify password in connection string
- Check pg_hba.conf authentication settings
- Restart PostgreSQL after changes

### Issue 3: Table Not Found
**Symptom**: `relation "Products" does not exist`
**Solution**:
- Verify database name in connection string
- Run setup_scripts.sql to create tables
- Check schema name (public)

### Issue 4: Transaction Deadlock
**Symptom**: `deadlock detected`
**Solution**:
- Run tests sequentially, not in parallel
- Check for long-running transactions
- Review transaction isolation level

### Issue 5: Parameter Binding Error
**Symptom**: `parameter $1 does not exist`
**Solution**:
- Verify parameter names use @ prefix
- Check parameter count matches SQL placeholders
- Ensure parameters are added to NpgsqlCommand

---

## Performance Testing (Optional)

After functional validation, consider performance testing:

1. **Load Testing**: Insert 10,000 products
2. **Query Performance**: Measure query execution times
3. **Connection Pooling**: Test multiple concurrent connections
4. **Index Effectiveness**: Compare query plans with/without indexes

---

## Sign-off

After completing all tests:

- [ ] All database operations tested and working
- [ ] Transaction atomicity verified
- [ ] Test suite passes
- [ ] SQL equivalency manually verified
- [ ] Performance is acceptable
- [ ] Documentation updated

**Migration Status**: [COMPLETE/INCOMPLETE]
**Signed**: ________________  
**Date**: ________________
