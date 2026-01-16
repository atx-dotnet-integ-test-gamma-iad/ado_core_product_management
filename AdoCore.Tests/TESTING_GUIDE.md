# Integration Testing Guide for AdoCore PostgreSQL Migration

## Overview
This document provides comprehensive instructions for executing integration tests to verify the successful migration of the AdoCore application from Microsoft SQL Server to PostgreSQL.

## Prerequisites

### 1. PostgreSQL Installation
Install PostgreSQL 12 or higher:

**Windows:**
```bash
# Download from https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql
```

**macOS:**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Docker (Recommended for Testing):**
```bash
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -p 5432:5432 \
  -d postgres:14
```

### 2. Database Setup
Execute the database setup script:

```bash
# Navigate to the test directory
cd AdoCore.Tests

# Run the setup script
psql -U postgres -f DatabaseSetup.sql

# Verify the setup
psql -U postgres -d adocore_test -c "\dt productmanagement_dbo.*"
```

### 3. Verify Connection
Test the connection string:

```bash
psql -U postgres -d adocore_test -c "SELECT current_database(), current_schema();"
```

## Running Integration Tests

### Option 1: Using Visual Studio
1. Open `AdoCore.sln` in Visual Studio
2. Build the solution (Ctrl+Shift+B)
3. Open Test Explorer (Test > Test Explorer)
4. Click "Run All Tests"

### Option 2: Using .NET CLI
```bash
# Navigate to the test project directory
cd AdoCore.Tests

# Restore dependencies
dotnet restore

# Build the test project
dotnet build

# Run all tests
dotnet test

# Run tests with detailed output
dotnet test --logger "console;verbosity=detailed"

# Run specific test
dotnet test --filter "FullyQualifiedName~InsertProductAsync_ShouldInsertProductAndReturnId"
```

### Option 3: Using Visual Studio Code
1. Install the .NET Test Explorer extension
2. Open the command palette (Ctrl+Shift+P)
3. Run "Test: Run All Tests"

## Test Coverage

### Test Cases Implemented

#### 1. InsertProductAsync_ShouldInsertProductAndReturnId
**Purpose:** Validates INSERT operation with RETURNING clause  
**SQL Statement:** Statement 3 from migration  
**Verifies:**
- Product is inserted into products table
- RETURNING clause returns valid product ID
- Product history is logged
- Product statistics are updated
- Transaction commits successfully

#### 2. GetAllProductsAsync_ShouldReturnAllProducts
**Purpose:** Validates complex SELECT with window functions  
**SQL Statement:** Statement 1 from migration  
**Verifies:**
- CTE (Common Table Expression) works correctly
- AVG() OVER () window function calculates correctly
- COUNT() OVER () window function works
- CASE expressions evaluate properly
- JOIN between products and CTE succeeds
- ORDER BY with CASE works correctly

#### 3. GetProductByIdAsync_WithValidId_ShouldReturnProduct
**Purpose:** Validates SELECT with LAG window function  
**SQL Statement:** Statement 2 from migration  
**Verifies:**
- LAG() OVER (ORDER BY) window function works
- LEFT OUTER JOIN with CTE succeeds
- CASE expression for percentage calculation works
- Parameterized query with @ProductId works

#### 4. GetProductByIdAsync_WithInvalidId_ShouldReturnNull
**Purpose:** Validates null handling  
**Verifies:**
- Query returns null when product doesn't exist
- No exceptions thrown for invalid IDs

#### 5. UpdateProductAsync_ShouldUpdateProduct
**Purpose:** Validates UPDATE operation within transaction  
**SQL Statement:** Statement 4 from migration  
**Verifies:**
- SELECT within transaction reads old values
- UPDATE statement modifies product correctly
- Product history insert logs changes
- Product statistics update maintains integrity
- Transaction commits successfully

#### 6. DeleteProductAsync_ShouldDeleteProduct
**Purpose:** Validates DELETE operation within transaction  
**SQL Statement:** Statement 5 from migration  
**Verifies:**
- SELECT within transaction reads values before delete
- Product history insert logs deletion
- DELETE statement removes product
- Product statistics update with CASE expression
- Transaction commits successfully
- CASCADE delete removes history records

#### 7. GetProductsByPriceRangeAsync_ShouldReturnProductsInRange
**Purpose:** Validates SELECT with RANK and PERCENT_RANK window functions  
**SQL Statement:** Statement 6 from migration  
**Verifies:**
- RANK() OVER (ORDER BY) calculates correctly
- PERCENT_RANK() OVER (ORDER BY) calculates correctly
- BETWEEN clause filters correctly
- CTE with window functions works
- CASE expression for price segment categorization

#### 8. GetLowStockProductsAsync_ShouldReturnProductsBelowThreshold
**Purpose:** Validates SELECT with AVG, MIN, MAX window functions  
**SQL Statement:** Statement 7 from migration  
**Verifies:**
- AVG() OVER () calculates average stock correctly
- MIN() OVER () and MAX() OVER () work
- WHERE clause with parameter filters correctly
- CASE expression for stock status categorization
- Percentage calculation works

#### 9. TransactionRollback_ShouldNotCommitChanges
**Purpose:** Validates transaction atomicity  
**Verifies:**
- Transaction begins successfully
- Operations execute within transaction scope
- Exception triggers rollback
- No changes persist after rollback
- Database state remains consistent

#### 10. WindowFunctions_InGetAllProductsAsync_ShouldCalculateCorrectly
**Purpose:** Validates window function calculations with known data  
**Verifies:**
- Window functions produce mathematically correct results
- Price categorization based on average is accurate
- Percentage calculations are correct

## Expected Test Results

### Success Criteria
All 10 tests should pass with:
- 0 failures
- 0 errors
- Execution time < 30 seconds

### Example Output
```
Test Run Successful.
Total tests: 10
     Passed: 10
     Failed: 0
    Skipped: 0
 Total time: 15.2345 Seconds
```

## SQL Equivalency Verification

Since the SQL Equivalency tool returned UNKNOWN/ERROR for all statement pairs, manual verification is required:

### Manual Verification Steps

#### 1. Setup SQL Server Comparison Database (If Available)
```sql
-- Create equivalent SQL Server schema
CREATE DATABASE AdoCore_SQLServer;
USE AdoCore_SQLServer;

CREATE SCHEMA productmanagement_dbo;

-- Create tables with SQL Server syntax
-- (Use original SQL Server schema)
```

#### 2. Execute Parallel Queries
For each of the 7 SQL statements:
1. Execute original SQL Server version
2. Execute converted PostgreSQL version
3. Compare result sets

#### 3. Document Equivalency Results
Create a spreadsheet or document with:
- Statement ID
- Original SQL Server query
- Converted PostgreSQL query
- Result set comparison (row count, column values)
- Equivalency status (Equivalent/Not Equivalent)
- Notes on any differences

## Troubleshooting

### Issue: Connection Refused
**Symptom:** `Npgsql.NpgsqlException: Connection refused`  
**Solution:**
- Verify PostgreSQL is running: `pg_isready`
- Check connection string in `appsettings.test.json`
- Verify port 5432 is not blocked by firewall

### Issue: Database Does Not Exist
**Symptom:** `FATAL: database "adocore_test" does not exist`  
**Solution:**
- Run the DatabaseSetup.sql script
- Verify database creation: `psql -U postgres -l | grep adocore_test`

### Issue: Schema Not Found
**Symptom:** `ERROR: schema "productmanagement_dbo" does not exist`  
**Solution:**
- Verify schema creation: `psql -U postgres -d adocore_test -c "\dn"`
- Re-run DatabaseSetup.sql script

### Issue: Permission Denied
**Symptom:** `ERROR: permission denied for schema productmanagement_dbo`  
**Solution:**
```sql
GRANT ALL PRIVILEGES ON SCHEMA productmanagement_dbo TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA productmanagement_dbo TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO postgres;
```

### Issue: Test Cleanup Failures
**Symptom:** Tests pass individually but fail when run together  
**Solution:**
- Implement proper cleanup in `CleanupTestData()` method
- Use test transactions that rollback after each test
- Consider using test database that's recreated for each test run

## Validation Criteria Verification

### Criterion 12: Database Connectivity
**Status:** Will be verified when tests connect successfully  
**Evidence:** Test execution log showing successful connection

### Criterion 13: Database Operations Execution
**Status:** Will be verified when all CRUD tests pass  
**Evidence:** 
- Test: InsertProductAsync_ShouldInsertProductAndReturnId (INSERT)
- Test: GetAllProductsAsync_ShouldReturnAllProducts (SELECT)
- Test: UpdateProductAsync_ShouldUpdateProduct (UPDATE)
- Test: DeleteProductAsync_ShouldDeleteProduct (DELETE)

### Criterion 14: Transaction Atomicity
**Status:** Will be verified when transaction tests pass  
**Evidence:**
- Test: TransactionRollback_ShouldNotCommitChanges
- All INSERT/UPDATE/DELETE tests verify commit success

### Criterion 15: All Tests Pass
**Status:** Will be verified when test suite completes  
**Evidence:** Test execution results showing 10/10 passing

## Additional Testing Recommendations

### 1. Performance Testing
Compare query execution times between SQL Server and PostgreSQL:
```bash
# Enable query timing in PostgreSQL
psql -U postgres -d adocore_test -c "\timing on"

# Execute each query and record execution time
```

### 2. Load Testing
Test concurrent operations:
```csharp
// Run multiple operations in parallel
var tasks = Enumerable.Range(0, 100)
    .Select(i => _repository.InsertProductAsync(new Product { ... }))
    .ToArray();
await Task.WhenAll(tasks);
```

### 3. Data Integrity Testing
Verify referential integrity and constraints:
```sql
-- Test foreign key constraints
-- Test cascade deletes
-- Test check constraints
```

### 4. Edge Case Testing
- Null value handling
- Empty string handling
- Maximum value boundaries
- Concurrent transaction conflicts

## Reporting Results

After completing all tests, update the validation summary with:

1. **Test Execution Results:**
   - Total tests executed
   - Tests passed/failed
   - Execution time
   - Any failures with stack traces

2. **SQL Equivalency Results:**
   - Statement-by-statement comparison results
   - Any differences found
   - Explanation of acceptable differences (e.g., timestamp precision)

3. **Performance Metrics:**
   - Query execution times
   - Transaction throughput
   - Comparison with SQL Server (if available)

4. **Issues Found:**
   - Description of any bugs or issues
   - Steps to reproduce
   - Severity assessment

5. **Sign-off:**
   - Tester name
   - Date
   - Overall assessment (Ready for Production / Needs Work)

## Next Steps

1. Execute all integration tests
2. Document all results
3. Perform manual SQL equivalency verification
4. Update validation_summary.md with test results
5. Address any failures or issues
6. Re-run tests until all pass
7. Obtain sign-off from stakeholders

## Contact Information

For issues or questions regarding testing:
- Review DEBUGGING_SUMMARY.md in project root
- Check migration logs in converted_statements.sql
- Review SQL equivalency report in sql_equivalency_validation_report.json
