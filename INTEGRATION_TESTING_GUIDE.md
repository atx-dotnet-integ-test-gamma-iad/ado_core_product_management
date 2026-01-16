# Integration Testing Guide for PostgreSQL Migration

## Overview
This document provides comprehensive instructions for performing integration testing of the migrated ADO.NET application from SQL Server to PostgreSQL.

## Prerequisites

1. **PostgreSQL Server** (version 13 or later)
   - Download from: https://www.postgresql.org/download/
   - Or use Docker: `docker run --name postgres-test -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:13`

2. **PostgreSQL Client Tools**
   - pgAdmin 4 (https://www.pgadmin.org/)
   - Or psql command-line tool (included with PostgreSQL)

3. **.NET 9.0 SDK**
   - Already installed (verified by successful build)

## Test Environment Setup

### Step 1: Install PostgreSQL (if not already installed)

#### Option A: Windows
```powershell
# Download installer from https://www.postgresql.org/download/windows/
# Run installer and set password for 'postgres' user
# Default port: 5432
```

#### Option B: Docker
```bash
# Pull and run PostgreSQL container
docker run --name postgres-test \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  -p 5432:5432 \
  -d postgres:13

# Verify container is running
docker ps | grep postgres-test
```

#### Option C: Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Step 2: Create Database and Schema

#### Using psql:
```bash
# Connect to PostgreSQL
psql -U postgres -h localhost

# Run the migration script
\i /path/to/Database/Scripts/01_InitialSetup_PostgreSQL.sql

# Or copy-paste the script content
```

#### Using pgAdmin:
1. Open pgAdmin 4
2. Connect to your PostgreSQL server
3. Right-click on "Databases" → "Create" → "Database"
4. Name: "postgres" (or use existing)
5. Open Query Tool
6. Load and execute: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`

### Step 3: Update Connection String

The connection string in `appsettings.json` is already configured for PostgreSQL:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=postgres;Username=postgres;Password=postgres;Include Error Detail=true",
    "ProdConnection": "Host=localhost;Database=postgres;Username=postgres;Password=postgres;Include Error Detail=true"
  },
  "Environment": "Development"
}
```

**Adjust if needed:**
- `Host`: Your PostgreSQL server address
- `Database`: Target database name
- `Username`: PostgreSQL username
- `Password`: PostgreSQL password
- `Port`: Add `;Port=5432` if using non-default port

### Step 4: Verify Database Connection

```bash
# From project directory
dotnet run

# If connection fails, check:
# 1. PostgreSQL service is running
# 2. Firewall allows port 5432
# 3. Connection string is correct
# 4. pg_hba.conf allows connections (PostgreSQL config)
```

## Integration Test Suite

### Test 1: Database Connection (Criterion 12)

**Objective:** Verify application can connect to PostgreSQL database

**Steps:**
```bash
# Run the application
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet run
```

**Expected Result:**
- Application starts without connection errors
- Menu displays successfully
- No exception thrown during connection initialization

**Validation:**
- ✅ Connection established
- ✅ No timeout errors
- ✅ No authentication failures

**Status:** PASS/FAIL

---

### Test 2: Simple DML Operations (Criterion 13 - Part 1)

**Objective:** Verify INSERT, UPDATE, DELETE operations proven EQUIVALENT by tool

#### Test 2.1: INSERT Operation
```bash
# Using CLI
dotnet run -- add "Test Product" 99.99 50 "Integration test product"

# Or using interactive mode
dotnet run
# Select option 3 (Create new product)
# Enter: Name="Test Product", Price=99.99, Stock=50, Description="Integration test product"
```

**Expected Result:**
- Product inserted successfully
- New ProductId returned (via RETURNING clause)
- Record exists in database

**Verification Query (in psql):**
```sql
SELECT * FROM public.products WHERE name = 'Test Product';
```

**Status:** PASS/FAIL
**Notes:** 

---

#### Test 2.2: UPDATE Operation
```bash
# Get the ProductId from Test 2.1, then:
dotnet run -- update <ProductId> "Updated Test Product" 109.99 45 "Updated description"
```

**Expected Result:**
- Product updated successfully
- Modified date updated to NOW()
- Changes reflected in database

**Verification Query:**
```sql
SELECT name, price, stockquantity, modifieddate 
FROM public.products 
WHERE productid = <ProductId>;
```

**Status:** PASS/FAIL
**Notes:**

---

#### Test 2.3: DELETE Operation
```bash
dotnet run -- delete <ProductId>
```

**Expected Result:**
- Product deleted successfully
- Record no longer exists in database
- Trigger recorded DELETE in producthistory

**Verification Query:**
```sql
-- Should return 0 rows
SELECT * FROM public.products WHERE productid = <ProductId>;

-- Should show DELETE action
SELECT * FROM public.producthistory WHERE productid = <ProductId> ORDER BY actiondate DESC LIMIT 1;
```

**Status:** PASS/FAIL
**Notes:**

---

### Test 3: Complex SELECT Operations (Criterion 13 - Part 2)

**Objective:** Validate 4 complex queries marked ERROR by equivalency tool

#### Test 3.1: GetAllProductsAsync (CTE with AVG/COUNT window functions)
```bash
dotnet run -- list
```

**Expected Result:**
- All products listed with price categories
- Price percentage of average calculated
- Products sorted by price category then name
- No SQL errors

**Verification:**
- ✅ Query executes without errors
- ✅ Results include computed columns (pricecategory, pricepercentageofaverage)
- ✅ Sorting is correct (Above Average first, then by name)

**Manual Validation (run in psql):**
```sql
-- Run the actual query from ProductRepository.cs
WITH productstats
AS (SELECT
    productid, AVG(Price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM public.products)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.avgprice THEN 'Above Average'
        WHEN p.Price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.Price / ps.avgprice), 2) AS pricepercentageofaverage
    FROM public.products AS p
    INNER JOIN productstats AS ps
        ON p.ProductId = ps.productid
    ORDER BY
    CASE
        WHEN p.Price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.Name NULLS FIRST;
```

**Status:** PASS/FAIL
**Notes:**

---

#### Test 3.2: GetProductByIdAsync (CTE with LAG window function)
```bash
dotnet run -- get 1
```

**Expected Result:**
- Product details displayed
- Previous price and stock shown (if available)
- Price change percentage calculated
- No SQL errors

**Verification:**
- ✅ Query executes without errors
- ✅ LAG window function works correctly
- ✅ Price change percentage calculated accurately

**Manual Validation:**
```sql
-- Run with actual ProductId
WITH producthistory
AS (SELECT
    productid, lag(Price) OVER (ORDER BY ModifiedDate) AS previousprice, 
    lag(StockQuantity) OVER (ORDER BY ModifiedDate) AS previousstock
    FROM public.products
    WHERE productid = 1)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, 
    p.CreatedDate, p.ModifiedDate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.Price - ph.previousprice) / ph.previousprice), 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM public.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.ProductId = ph.productid
    WHERE p.ProductId = 1;
```

**Status:** PASS/FAIL
**Notes:**

---

#### Test 3.3: GetProductsByPriceRangeAsync (CTE with RANK/PERCENT_RANK)
```bash
# Test with price range that includes multiple products
dotnet run

# In interactive mode, add option to get by price range
# Or use direct database query for now
```

**Manual Test (in psql):**
```sql
-- Test with sample price range
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.Price) AS pricerank, 
    percent_rank() OVER (ORDER BY p.Price) AS pricepercentile
    FROM public.products AS p
    WHERE p.Price BETWEEN 100 AND 500)
SELECT
    rp.productid, rp.name, rp.price, rp.pricerank, rp.pricepercentile,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;
```

**Expected Result:**
- Products within price range returned
- Ranked by price correctly
- Percentile calculated (0.0 to 1.0)
- Price segment assigned correctly

**Status:** PASS/FAIL
**Notes:**

---

#### Test 3.4: GetLowStockProductsAsync (CTE with AVG/MIN/MAX)
```bash
# Test with threshold that captures some products
# Update a product to have low stock first:
dotnet run -- stock 1 5

# Then test low stock query through database
```

**Manual Test (in psql):**
```sql
-- Test with threshold of 10
WITH stockanalysis
AS (SELECT p.*,
        AVG(StockQuantity) OVER () AS avgstock,
        MIN(StockQuantity) OVER () AS minstock,
        MAX(StockQuantity) OVER () AS maxstock
    FROM public.products AS p)
SELECT sa.productid, sa.name, sa.stockquantity, sa.avgstock,
        CASE
            WHEN sa.StockQuantity <= 10 THEN 'Critical'
            WHEN sa.StockQuantity <= avgstock * 0.5 THEN 'Low'
            ELSE 'Adequate'
        END AS stockstatus,
        round((sa.StockQuantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE sa.StockQuantity <= 10
    ORDER BY sa.StockQuantity;
```

**Expected Result:**
- Products with stock <= threshold returned
- Window functions calculate avg/min/max correctly
- Stock status assigned correctly
- Stock percentage calculated accurately

**Status:** PASS/FAIL
**Notes:**

---

### Test 4: Transaction Handling (Criterion 14)

**Objective:** Verify transaction atomicity using ExecuteInTransactionAsync

#### Test 4.1: Successful Transaction
```csharp
// Add this test method to verify transaction commit
// This requires modifying the application or creating a test project
```

**Manual Test:**
```sql
-- Before: Check product count
SELECT COUNT(*) FROM public.products;

-- In application: Insert product, update another, delete a third (all in transaction)
-- After: Verify all changes committed
SELECT COUNT(*) FROM public.products;
```

**Expected Result:**
- All operations within transaction succeed
- Changes are committed
- Database state is consistent

**Status:** PASS/FAIL

---

#### Test 4.2: Failed Transaction (Rollback)
```sql
-- Intentionally cause a constraint violation to test rollback
-- The transaction should rollback all changes
```

**Expected Result:**
- Transaction rolls back on error
- No partial changes persist
- Database returns to pre-transaction state

**Status:** PASS/FAIL

---

### Test 5: Performance Testing

**Objective:** Verify window function queries perform acceptably with realistic data

#### Test 5.1: Load Test Data
```sql
-- Insert additional test products
INSERT INTO public.products (name, description, price, stockquantity, categoryid, supplierid, sku, reorderlevel)
SELECT 
    'Test Product ' || generate_series,
    'Test description ' || generate_series,
    random() * 1000 + 50,
    floor(random() * 100)::int,
    (random() * 19 + 1)::int,
    (random() * 7 + 1)::int,
    'TST-' || generate_series,
    10
FROM generate_series(1, 1000);
```

#### Test 5.2: Query Performance
```sql
-- Test each complex query with EXPLAIN ANALYZE
EXPLAIN ANALYZE
WITH productstats
AS (SELECT
    productid, AVG(Price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM public.products)
SELECT
    p.ProductId, p.Name, p.Price, ps.avgprice
    FROM public.products AS p
    INNER JOIN productstats AS ps
        ON p.ProductId = ps.productid
    LIMIT 100;
```

**Acceptable Performance:**
- Query execution time < 100ms for GetAllProductsAsync
- Query execution time < 50ms for GetProductByIdAsync
- Index usage confirmed in EXPLAIN ANALYZE output

**Status:** PASS/FAIL
**Notes:**

---

## Test Results Summary

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| 1 | Database Connection | | |
| 2.1 | INSERT Operation | | |
| 2.2 | UPDATE Operation | | |
| 2.3 | DELETE Operation | | |
| 3.1 | GetAllProductsAsync | | |
| 3.2 | GetProductByIdAsync | | |
| 3.3 | GetProductsByPriceRangeAsync | | |
| 3.4 | GetLowStockProductsAsync | | |
| 4.1 | Transaction Commit | | |
| 4.2 | Transaction Rollback | | |
| 5.1 | Load Test Data | | |
| 5.2 | Query Performance | | |

## Issues and Resolutions

### Known Limitations
1. **Equivalency Tool Limitations:** The SQL equivalency tool cannot formally verify complex queries with CTEs and window functions due to Z3 solver limitations. These require manual validation.

2. **Column Name Case Sensitivity:** PostgreSQL lowercases identifiers by default. The DMS tool has converted all column names to lowercase. Queries use the lowercase names correctly.

3. **NULLS FIRST:** PostgreSQL adds `NULLS FIRST` to ORDER BY clauses by default. This is explicit in converted queries.

### Common Issues

#### Issue: Connection Refused
**Solution:** 
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check port is open
netstat -an | grep 5432

# Check pg_hba.conf allows connections
# Add line: host all all 0.0.0.0/0 md5
```

#### Issue: Authentication Failed
**Solution:**
```bash
# Reset postgres user password
sudo -u postgres psql
ALTER USER postgres PASSWORD 'postgres';
```

#### Issue: Query Timeout
**Solution:**
```sql
-- Increase statement timeout
SET statement_timeout = '30s';

-- Check for missing indexes
SELECT * FROM pg_stat_user_indexes WHERE schemaname = 'public';
```

## Recommendations

1. **Create Unit Tests:** Implement NUnit or xUnit tests for each repository method
2. **Create Integration Tests:** Automated tests using Testcontainers for PostgreSQL
3. **Performance Monitoring:** Use pg_stat_statements to monitor query performance
4. **Connection Pooling:** Verify Npgsql connection pooling is working efficiently
5. **Error Logging:** Implement structured logging (Serilog) for production monitoring

## Next Steps

After completing integration testing:
1. Document any SQL differences found between SQL Server and PostgreSQL behavior
2. Create automated test suite to prevent regressions
3. Perform user acceptance testing (UAT)
4. Create deployment runbook for production migration
5. Plan rollback strategy if issues arise in production

## References

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- SQL Equivalency Tool Report: `sql_equivalency_validation_report.json`
- DMS Conversion Log: `dms_conversion_log.txt`
