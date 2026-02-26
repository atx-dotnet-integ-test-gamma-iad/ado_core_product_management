# Manual SQL Equivalency Validation Guide

## Overview
This guide provides detailed instructions for manually validating the SQL statement conversions from Microsoft SQL Server to PostgreSQL. The automated SQL Equivalency tool failed for all 7 statement pairs, requiring manual validation.

## Tool Failure Context
- **DMS MCP Tool**: Failed for all 7 statements with error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **SQL Equivalency Tool**: Failed for all 7 statement pairs with error: "'uniqueID'"
- **Transformation Approach**: Manual conversion applied with lowercase schema mapping as specified in transformation definition
- **Compliance**: Per transformation definition requirements, all statements marked as ERROR (not agent judgment)

## Prerequisites

### 1. PostgreSQL Database Setup
```sql
-- Create database
CREATE DATABASE ProductManagement;

-- Connect to database
\c ProductManagement;

-- Create tables with lowercase schema (as converted)
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice DECIMAL(18,2),
    newprice DECIMAL(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL,
    FOREIGN KEY (productid) REFERENCES products(productid)
);

CREATE TABLE productstats (
    statid SERIAL PRIMARY KEY,
    totalproducts INTEGER DEFAULT 0,
    averageprice DECIMAL(18,2) DEFAULT 0,
    lastupdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialize stats
INSERT INTO productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP);
```

### 2. Sample Test Data
```sql
-- Insert test products
INSERT INTO products (name, description, price, stockquantity, createddate, modifieddate)
VALUES 
    ('Product A', 'Description A', 10.00, 100, CURRENT_TIMESTAMP, NULL),
    ('Product B', 'Description B', 20.00, 50, CURRENT_TIMESTAMP, NULL),
    ('Product C', 'Description C', 30.00, 75, CURRENT_TIMESTAMP, NULL),
    ('Product D', 'Description D', 15.00, 25, CURRENT_TIMESTAMP, NULL),
    ('Product E', 'Description E', 50.00, 10, CURRENT_TIMESTAMP, NULL);

-- Update stats
UPDATE productstats 
SET totalproducts = 5, 
    averageprice = 25.00, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
```

## Validation Test Cases

### Test Case 1: GetAllProductsAsync - Window Functions & CTE
**Purpose**: Validate window functions (AVG OVER, COUNT OVER), CTE, and complex ordering

**PostgreSQL Query**:
```sql
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;
```

**Expected Results**:
- 5 rows returned
- Average price: 25.00
- Products with price > 25: 'Above Average' (Product E: 50.00)
- Products with price = 25: 'Average' (none in sample)
- Products with price < 25: 'Below Average' (Products A, B, C, D)
- Ordering: Above average first, then below average, sorted by name within each group

**Validation Steps**:
1. Execute query against PostgreSQL
2. Verify row count matches expected
3. Verify avgprice calculation (25.00)
4. Verify totalproducts count (5)
5. Verify pricecategory values are correct
6. Verify pricepercentageofaverage calculations (Product A: 40.00, Product B: 80.00, etc.)
7. Verify ordering (Product E first, then A, B, C, D by name)

---

### Test Case 2: GetProductByIdAsync - LAG Window Function
**Purpose**: Validate LAG window function for historical price/stock tracking

**Setup**:
```sql
-- Update a product to create history
UPDATE products 
SET price = 25.00, 
    stockquantity = 80, 
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = 1;
```

**PostgreSQL Query**:
```sql
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = 1
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = 1;
```

**Expected Results**:
- 1 row returned for productid = 1
- Current price: 25.00
- Current stock: 80
- previousprice: 10.00 (original value)
- previousstock: 100 (original value)
- pricechangepercentage: 150.00 ((25-10)/10 * 100)

**Validation Steps**:
1. Execute query with @ProductId = 1
2. Verify LAG function returns previous values
3. Verify price change percentage calculation
4. Test with product that has no history (previousprice/previousstock should be NULL)

---

### Test Case 3: InsertProductAsync - RETURNING Clause & Transaction
**Purpose**: Validate RETURNING clause for identity capture and multi-statement transaction

**Application Code Test** (execute via application):
```csharp
var product = new Product
{
    Name = "Test Product",
    Description = "Test Description",
    Price = 35.00m,
    StockQuantity = 60
};

int newProductId = await repository.InsertProductAsync(product);
```

**Manual PostgreSQL Validation**:
```sql
-- Verify product was inserted
SELECT * FROM products WHERE name = 'Test Product';

-- Verify history was logged
SELECT * FROM producthistory 
WHERE productid = (SELECT productid FROM products WHERE name = 'Test Product')
AND action = 'INSERT';

-- Verify stats were updated
SELECT totalproducts, averageprice, lastupdated 
FROM productstats 
WHERE statid = 1;
```

**Expected Results**:
- Product inserted with new productid
- ProductHistory record created with action='INSERT', newprice=35.00, newstock=60
- ProductStats.totalproducts incremented to 6
- ProductStats.averageprice recalculated: (25.00 * 5 + 35.00) / 6 = 26.67
- All changes committed atomically

**Validation Steps**:
1. Execute insert via application
2. Verify RETURNING clause returns new productid
3. Verify all 3 statements executed within transaction
4. Test rollback scenario by forcing an error (e.g., invalid stats update)
5. Verify rollback undoes all changes

---

### Test Case 4: UpdateProductAsync - Multi-Statement Transaction
**Purpose**: Validate transaction atomicity with old value capture

**Application Code Test**:
```csharp
var product = new Product
{
    ProductId = 1,
    Name = "Updated Product A",
    Description = "Updated Description",
    Price = 30.00m,
    StockQuantity = 90
};

await repository.UpdateProductAsync(product);
```

**Manual PostgreSQL Validation**:
```sql
-- Verify product was updated
SELECT * FROM products WHERE productid = 1;

-- Verify history was logged with old and new values
SELECT * FROM producthistory 
WHERE productid = 1 
AND action = 'UPDATE'
ORDER BY actiondate DESC 
LIMIT 1;

-- Verify stats were updated
SELECT averageprice FROM productstats WHERE statid = 1;
```

**Expected Results**:
- Product updated with new values (name, description, price, stockquantity)
- ModifiedDate updated to CURRENT_TIMESTAMP
- ProductHistory record with oldprice, newprice, oldstock, newstock
- ProductStats.averageprice adjusted: (old_avg * total - old_price + new_price) / total
- Transaction commits only if all statements succeed

**Validation Steps**:
1. Capture old values before update
2. Execute update via application
3. Verify old values are correctly captured in SELECT statement
4. Verify all 4 statements execute atomically
5. Test rollback by simulating error in one statement
6. Verify CURRENT_TIMESTAMP produces valid PostgreSQL timestamp

---

### Test Case 5: DeleteProductAsync - Transaction with History Logging
**Purpose**: Validate deletion with audit trail and stats update

**Application Code Test**:
```csharp
await repository.DeleteProductAsync(1);
```

**Manual PostgreSQL Validation**:
```sql
-- Verify product was deleted
SELECT * FROM products WHERE productid = 1;

-- Verify history was logged before deletion
SELECT * FROM producthistory 
WHERE productid = 1 
AND action = 'DELETE'
ORDER BY actiondate DESC 
LIMIT 1;

-- Verify stats were updated
SELECT totalproducts, averageprice FROM productstats WHERE statid = 1;
```

**Expected Results**:
- Product deleted from products table
- ProductHistory record exists with action='DELETE', oldprice, oldstock
- ProductStats.totalproducts decremented
- ProductStats.averageprice recalculated: (old_avg * old_total - deleted_price) / (old_total - 1)
- Transaction atomicity maintained

**Validation Steps**:
1. Capture old values before deletion
2. Execute delete via application
3. Verify history logged BEFORE deletion (old values captured)
4. Verify product no longer exists in products table
5. Verify stats recalculated correctly
6. Test transaction rollback scenario

---

### Test Case 6: GetProductsByPriceRangeAsync - RANK & PERCENT_RANK
**Purpose**: Validate ranking window functions

**PostgreSQL Query**:
```sql
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN 15.00 AND 35.00
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;
```

**Expected Results**:
- Products with price 15-35: Products D (15), B (20), C (30)
- RANK: 1, 2, 3
- PERCENT_RANK: 0.0, 0.5, 1.0
- PriceSegment: 'Budget' (0.0), 'Mid-Range' (0.5), 'Premium' (1.0)

**Validation Steps**:
1. Execute query with @MinPrice=15.00, @MaxPrice=35.00
2. Verify RANK() ordering (1, 2, 3)
3. Verify PERCENT_RANK() calculations
4. Verify pricesegment categorization
5. Test edge cases (empty range, single product range)

---

### Test Case 7: GetLowStockProductsAsync - Complex Window Functions
**Purpose**: Validate AVG/MIN/MAX OVER() with filtering

**PostgreSQL Query**:
```sql
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= 25 THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= 50
ORDER BY stockquantity;
```

**Expected Results** (with sample data):
- Average stock across all products: (100+50+75+25+10)/5 = 52
- Products with stock <= 50: Products E (10), D (25), B (50)
- stockstatus: 'Critical' (10, 25), 'Low' (50)
- stockpercentageofaverage: 19.23% (10), 48.08% (25), 96.15% (50)

**Validation Steps**:
1. Execute query with @Threshold=50
2. Verify window function calculations (avgstock, minstock, maxstock)
3. Verify filtering (stockquantity <= threshold)
4. Verify stockstatus categorization logic
5. Verify percentage calculations
6. Test with different thresholds

---

## Edge Cases & Error Handling

### Test Transaction Rollback
```sql
-- Test rollback by forcing constraint violation
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES ('Test', 'Test', -10.00, 100); -- Should fail with constraint if you add CHECK(price >= 0)
    -- Verify rollback occurs
ROLLBACK;
```

### Test NULL Value Handling
```sql
-- Insert product with NULL description
INSERT INTO products (name, description, price, stockquantity)
VALUES ('Null Test', NULL, 25.00, 50);

-- Verify application handles NULL correctly
```

### Test Parameter Binding
```sql
-- Verify Npgsql parameters work correctly
-- Execute via application with various data types
-- Test special characters in strings
-- Test decimal precision
-- Test date/time values
```

## Performance Validation

### Compare Execution Plans
```sql
-- Enable query analysis
EXPLAIN ANALYZE 
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT p.*, ps.avgprice, ps.totalproducts
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid;
```

### Benchmark Queries
- Execute each query 1000 times
- Measure average execution time
- Compare with SQL Server baseline (if available)
- Identify any performance regressions

## Validation Checklist

### SQL Syntax Validation
- [ ] All window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) work correctly
- [ ] CTEs (WITH clauses) execute properly
- [ ] CASE expressions evaluate correctly
- [ ] JOIN operations produce correct results
- [ ] ORDER BY with complex expressions works
- [ ] ROUND() function produces expected precision
- [ ] RETURNING clause captures identity values correctly
- [ ] CURRENT_TIMESTAMP produces valid timestamps

### Data Accuracy Validation
- [ ] All SELECT queries return expected row counts
- [ ] Calculated columns match expected values
- [ ] Window function results match SQL Server behavior
- [ ] NULL handling works correctly
- [ ] Data type conversions are accurate (decimal, integer, timestamp)

### Transaction Validation
- [ ] InsertProductAsync commits all 3 statements atomically
- [ ] UpdateProductAsync commits all 4 statements atomically
- [ ] DeleteProductAsync commits all 4 statements atomically
- [ ] Rollback correctly undoes all changes on error
- [ ] Old values are correctly captured before updates/deletes

### Application Integration Validation
- [ ] GetConnectionAsync() establishes PostgreSQL connection
- [ ] Parameter binding works for all data types
- [ ] NpgsqlCommand executes successfully
- [ ] NpgsqlDataReader reads results correctly
- [ ] NpgsqlTransaction handles commits/rollbacks
- [ ] Connection pooling works efficiently
- [ ] Async/await patterns work correctly

### Error Handling Validation
- [ ] Invalid ProductId returns null or throws appropriate exception
- [ ] Constraint violations trigger rollbacks
- [ ] Connection failures are handled gracefully
- [ ] Transaction deadlocks are detected and handled

## Sign-Off Criteria

The migration is validated when:
1. ✅ All 7 test cases pass with expected results
2. ✅ All edge cases are handled correctly
3. ✅ Transaction atomicity is verified for all multi-statement operations
4. ✅ Performance is acceptable compared to SQL Server baseline
5. ✅ Error handling works correctly
6. ✅ Integration tests pass (if available)
7. ✅ Production connection string uses secure credentials
8. ✅ Npgsql package vulnerability is addressed

## Known Issues & Limitations

### Tool Failures
- **DMS MCP Tool**: Failed with "Metadata model creation failed" for all statements
- **SQL Equivalency Tool**: Failed with "'uniqueID'" error for all validation attempts
- **Mitigation**: Manual conversion applied with lowercase schema mapping as specified

### Security Considerations
- **Npgsql 8.0.1 Vulnerability**: GHSA-x9vc-6hfv-hg8c (high severity)
- **Recommendation**: Upgrade to patched version before production deployment
- **Production Credentials**: Replace default postgres/postgres credentials

### Schema Case Sensitivity
- **PostgreSQL Behavior**: Uses lowercase by default unless quoted
- **Migration Approach**: All schema objects converted to lowercase (products, producthistory, productstats)
- **Compatibility**: Application code updated to use lowercase schema names

## Next Steps After Validation

1. **Address Security Issues**:
   - Upgrade Npgsql to latest patched version
   - Update production connection string with secure credentials
   - Implement credential management (environment variables, secrets manager)

2. **Optimize Performance**:
   - Add indexes on frequently queried columns (productid, price, stockquantity)
   - Analyze query plans and optimize where needed
   - Configure PostgreSQL connection pooling

3. **Production Deployment**:
   - Deploy PostgreSQL database schema
   - Migrate production data
   - Update application configuration
   - Perform smoke tests in production environment

4. **Monitoring & Maintenance**:
   - Set up database monitoring
   - Configure query logging
   - Establish backup and recovery procedures
   - Document operational procedures

## Contact & Support

For questions or issues related to this migration:
- Review the sql_equivalency_validation_report.json for detailed conversion information
- Check dms_conversion_log.json for DMS tool failure details
- Consult the migration_summary.md for overall transformation status
