# PostgreSQL Migration Runtime Validation Guide

## Overview
This guide provides step-by-step instructions for validating the migrated ADO.NET application against the remaining exit criteria (12-15) that require runtime testing with a live PostgreSQL database.

## Prerequisites
1. PostgreSQL database server installed (version 12 or higher recommended)
2. PostgreSQL client tools (psql or pgAdmin)
3. .NET SDK installed (version matching the project)
4. Access to create databases and tables

## Environment Setup

### Step 1: Install PostgreSQL
If not already installed:
- **Windows**: Download from https://www.postgresql.org/download/windows/
- **macOS**: `brew install postgresql@15`
- **Linux**: `sudo apt-get install postgresql-15` (Ubuntu/Debian)

### Step 2: Start PostgreSQL Service
```bash
# Windows (run as Administrator)
net start postgresql-x64-15

# macOS
brew services start postgresql@15

# Linux
sudo systemctl start postgresql
```

### Step 3: Create Database and Schema
```bash
# Connect to PostgreSQL
psql -U postgres

# Run the initialization script
\i Database/Scripts/01_PostgreSQL_InitialSetup.sql

# Verify tables were created
\dt
\q
```

Or using the command line:
```bash
# Create database
createdb -U postgres ProductManagement

# Initialize schema
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

### Step 4: Update Connection String (if needed)
Edit `appsettings.json` to match your PostgreSQL configuration:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
  },
  "Environment": "Development"
}
```

## Validation Testing

### Criterion 12: Database Connection Testing

**Objective**: Verify the application successfully connects to PostgreSQL

**Test Procedure**:
```bash
# Build the application
dotnet build

# Run the application
dotnet run

# Expected outcome: Application starts without connection errors
# Look for any connection-related exceptions in the console output
```

**Validation Checklist**:
- [ ] Application starts without throwing connection exceptions
- [ ] No "Connection refused" or "Authentication failed" errors
- [ ] Connection string is properly parsed and used
- [ ] Connection pooling works correctly

**Expected Evidence**:
- Application console output showing successful startup
- No PostgreSQL connection errors in logs
- Screenshot or log file showing successful connection

---

### Criterion 13: Database Operations Testing

**Objective**: Verify all CRUD operations execute successfully

**Test Procedure**:
Run the application interactively and test each operation:

```bash
dotnet run
```

**Test Case 1: GetAllProductsAsync (Statement 1 - ERROR equivalency status)**
```
Menu Option: 1 (List all products)
Expected: Display list of 18 products with price categories
Verify: No SQL errors, window functions work correctly
```

**Test Case 2: GetProductByIdAsync (Statement 2 - ERROR equivalency status)**
```
Menu Option: 2 (View product details)
Input: ProductId = 1
Expected: Display product details with price change percentage
Verify: LAG window function works correctly
```

**Test Case 3: InsertProductAsync (Statement 3 - ERROR equivalency status)**
```
Menu Option: 3 (Add new product)
Input: Name="Test Product", Description="Test", Price=99.99, Stock=10
Expected: Product created successfully, new ProductId returned
Verify: RETURNING clause captures ProductId correctly
Verify: ProductHistory record created
Verify: ProductStats updated
```

**Test Case 4: UpdateProductAsync (Statement 4 - EQUIVALENT status)**
```
Menu Option: 4 (Update product)
Input: ProductId=1, modify price or stock
Expected: Product updated successfully
Verify: ProductHistory record created with old/new values
Verify: ProductStats recalculated correctly
```

**Test Case 5: DeleteProductAsync (Statement 5 - EQUIVALENT status)**
```
Menu Option: 5 (Delete product)
Input: ProductId of test product created earlier
Expected: Product deleted successfully
Verify: ProductHistory record created
Verify: ProductStats updated (total count decremented)
```

**Test Case 6: GetProductsByPriceRangeAsync (Statement 6 - ERROR equivalency status)**
```
Menu Option: 6 (Search products by price range)
Input: MinPrice=100, MaxPrice=500
Expected: Display products in range with price segments
Verify: RANK and PERCENT_RANK window functions work correctly
```

**Test Case 7: GetLowStockProductsAsync (Statement 7 - ERROR equivalency status)**
```
Menu Option: 7 (View low stock products)
Input: Threshold=10
Expected: Display products with stock <= threshold
Verify: Window functions (AVG, MIN, MAX OVER) work correctly
```

**Validation Checklist**:
- [ ] All SELECT statements execute without errors
- [ ] INSERT returns correct ProductId using RETURNING clause
- [ ] UPDATE modifies data correctly
- [ ] DELETE removes data correctly
- [ ] Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) return expected results
- [ ] CTEs (Common Table Expressions) execute correctly
- [ ] Parameters are properly bound (@ProductId, @MinPrice, etc.)
- [ ] All 5 statements with ERROR equivalency status work correctly despite formal verification failure

**Expected Evidence**:
- Screenshots or logs of each operation succeeding
- Sample output data from SELECT queries
- Confirmation of data persistence (check via psql)

---

### Criterion 14: Transaction Atomicity Testing

**Objective**: Verify transaction commit and rollback maintain data integrity

**Test Procedure**:

**Test Case 1: Successful Transaction (InsertProductAsync)**
```bash
# Use psql to monitor
psql -U postgres -d ProductManagement

# In separate terminal, run application and insert product
dotnet run
# Select option 3 (Add product) and complete normally

# In psql, verify:
SELECT COUNT(*) FROM Products WHERE Name = 'Test Product';  -- Should be 1
SELECT COUNT(*) FROM ProductHistory WHERE Action = 'INSERT'; -- Should have new record
SELECT TotalProducts FROM ProductStats WHERE StatId = 1;     -- Should be incremented
```

**Test Case 2: Transaction Rollback (Simulated Error)**
To properly test rollback, you would need to:
1. Temporarily modify code to throw exception after first INSERT
2. Run the operation
3. Verify no partial data was committed

**Validation Checklist**:
- [ ] Successful transactions commit all changes atomically
- [ ] Failed transactions rollback completely (no partial commits)
- [ ] InsertProductAsync: All 3 operations (INSERT, history, stats) committed together
- [ ] UpdateProductAsync: All 3 operations (SELECT, UPDATE, INSERT history, UPDATE stats) committed together
- [ ] DeleteProductAsync: All 3 operations (SELECT, INSERT history, DELETE, UPDATE stats) committed together
- [ ] No orphaned records in dependent tables after rollback

**Expected Evidence**:
- Database queries showing atomic commits
- Test results showing no partial data after forced errors
- Transaction log output confirming commit/rollback operations

---

### Criterion 15: Test Suite Execution

**Objective**: Run all unit and integration tests against PostgreSQL

**Test Procedure**:

**Step 1: Check for existing tests**
```bash
# Search for test projects
find . -name "*.Tests.csproj" -o -name "*.Test.csproj"

# Or check solution for test projects
dotnet sln list
```

**Step 2: Run tests (if they exist)**
```bash
# Run all tests
dotnet test

# Run with detailed output
dotnet test --verbosity detailed

# Run with code coverage
dotnet test --collect:"XPlat Code Coverage"
```

**Current Status**: No test projects found in the repository

**Validation Checklist**:
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Tests connect to PostgreSQL successfully
- [ ] Tests clean up test data after execution
- [ ] Code coverage meets project standards

**Expected Evidence**:
- Test execution report showing pass/fail counts
- Test output logs
- Code coverage report (if applicable)

**Note**: If no tests exist, this criterion requires creating a test suite or documenting the absence of tests as acceptable per project standards.

---

## Validation Results Documentation

### Success Criteria Summary
After completing all tests, document results:

1. **Criterion 12 - Database Connection**: PASS/FAIL
   - Evidence: [Describe or attach evidence]
   
2. **Criterion 13 - Database Operations**: PASS/FAIL
   - Statement 1 (GetAllProductsAsync): PASS/FAIL
   - Statement 2 (GetProductByIdAsync): PASS/FAIL
   - Statement 3 (InsertProductAsync): PASS/FAIL
   - Statement 4 (UpdateProductAsync): PASS/FAIL
   - Statement 5 (DeleteProductAsync): PASS/FAIL
   - Statement 6 (GetProductsByPriceRangeAsync): PASS/FAIL
   - Statement 7 (GetLowStockProductsAsync): PASS/FAIL
   - Evidence: [Describe or attach evidence]
   
3. **Criterion 14 - Transaction Atomicity**: PASS/FAIL
   - Evidence: [Describe or attach evidence]
   
4. **Criterion 15 - Test Suite Execution**: PASS/FAIL/NOT_APPLICABLE
   - Evidence: [Describe or attach evidence]

---

## Troubleshooting

### Common Issues

**Issue 1: "Connection refused"**
```
Solution: Ensure PostgreSQL is running
- Windows: Check Services panel
- macOS/Linux: sudo systemctl status postgresql
```

**Issue 2: "Authentication failed"**
```
Solution: Check connection string username/password
- Verify credentials in appsettings.json
- Check pg_hba.conf for authentication method
```

**Issue 3: "relation does not exist"**
```
Solution: Schema not initialized
- Run 01_PostgreSQL_InitialSetup.sql script
- Verify tables with: psql -d ProductManagement -c "\dt"
```

**Issue 4: "RETURNING clause not returning value"**
```
Solution: Ensure ExecuteScalarAsync is used
- Check InsertProductAsync implementation
- Verify NpgsqlCommand.ExecuteScalarAsync() is called
```

**Issue 5: Window functions not working**
```
Solution: PostgreSQL version compatibility
- Ensure PostgreSQL 9.4+ (window functions support)
- Check query syntax matches PostgreSQL dialect
```

---

## Additional Considerations

### Security
- Use secure credentials in production
- Implement proper connection string encryption
- Apply principle of least privilege for database user

### Performance
- Monitor query execution times
- Check query plans: EXPLAIN ANALYZE <query>
- Verify indexes are created correctly
- Ensure connection pooling is enabled

### Npgsql Version
Current: 8.0.0 (has security vulnerability NU1903)
Recommendation: Consider upgrading to latest stable version

### Statement Equivalency Notes
- 5 out of 7 statements have ERROR equivalency status (tool returned UNKNOWN)
- These statements are syntactically identical or use equivalent PostgreSQL constructs
- Functional testing is critical to verify runtime correctness
- Statements 4 and 5 (UPDATE and DELETE) were validated as EQUIVALENT by the tool

---

## Completion Checklist

- [ ] PostgreSQL database installed and running
- [ ] Database schema initialized from script
- [ ] Connection string configured correctly
- [ ] Application builds without errors (already validated)
- [ ] Application connects to PostgreSQL (Criterion 12)
- [ ] All 7 database operations tested and working (Criterion 13)
- [ ] Transaction atomicity verified (Criterion 14)
- [ ] Test suite executed or documented as N/A (Criterion 15)
- [ ] All validation results documented
- [ ] Evidence collected (logs, screenshots, query results)

---

## Next Steps After Validation

1. Document all test results in validation summary
2. Update OVERALL STATUS from PARTIAL to PASS (if all criteria met)
3. Address any failed tests or issues discovered
4. Consider upgrading Npgsql to address security vulnerability
5. Implement unit/integration tests if they don't exist
6. Deploy to staging environment for further validation
7. Conduct performance testing under load
8. Create migration runbook for production deployment
