# Microsoft SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-31 |
| **Source Database** | Microsoft SQL Server (ProductManagement) |
| **Target Database** | PostgreSQL (postgres) |
| **Application** | AdoCore (.NET 9.0 ADO.NET Application) |
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

## DMS Tool Status

The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) was attempted for ALL 7 SQL statements. Every attempt failed with the same error:

```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
```

**DMS Configuration Used:**
- Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: `ProductManagement`
- Schema: `dbo`
- Server: `172.31.83.165`
- Region: `us-east-1`

**Retry Attempts:** 4 total calls made with various parameter combinations including increased poll_attempts (30) and poll_interval_seconds (15). All failed consistently.

**DMS Schema Mapping Tool:** Successfully retrieved target schema mappings, which were used to guide manual conversion:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

## SQL Equivalency Validation Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was called for ALL 7 statement pairs. Every call returned an ERROR:

```json
{
  "equivalence_status": "ERROR",
  "error": "'uniqueID'"
}
```

**Note:** Per the transformation definition, equivalency status is determined SOLELY by the tool output. No agent judgment was used. All 7 statements are marked as ERROR.

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetAllProductsAsync()`
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE/WHEN, ROUND
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average'
         WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats_cte AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average'
         WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND(CAST(p.price AS NUMERIC) / ps.avgprice * 100, 2) as pricepercentageofaverage
FROM productmanagement_dbo.products p INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

**Key Changes:** CTE renamed to avoid conflict with table name, all identifiers lowercase, CAST for ROUND division, schema prefix `productmanagement_dbo`.

---

### Statement 2: GetProductByIdAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetProductByIdAsync(int productId)`
- **Type:** SELECT with CTE, LAG Window Functions, LEFT JOIN, parameterized (@ProductId)
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN
        ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
    ELSE NULL END as PriceChangePercentage
FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory_cte AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) as previousprice,
           LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN
        ROUND(CAST((p.price - ph.previousprice) AS NUMERIC) / ph.previousprice * 100, 2)
    ELSE NULL END as pricechangepercentage
FROM productmanagement_dbo.products p LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Key Changes:** CTE renamed, all identifiers lowercase, CAST for ROUND division, schema prefix.

---

### Statement 3: InsertProductAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats, GETDATE()
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

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
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid
),
log_insertion AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp() FROM new_product
),
update_stats AS (
    UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp() WHERE statid = 1
)
SELECT productid FROM new_product
```

**Key Changes:** DECLARE/SCOPE_IDENTITY() replaced with writable CTE and RETURNING clause. BEGIN TRANSACTION/COMMIT replaced with implicit CTE transaction. GETDATE() → clock_timestamp(). All identifiers lowercase.

---

### Statement 4: UpdateProductAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats, GETDATE()
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    UPDATE Products SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (...) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock FROM productmanagement_dbo.products WHERE productid = @ProductId
),
do_update AS (
    UPDATE productmanagement_dbo.products SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId RETURNING productid
),
log_changes AS (
    INSERT INTO productmanagement_dbo.producthistory (...) SELECT @ProductId, 'UPDATE', ov.oldprice, @Price,
        ov.oldstock, @StockQuantity, clock_timestamp() FROM old_values ov
)
UPDATE productmanagement_dbo.productstats SET
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp() WHERE statid = 1
```

**Key Changes:** DECLARE/SELECT INTO variables replaced with old_values CTE. Writable CTEs chain operations. GETDATE() → clock_timestamp().

---

### Statement 5: DeleteProductAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE, GETDATE()
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (...) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 THEN (...) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock FROM productmanagement_dbo.products WHERE productid = @ProductId
),
log_deletion AS (
    INSERT INTO productmanagement_dbo.producthistory (...) SELECT @ProductId, 'DELETE', ov.oldprice, NULL,
        ov.oldstock, NULL, clock_timestamp() FROM old_values ov
),
do_delete AS (
    DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId RETURNING productid
)
UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 THEN (...) ELSE 0 END,
    lastupdated = clock_timestamp() WHERE statid = 1
```

**Key Changes:** Same pattern as UpdateProductAsync - variables replaced with CTE, writable CTEs, clock_timestamp().

---

### Statement 6: GetProductsByPriceRangeAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE/WHEN, parameterized
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
           PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
    WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp ORDER BY rp.PriceRank
```

**Converted PostgreSQL:**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
           PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
    WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

**Key Changes:** All identifiers lowercase, schema prefix. Window functions (RANK, PERCENT_RANK) are PostgreSQL-compatible.

---

### Statement 7: GetLowStockProductsAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER Window Functions, CASE/WHEN, ROUND, parameterized
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
           MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
    WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted PostgreSQL:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
           MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical'
    WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END as stockstatus,
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Key Changes:** All identifiers lowercase, CAST for ROUND integer division, schema prefix.

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` Version 5.1.4 | `Npgsql` Version 8.0.6 |
| `Microsoft.Extensions.Configuration` Version 8.0.0 | `Microsoft.Extensions.Configuration` Version 8.0.0 (unchanged) |
| `Microsoft.Extensions.Configuration.Json` Version 8.0.0 | `Microsoft.Extensions.Configuration.Json` Version 8.0.0 (unchanged) |
| `Microsoft.Extensions.DependencyInjection` Version 8.0.0 | `Microsoft.Extensions.DependencyInjection` Version 8.0.0 (unchanged) |

**Note:** Npgsql version was upgraded from plan-specified 8.0.1 to 8.0.6 to resolve known vulnerability [GHSA-x9vc-6hfv-hg8c](https://github.com/advisories/GHSA-x9vc-6hfv-hg8c).

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class | Occurrences |
|-----------------|--------------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 4 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Connection String Changes

| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | N/A | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (N/A) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed |

## Schema Mapping (from DMS Schema Mapping Tool)

| SQL Server Object | PostgreSQL Object |
|-------------------|-------------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

### Column Mapping (Products)

| SQL Server Column | PostgreSQL Column | Type Change |
|-------------------|-------------------|-------------|
| `ProductId` (int IDENTITY) | `productid` (INTEGER GENERATED ALWAYS AS IDENTITY) | Identity syntax |
| `Name` (nvarchar) | `name` (VARCHAR) | Type name |
| `Description` (nvarchar) | `description` (VARCHAR) | Type name |
| `Price` (decimal) | `price` (NUMERIC) | Type name |
| `StockQuantity` (int) | `stockquantity` (INTEGER) | Type name |
| `CreatedDate` (datetime) | `createddate` (TIMESTAMP WITHOUT TIME ZONE) | Type change |
| `ModifiedDate` (datetime) | `modifieddate` (TIMESTAMP WITHOUT TIME ZONE) | Type change |

## SQL Function Mapping

| SQL Server Function | PostgreSQL Equivalent | Source |
|--------------------|----------------------|--------|
| `GETDATE()` | `clock_timestamp()` | DMS Schema Mapping DDL defaults |
| `SCOPE_IDENTITY()` | `RETURNING productid` clause | Manual conversion |
| `DECLARE @var / SET @var` | CTE (WITH clause) | Manual conversion |
| `BEGIN TRANSACTION / COMMIT` | Writable CTE (implicit transaction) | Manual conversion |
| `ROUND(int_division)` | `ROUND(CAST(... AS NUMERIC) / ...)` | Manual conversion |

## Migration Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| `extracted_statements.sql` | sourceCode/ | ✅ Complete (7 statements) |
| `converted_statements.sql` | sourceCode/ | ✅ Complete (7 statements) |
| `sql_equivalency_validation_report.json` | sourceCode/ | ✅ Complete (7 statement pairs) |
| `migration_report.md` | sourceCode/ | ✅ Complete |

## Build Status

- **Final Build:** ✅ Succeeded (0 errors, 10 warnings)
- **Warnings:** All 10 warnings are pre-existing nullable reference warnings (CS8601, CS8618, CS8600, CS8603, CS8625)
- **No SQL Server references remaining** in any source file

## Files Modified

1. `DataAccess/ProductRepository.cs` - SQL statements, using, ADO.NET classes
2. `AdoCore.csproj` - Package reference
3. `appsettings.json` - Connection strings

## Files Created

1. `extracted_statements.sql` - Original MS SQL statement catalog
2. `converted_statements.sql` - Converted PostgreSQL statement catalog
3. `sql_equivalency_validation_report.json` - Equivalency validation report
4. `migration_report.md` - This report
