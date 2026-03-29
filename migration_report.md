# SQL Server to PostgreSQL Migration Report

## Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, replacing database access libraries, updating connection strings, and replacing project dependencies.

**Migration Date:** 2026-03-29  
**Application:** AdoCore (.NET 9.0 ADO.NET Application)  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  

---

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Converted by DMS MCP Tool | 0 |
| Statements Manually Converted (DMS Failure) | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Error | 7 |
| Files Modified | 3 |

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader; updated using directive |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.9 |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

---

## Package Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.9 |

> **Note:** Plan specified Npgsql 8.0.1, but version 8.0.1 has a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). Updated to 8.0.9 (latest 8.0.x patch) to comply with security guardrails.

---

## Class Replacements

| SQL Server Class | Npgsql Equivalent | Locations |
|-----------------|-------------------|-----------|
| `SqlConnection` | `NpgsqlConnection` | Field declaration, GetConnectionAsync method |
| `SqlCommand` | `NpgsqlCommand` | All 7 data access methods |
| `SqlDataReader` | `NpgsqlDataReader` | MapProductFromReader parameter |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not supported/needed) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

---

## DMS MCP Tool Conversion Results

All 7 statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) as required. All attempts failed with metadata model creation/conversion timeout errors.

| # | Method | DMS Status | Error |
|---|--------|-----------|-------|
| 1 | GetAllProductsAsync | FAILED | Metadata model conversion did not complete after 15 attempts |
| 2 | GetProductByIdAsync | FAILED | Metadata model creation did not complete after 15 attempts |
| 3 | InsertProductAsync | FAILED | Metadata model creation did not complete after 15 attempts |
| 4 | UpdateProductAsync | FAILED | Metadata model creation did not complete after 15 attempts |
| 5 | DeleteProductAsync | FAILED | Metadata model creation did not complete after 15 attempts |
| 6 | GetProductsByPriceRangeAsync | FAILED | Metadata model conversion did not complete after 15 attempts |
| 7 | GetLowStockProductsAsync | FAILED | Metadata model creation did not complete after 15 attempts |

**Conversion Method:** All 7 statements were manually converted with `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` applying lowercase schema object naming convention for PostgreSQL compatibility.

---

## SQL Equivalency Validation Results

All 7 statement pairs were validated through the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status.

| # | Method | Equivalency Status | Tool Error |
|---|--------|--------------------|------------|
| 1 | GetAllProductsAsync | ERROR | 'uniqueID' |
| 2 | GetProductByIdAsync | ERROR | 'uniqueID' |
| 3 | InsertProductAsync | ERROR | 'uniqueID' |
| 4 | UpdateProductAsync | ERROR | 'uniqueID' |
| 5 | DeleteProductAsync | ERROR | 'uniqueID' |
| 6 | GetProductsByPriceRangeAsync | ERROR | 'uniqueID' |
| 7 | GetLowStockProductsAsync | ERROR | 'uniqueID' |

> **Note:** All equivalency validations returned ERROR from the tool. Per the transformation definition, these are marked as ERROR (not using agent judgment for equivalency determination). All 7 statements require manual review.

---

## Detailed Per-Statement Breakdown

### Statement 1: GetAllProductsAsync

**Source Method:** `GetAllProductsAsync` in `DataAccess/ProductRepository.cs`

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END,
    p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END,
    p.name
```

**DMS Status:** FAILED | **Equivalency:** ERROR | **Conversion:** Manual (lowercase schema)

---

### Statement 2: GetProductByIdAsync

**Source Method:** `GetProductByIdAsync` in `DataAccess/ProductRepository.cs`

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN 
        ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
    ELSE NULL END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory AS (
    SELECT productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN 
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
    ELSE NULL END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**DMS Status:** FAILED | **Equivalency:** ERROR | **Conversion:** Manual (lowercase schema)

---

### Statement 3: InsertProductAsync

**Source Method:** `InsertProductAsync` in `DataAccess/ProductRepository.cs`

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE ProductStats SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

**Converted PostgreSQL:**
```sql
WITH inserted AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM inserted
),
stats AS (
    UPDATE productstats SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW() WHERE statid = 1
)
SELECT productid FROM inserted
```

**Key Changes:** SCOPE_IDENTITY() → INSERT...RETURNING with writable CTE; GETDATE() → NOW(); BEGIN TRANSACTION/COMMIT → writable CTE (atomic)

**DMS Status:** FAILED | **Equivalency:** ERROR | **Conversion:** Manual (lowercase schema + restructured)

---

### Statement 4: UpdateProductAsync

**Source Method:** `UpdateProductAsync` in `DataAccess/ProductRepository.cs`

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    UPDATE Products SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock FROM products WHERE productid = @ProductId
),
do_update AS (
    UPDATE products SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
    FROM old_values ov
)
UPDATE productstats SET averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1
```

**Key Changes:** DECLARE/SET pattern → writable CTE with old_values subquery; GETDATE() → NOW()

**DMS Status:** FAILED | **Equivalency:** ERROR | **Conversion:** Manual (lowercase schema + restructured)

---

### Statement 5: DeleteProductAsync

**Source Method:** `DeleteProductAsync` in `DataAccess/ProductRepository.cs`

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock FROM products WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
    FROM old_values ov
),
do_delete AS (
    DELETE FROM products WHERE productid = @ProductId
)
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1
```

**Key Changes:** DECLARE/SET pattern → writable CTE with old_values subquery; GETDATE() → NOW()

**DMS Status:** FAILED | **Equivalency:** ERROR | **Conversion:** Manual (lowercase schema + restructured)

---

### Statement 6: GetProductsByPriceRangeAsync

**Source Method:** `GetProductsByPriceRangeAsync` in `DataAccess/ProductRepository.cs`

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
         ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp ORDER BY rp.PriceRank
```

**Converted PostgreSQL:**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
         WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
         ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

**DMS Status:** FAILED | **Equivalency:** ERROR | **Conversion:** Manual (lowercase schema)

---

### Statement 7: GetLowStockProductsAsync

**Source Method:** `GetLowStockProductsAsync` in `DataAccess/ProductRepository.cs`

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*,
    CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
         ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted PostgreSQL:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*,
    CASE WHEN stockquantity <= @Threshold THEN 'Critical'
         WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
         ELSE 'Adequate' END as stockstatus,
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Key Changes:** Added CAST(stockquantity AS NUMERIC) to avoid integer division in ROUND

**DMS Status:** FAILED | **Equivalency:** ERROR | **Conversion:** Manual (lowercase schema)

---

## Statements Requiring Manual Review

**All 7 statements require manual review** due to:
1. DMS MCP tool failure for all conversion attempts (metadata model timeout)
2. SQL Equivalency tool returning ERROR for all validation attempts

---

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| `extracted_statements.sql` | Project root | Complete (7 statements) |
| `converted_statements.sql` | Project root | Complete (7 statements) |
| `sql_equivalency_validation_report.json` | Project root | Complete (7 entries) |
| `migration_report.md` | Project root | Complete |

---

## Build Status

**Final Build:** SUCCESS  
**Errors:** 0  
**Warnings:** 10 (pre-existing nullable reference warnings)  

---

## Key Technical Decisions

1. **Writable CTEs for Transaction Blocks:** Statements 3, 4, and 5 originally used SQL Server's DECLARE/SET/BEGIN TRANSACTION pattern. These were restructured to use PostgreSQL writable CTEs (data-modifying CTEs) which allow multiple DML operations in a single atomic query that works with Npgsql parameterized queries.

2. **SCOPE_IDENTITY() Replacement:** Replaced with INSERT...RETURNING clause in a writable CTE, which is the idiomatic PostgreSQL approach for retrieving auto-generated identity values.

3. **GETDATE() → NOW():** Standard PostgreSQL equivalent for current timestamp.

4. **Lowercase Schema Objects:** All table names, column names, aliases, and CTE names converted to lowercase per PostgreSQL naming convention (required by manual conversion rules when DMS fails).

5. **Integer Division Fix:** Statement 7 (GetLowStockProductsAsync) added CAST(stockquantity AS NUMERIC) to prevent integer division when computing StockPercentageOfAverage.

6. **Npgsql Version:** Used 8.0.9 instead of 8.0.1 to avoid known security vulnerability (GHSA-x9vc-6hfv-hg8c).
