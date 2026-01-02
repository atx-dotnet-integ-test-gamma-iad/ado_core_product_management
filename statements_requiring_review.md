# SQL Statements Requiring Manual Review

## Migration Overview
This document lists all SQL statements that require manual review and database testing to validate functional equivalency after migration from Microsoft SQL Server to PostgreSQL.

**Total Statements Requiring Review:** 7 out of 7

**Review Required Reason:** The SQL Equivalency validation tool (Z3SqlSolverVerifier) returned "UNKNOWN" for all statement pairs, unable to prove equivalency or non-equivalency using formal verification methods. Per transformation requirements, UNKNOWN status has been marked as ERROR.

---

## Statement 1: GetAllProductsAsync
**Priority:** MEDIUM  
**Status:** ERROR (Equivalency tool returned UNKNOWN)  
**Conversion Method:** DMS Tool (Success)

### Original SQL Server Statement
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name
```

### Converted PostgreSQL Statement
```sql
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST
```

### Key Changes
- Schema: `Products` → `productmanagement_dbo.products`
- Column names converted to lowercase
- CTE name converted to lowercase
- Added `NULLS FIRST` to ORDER BY clauses

### Testing Recommendations
1. Verify window function calculations (AVG, COUNT) produce identical results
2. Validate CASE expression logic for price categorization
3. Test with empty result sets to ensure NULLS FIRST handling is correct
4. Compare result set ordering between SQL Server and PostgreSQL

---

## Statement 2: GetProductByIdAsync
**Priority:** MEDIUM  
**Status:** ERROR (Equivalency tool returned UNKNOWN)  
**Conversion Method:** DMS Tool (Success)

### Original SQL Server Statement
```sql
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

### Converted PostgreSQL Statement
```sql
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId
```

### Key Changes
- Schema and column name transformations
- `LEFT JOIN` → `LEFT OUTER JOIN`
- LAG window function syntax preserved

### Testing Recommendations
1. **CRITICAL:** Verify LAG function behavior with ORDER BY ModifiedDate
2. Test with products that have NULL ModifiedDate values
3. Validate percentage calculation accuracy
4. Test with single-row result sets

---

## Statement 3: InsertProductAsync
**Priority:** HIGH (Critical - Manual Conversion)  
**Status:** ERROR (DMS conversion failed, manual conversion applied, equivalency tool returned UNKNOWN)  
**Conversion Method:** MANUAL_AFTER_DMS_FAILURE

### Original SQL Server Statement
```sql
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
```

### Converted PostgreSQL Implementation (C# Managed Transaction)
The conversion has been split into multiple statements managed by C# code with BeginTransactionAsync/CommitAsync:

```sql
-- Statement 1: Insert with RETURNING
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 2: History logging
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3: Statistics update
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
```

### Key Changes
- `SCOPE_IDENTITY()` → `RETURNING productid` clause
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `BEGIN TRANSACTION/COMMIT` → C# `BeginTransactionAsync/CommitAsync`
- `DECLARE @NewProductId` → C# local variable
- Schema and column name transformations

### Testing Recommendations (CRITICAL)
1. **MUST VERIFY:** RETURNING clause correctly returns new product ID
2. **MUST VERIFY:** Transaction commit/rollback works correctly
3. **MUST VERIFY:** All three statements execute within same transaction
4. Test transaction rollback on failure scenarios
5. Verify concurrent insert scenarios don't cause ID conflicts
6. Validate statistics calculation accuracy
7. Test with NULL description values

---

## Statement 4: UpdateProductAsync
**Priority:** HIGH  
**Status:** ERROR (Equivalency tool returned UNKNOWN)  
**Conversion Method:** DMS Tool (Success with warnings)

### DMS Warning
`[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]`

### Converted PostgreSQL Implementation (C# Managed Transaction)
Transaction handling moved to C# code. Statements split into:
1. SELECT to get old values
2. UPDATE product
3. INSERT history log
4. UPDATE statistics

### Key Changes
- Transaction management moved from SQL to C# code
- `GETDATE()` → `CURRENT_TIMESTAMP`
- Variables managed in C# code instead of SQL DECLARE statements

### Testing Recommendations
1. Verify old values are correctly captured before update
2. Test transaction rollback if any statement fails
3. Validate statistics recalculation accuracy
4. Test concurrent update scenarios

---

## Statement 5: DeleteProductAsync
**Priority:** HIGH  
**Status:** ERROR (Equivalency tool returned UNKNOWN)  
**Conversion Method:** DMS Tool (Success with warnings)

### Converted PostgreSQL Implementation (C# Managed Transaction)
Similar to UpdateProductAsync, transaction handling moved to C# code with four separate statements.

### Key Changes
- CASE expression in statistics update preserved correctly
- Transaction management in C# code
- `GETDATE()` → `CURRENT_TIMESTAMP`

### Testing Recommendations
1. Verify deletion cascades correctly (if foreign keys exist)
2. Test CASE expression logic in statistics update (division by zero handling)
3. Validate transaction rollback scenarios
4. Test with last product in database

---

## Statement 6: GetProductsByPriceRangeAsync
**Priority:** MEDIUM  
**Status:** ERROR (Equivalency tool returned UNKNOWN)  
**Conversion Method:** DMS Tool (Success)

### Key Window Functions
- `RANK() OVER (ORDER BY p.Price)`
- `PERCENT_RANK() OVER (ORDER BY p.Price)`

### Testing Recommendations
1. Verify RANK and PERCENT_RANK calculations match SQL Server
2. Test BETWEEN clause with boundary values
3. Validate price segment categorization logic
4. Test with empty result sets

---

## Statement 7: GetLowStockProductsAsync
**Priority:** MEDIUM  
**Status:** ERROR (Equivalency tool returned UNKNOWN)  
**Conversion Method:** DMS Tool (Success)

### Key Window Functions
- `AVG(stockquantity) OVER ()`
- `MIN(stockquantity) OVER ()`
- `MAX(stockquantity) OVER ()`

### Testing Recommendations
1. Verify aggregate window functions produce identical results
2. Test stock status categorization logic
3. Validate percentage calculations
4. Test with threshold boundary values

---

## Overall Testing Strategy

### Phase 1: Unit Testing (Per Statement)
1. Create test database with sample data
2. Execute each method individually
3. Compare results with expected output
4. Validate error handling

### Phase 2: Integration Testing
1. Test complete CRUD workflows
2. Verify transaction atomicity
3. Test concurrent operations
4. Validate data consistency

### Phase 3: Performance Testing
1. Compare query execution times
2. Analyze PostgreSQL query execution plans
3. Optimize indexes if needed
4. Validate connection pooling

### Database Setup Required
```sql
-- Create schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create tables (lowercase names)
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18,2),
    newprice NUMERIC(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedby VARCHAR(100)
);

CREATE TABLE productmanagement_dbo.productstats (
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18,2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18,2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initialize stats table
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (statid) DO NOTHING;
```

---

## Summary

**All 7 statements require database testing** due to SQL Equivalency tool limitations. The DMS tool successfully converted 6 out of 7 statements syntactically. One statement (InsertProductAsync) required manual conversion due to complex transaction block syntax that DMS could not process.

**Code Compilation:** ✅ SUCCESS - All converted code compiles without errors

**Next Steps:**
1. Set up PostgreSQL database with correct schema
2. Execute database testing plan above
3. Validate all operations produce correct results
4. Performance test and optimize as needed
5. Deploy to production after successful validation

**Risk Assessment:** MEDIUM
- Syntax conversion completed successfully
- Code compiles without errors
- Main risk is runtime behavior validation
- Transaction handling refactored but follows best practices
- Window functions should behave identically in PostgreSQL
