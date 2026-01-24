# PostgreSQL Runtime Validation Guide

## Overview
This guide provides step-by-step instructions for completing the runtime validation criteria (12-15) that cannot be automated without a live PostgreSQL database instance.

## Prerequisites

### Required Software
1. **PostgreSQL 12 or later** installed and running
2. **.NET 9.0 SDK** installed
3. **psql** command-line tool or **pgAdmin** for database management

### Required Credentials
- PostgreSQL host, port, database name, username, and password

---

## Step 1: PostgreSQL Database Setup (Criterion 12 - Part 1)

### Option A: Using psql Command Line

```bash
# 1. Create the database (as postgres superuser)
psql -U postgres -c "CREATE DATABASE productmanagement;"

# 2. Run the setup script
psql -U postgres -d productmanagement -f Database/Scripts/01_PostgreSQL_Setup.sql

# 3. Verify the setup
psql -U postgres -d productmanagement -c "SELECT COUNT(*) FROM products;"
```

### Option B: Using pgAdmin

1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" and select "Create" > "Database..."
3. Name it `productmanagement` and click "Save"
4. Open the Query Tool for the new database
5. Open and execute `Database/Scripts/01_PostgreSQL_Setup.sql`
6. Verify by running: `SELECT COUNT(*) FROM products;` (should return 19)

### Expected Results
- Database `productmanagement` created
- Tables created: `categories`, `suppliers`, `products`, `producthistory`, `productstats`
- Sample data inserted: 20 categories, 8 suppliers, 19 products
- Indexes and triggers created successfully

---

## Step 2: Update Connection String (Criterion 12 - Part 2)

Edit `appsettings.json` with your PostgreSQL credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=YOUR_ACTUAL_PASSWORD",
    "ProdConnection": "Host=YOUR_HOST;Port=5432;Database=productmanagement;Username=postgres;Password=YOUR_ACTUAL_PASSWORD"
  },
  "Environment": "Development"
}
```

**Replace:**
- `localhost` with your PostgreSQL host (if not local)
- `YOUR_ACTUAL_PASSWORD` with your actual PostgreSQL password
- `5432` with your PostgreSQL port (if different)

---

## Step 3: Test Database Connectivity (Criterion 12)

### Build and Run the Application

```bash
# Navigate to the source code directory
cd sourceCode

# Build the application
dotnet build AdoCore.csproj

# Run in interactive mode
dotnet run
```

### Expected Output
```
Product Management System
------------------------
1. List all products
2. Get product by ID
3. Create new product
4. Update product
5. Delete product
6. Update product stock
Q. Quit

Enter your choice:
```

### Validation Checkpoint
- ✅ Application starts without connection errors
- ✅ Main menu displays correctly
- ✅ No exceptions thrown during startup

**Document Result:** Note any connection errors or issues in your validation report.

---

## Step 4: Test CRUD Operations (Criterion 13)

### Test 1: SELECT - List All Products (GetAllProductsAsync)

**Command:**
```bash
dotnet run -- list
```

**What to Verify:**
- ✅ Complex CTE query executes successfully
- ✅ Window functions (AVG OVER, COUNT OVER) work correctly
- ✅ Products displayed with price categories ("Above Average", "Below Average", "Average")
- ✅ Price percentage of average calculated correctly
- ✅ Results ordered by price category and name

**Expected Output:** List of 19 products with price analysis

**SQL Statement Tested:** STMT-001 (Complex CTE with window functions)

---

### Test 2: SELECT by ID - Get Product Details (GetProductByIdAsync)

**Command:**
```bash
dotnet run -- get 1
```

**What to Verify:**
- ✅ LAG window function executes successfully
- ✅ Product details displayed correctly
- ✅ Previous price and stock information shown (may be NULL for first product)
- ✅ Price change percentage calculated correctly (if previous price exists)

**Expected Output:** Details for product ID 1 with historical comparison

**SQL Statement Tested:** STMT-002 (LAG window function)

---

### Test 3: INSERT - Create New Product (InsertProductAsync)

**Command:**
```bash
dotnet run -- add "Test Product" 99.99 50 "Test product for validation"
```

**What to Verify:**
- ✅ Product inserted successfully
- ✅ **CRITICAL**: RETURNING clause returns the new ProductId
- ✅ New ProductId displayed in output
- ✅ Product history trigger creates INSERT record
- ✅ Product stats updated correctly

**Verification Query:**
```sql
-- Run in psql or pgAdmin
SELECT * FROM products WHERE name = 'Test Product';
SELECT * FROM producthistory WHERE action = 'INSERT' ORDER BY actiondate DESC LIMIT 1;
```

**Expected Output:** 
```
Product added successfully with ID: [NEW_ID]
```

**SQL Statement Tested:** STMT-003 (CRITICAL - SCOPE_IDENTITY → RETURNING conversion)

---

### Test 4: UPDATE - Modify Product (UpdateProductAsync)

**Command:**
```bash
dotnet run -- update 1 "Updated ProBook X1" 1399.99 20 "Updated high-performance laptop"
```

**What to Verify:**
- ✅ Product updated successfully
- ✅ CURRENT_TIMESTAMP sets ModifiedDate correctly
- ✅ Product history trigger creates UPDATE record
- ✅ Old and new values captured in history

**Verification Query:**
```sql
-- Run in psql or pgAdmin
SELECT * FROM products WHERE productid = 1;
SELECT * FROM producthistory WHERE productid = 1 AND action = 'UPDATE' ORDER BY actiondate DESC LIMIT 1;
```

**Expected Output:**
```
Product updated successfully.
```

**SQL Statement Tested:** STMT-004 (GETDATE → CURRENT_TIMESTAMP conversion)

---

### Test 5: DELETE - Remove Product (DeleteProductAsync)

**Command:**
```bash
# First, create a product to delete
dotnet run -- add "Delete Test" 10.00 1 "Product to delete"

# Note the returned ProductId (let's assume it's 20)
# Then delete it
dotnet run -- delete 20
```

**What to Verify:**
- ✅ Product deleted successfully
- ✅ Product history trigger creates DELETE record
- ✅ Transaction handling works correctly

**Verification Query:**
```sql
-- Run in psql or pgAdmin
SELECT * FROM products WHERE name = 'Delete Test';  -- Should return 0 rows
SELECT * FROM producthistory WHERE action = 'DELETE' ORDER BY actiondate DESC LIMIT 1;
```

**Expected Output:**
```
Product deleted successfully.
```

**SQL Statement Tested:** STMT-005 (Simple DELETE)

---

### Test 6: SELECT with Price Range (GetProductsByPriceRangeAsync)

**Command:**
```bash
dotnet run  # Interactive mode
# Choose option that calls GetProductsByPriceRangeAsync (if available in menu)
# Or run specific test if CLI command exists
```

**Manual Test via C# Code:**
Create a test file `RuntimeTest.cs`:

```csharp
using AdoCore.DataAccess;
using Microsoft.Extensions.Configuration;

var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();

var repository = new ProductRepository(configuration);

// Test GetProductsByPriceRangeAsync
var products = await repository.GetProductsByPriceRangeAsync(100, 500);
Console.WriteLine($"Products in range $100-$500: {products.Count}");
foreach (var p in products)
{
    Console.WriteLine($"  {p.Name}: ${p.Price}");
}
```

**What to Verify:**
- ✅ RANK() window function works correctly
- ✅ PERCENT_RANK() window function works correctly
- ✅ Price segments assigned correctly (Budget/Mid-Range/Premium)
- ✅ Results ordered by price rank

**SQL Statement Tested:** STMT-006 (RANK/PERCENT_RANK window functions)

---

### Test 7: SELECT Low Stock Products (GetLowStockProductsAsync)

**Manual Test via C# Code:**
```csharp
// Test GetLowStockProductsAsync
var lowStockProducts = await repository.GetLowStockProductsAsync(10);
Console.WriteLine($"Low stock products (threshold: 10): {lowStockProducts.Count}");
foreach (var p in lowStockProducts)
{
    Console.WriteLine($"  {p.Name}: {p.StockQuantity} units");
}
```

**What to Verify:**
- ✅ Multiple window functions (AVG, MIN, MAX OVER) work correctly
- ✅ Stock status calculated correctly (Critical/Low/Adequate)
- ✅ Stock percentage of average calculated correctly
- ✅ Results filtered and ordered correctly

**SQL Statement Tested:** STMT-007 (Multiple window functions)

---

## Step 5: Test Transaction Atomicity (Criterion 14)

### Test Scenario 1: Successful Transaction Commit

**Code to Test:**
```csharp
// Modify UpdateProductAsync to wrap multiple operations in a transaction
// Verify both operations commit together
```

**What to Verify:**
- ✅ Transaction begins successfully (NpgsqlTransaction)
- ✅ Multiple operations execute within transaction
- ✅ Transaction commits successfully
- ✅ All changes persisted to database

### Test Scenario 2: Transaction Rollback on Error

**Code to Test:**
```csharp
// Introduce an intentional error (e.g., invalid data) mid-transaction
// Verify rollback occurs
```

**What to Verify:**
- ✅ Transaction begins successfully
- ✅ First operation executes
- ✅ Error occurs on second operation
- ✅ Transaction rolls back automatically
- ✅ No partial changes persisted (database state unchanged)

**Verification:**
```sql
-- Before and after comparison
SELECT * FROM products WHERE productid = [TEST_ID];
SELECT * FROM producthistory WHERE productid = [TEST_ID] ORDER BY actiondate DESC;
```

---

## Step 6: Run Unit/Integration Tests (Criterion 15)

### Note
The current project does not appear to have unit tests or integration tests included.

### If Tests Exist:

```bash
# Run all tests
dotnet test

# Run specific test category
dotnet test --filter Category=Integration

# Run with verbose output
dotnet test -v detailed
```

### If Tests Do Not Exist:

**Document in validation report:**
- "No unit tests or integration tests found in the project"
- "Manual testing of all CRUD operations completed successfully" (if true)
- "Recommend adding test suite for future validation"

---

## Validation Checklist

### Criterion 12: Database Connectivity ✅/❌
- [ ] PostgreSQL database created and schema deployed
- [ ] Connection string configured correctly
- [ ] Application connects to PostgreSQL without errors
- [ ] No connection timeout or authentication issues

### Criterion 13: CRUD Operations ✅/❌
- [ ] GetAllProductsAsync executes (CTE + window functions)
- [ ] GetProductByIdAsync executes (LAG window function)
- [ ] InsertProductAsync executes (RETURNING clause returns ID)
- [ ] UpdateProductAsync executes (CURRENT_TIMESTAMP works)
- [ ] DeleteProductAsync executes successfully
- [ ] GetProductsByPriceRangeAsync executes (RANK/PERCENT_RANK)
- [ ] GetLowStockProductsAsync executes (multiple window functions)

### Criterion 14: Transaction Atomicity ✅/❌
- [ ] Transactions begin successfully (NpgsqlTransaction)
- [ ] Successful transactions commit correctly
- [ ] Failed transactions rollback correctly
- [ ] No partial data persisted on rollback

### Criterion 15: Test Execution ✅/❌
- [ ] Unit tests executed (if exist)
- [ ] Integration tests executed (if exist)
- [ ] All tests pass against PostgreSQL
- [ ] OR: Manual testing completed for all operations

---

## Reporting Results

After completing all tests, document:

1. **Database Setup Result:**
   - Date/time of setup
   - PostgreSQL version
   - Any issues encountered

2. **Connection Test Result:**
   - Success/failure
   - Connection string used (without password)
   - Any errors

3. **CRUD Test Results:**
   - For each operation (GetAll, GetById, Insert, Update, Delete, etc.):
     - Success/failure
     - Execution time
     - Any errors or warnings
     - Sample output

4. **Transaction Test Results:**
   - Commit test: Success/failure
   - Rollback test: Success/failure
   - Any issues observed

5. **Test Execution Results:**
   - Number of tests run
   - Pass/fail count
   - OR: Note that no tests exist and manual testing completed

---

## Common Issues and Solutions

### Issue 1: Connection Refused
**Solution:** Verify PostgreSQL is running and accepting connections on the specified port.
```bash
# Check PostgreSQL status
sudo systemctl status postgresql  # Linux
# OR
pg_isready -h localhost -p 5432    # Cross-platform
```

### Issue 2: Authentication Failed
**Solution:** Verify username/password are correct. May need to edit `pg_hba.conf` to allow password authentication.

### Issue 3: Database Does Not Exist
**Solution:** Ensure database was created successfully. Check connection string database name matches created database.

### Issue 4: Table Does Not Exist
**Solution:** Verify the PostgreSQL setup script ran completely without errors.

### Issue 5: RETURNING Clause Not Working
**Solution:** Verify using Npgsql 8.0+ which fully supports RETURNING clauses.

---

## Success Criteria Summary

### All Runtime Criteria Met When:
1. ✅ Application connects to PostgreSQL database successfully
2. ✅ All 7 SQL statements execute without errors
3. ✅ CRUD operations produce expected results
4. ✅ Transactions commit and rollback correctly
5. ✅ All tests pass (or manual testing confirms functionality)

### Evidence to Collect:
- Screenshots of successful operations
- Console output logs
- Database query results
- Test execution reports
- Any error messages encountered and resolved

---

## Next Steps After Validation

1. Update `validation_summary.md` with runtime test results
2. Update SQL equivalency report if any statements failed
3. Document any code changes needed based on runtime testing
4. Create test suite if one doesn't exist
5. Deploy to production environment if all tests pass

