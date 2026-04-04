# SQL Server to PostgreSQL Migration Report

## Summary

| Item | Value |
|------|-------|
| **Application** | AdoCore - .NET ADO Product Management Application |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Migration Date** | 2026-04-04 |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Framework** | .NET 9.0 |

---

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

### DMS Tool Status
The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for ALL 7 SQL statements but consistently failed with **metadata model creation/conversion timeouts**. Multiple attempts were made with varying `max_poll_attempts` and `poll_interval_seconds` values, including retries with a simple `SELECT` statement, all resulting in the same timeout error.

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was **successfully used** to obtain target schema mappings for all 3 database tables, which were then used to guide manual conversion.

### SQL Equivalency Tool Status
The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for ALL 7 statement pairs. All calls returned `ERROR` with message `'uniqueID'`, indicating a system-level issue with the tool. Per the transformation definition, all statements are marked as `ERROR` status (no agent judgment used).

---

## Schema Mapping (from DMS Schema Mapping Tool)

### Products Table
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `ProductId INT IDENTITY(1,1)` | `productid INTEGER GENERATED ALWAYS AS IDENTITY` |
| `Name NVARCHAR(100)` | `name VARCHAR(100)` |
| `Description NVARCHAR(500)` | `description VARCHAR(500)` |
| `Price DECIMAL(18,2)` | `price NUMERIC(18,2)` |
| `StockQuantity INT` | `stockquantity INTEGER` |
| `CreatedDate DATETIME DEFAULT GETDATE()` | `createddate TIMESTAMP DEFAULT clock_timestamp()` |
| `ModifiedDate DATETIME` | `modifieddate TIMESTAMP` |

### ProductHistory Table
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `HistoryId INT IDENTITY(1,1)` | `historyid INTEGER GENERATED ALWAYS AS IDENTITY` |
| `ProductId INT` | `productid INTEGER` |
| `Action VARCHAR(10)` | `action VARCHAR(10)` |
| `OldPrice DECIMAL(18,2)` | `oldprice NUMERIC(18,2)` |
| `NewPrice DECIMAL(18,2)` | `newprice NUMERIC(18,2)` |
| `OldStock INT` | `oldstock INTEGER` |
| `NewStock INT` | `newstock INTEGER` |
| `ActionDate DATETIME DEFAULT GETDATE()` | `actiondate TIMESTAMP DEFAULT clock_timestamp()` |

### ProductStats Table
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |
| `StatId INT DEFAULT 1` | `statid INTEGER DEFAULT 1` |
| `TotalProducts INT DEFAULT 0` | `totalproducts INTEGER DEFAULT 0` |
| `AveragePrice DECIMAL(18,2) DEFAULT 0` | `averageprice NUMERIC(18,2) DEFAULT 0` |
| `LastUpdated DATETIME DEFAULT GETDATE()` | `lastupdated TIMESTAMP DEFAULT clock_timestamp()` |

---

## Detailed SQL Statement Conversion

### Statement 1: GetAllProductsAsync

| Property | Value |
|---|---|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetAllProductsAsync()` |
| **Line Location** | ~43-72 |
| **Complexity** | Hard |
| **DMS Conversion** | FAILED - Metadata model conversion timeout |
| **Manual Conversion** | Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR - "'uniqueID'" |

**Original SQL (MS SQL Server):**
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

**Converted SQL (PostgreSQL):**
```sql
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END,
    p.name
```

**Key Changes:** CTE renamed to `productstats_cte` (avoiding conflict with table name), all identifiers lowercase, schema prefix `productmanagement_dbo`.

---

### Statement 2: GetProductByIdAsync

| Property | Value |
|---|---|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetProductByIdAsync(int productId)` |
| **Line Location** | ~87-116 |
| **Complexity** | Hard |
| **DMS Conversion** | FAILED - Metadata model creation timeout |
| **Manual Conversion** | Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR - "'uniqueID'" |

**Original SQL (MS SQL Server):**
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
       p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
       CASE WHEN ph.PreviousPrice IS NOT NULL THEN 
           ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
       ELSE NULL END as PriceChangePercentage
FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted SQL (PostgreSQL):**
```sql
WITH producthistory_cte AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) as previousprice,
           LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity,
       p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
       CASE WHEN ph.previousprice IS NOT NULL THEN 
           ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
       ELSE NULL END as pricechangepercentage
FROM productmanagement_dbo.products p LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Key Changes:** CTE renamed to `producthistory_cte`, all identifiers lowercase, schema prefix.

---

### Statement 3: InsertProductAsync

| Property | Value |
|---|---|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `InsertProductAsync(Product product)` |
| **Line Location** | ~131-155 |
| **Complexity** | Hard |
| **DMS Conversion** | FAILED - Metadata model creation timeout |
| **Manual Conversion** | Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR - "'uniqueID'" |

**Original SQL (MS SQL Server):**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE ProductStats SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

**Converted SQL (PostgreSQL):**
```sql
BEGIN;
    WITH new_product AS (
        INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid
    )
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp() FROM new_product;
    UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;
SELECT currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));
```

**Key Changes:** `SCOPE_IDENTITY()` → CTE with `RETURNING` + `currval()`, `GETDATE()` → `clock_timestamp()`, `BEGIN TRANSACTION` → `BEGIN`, `DECLARE @var` → CTE pattern, all identifiers lowercase.

---

### Statement 4: UpdateProductAsync

| Property | Value |
|---|---|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `UpdateProductAsync(Product product)` |
| **Line Location** | ~170-198 |
| **Complexity** | Hard |
| **DMS Conversion** | FAILED - Metadata model creation timeout |
| **Manual Conversion** | Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR - "'uniqueID'" |

**Original SQL (MS SQL Server):**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    UPDATE Products SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory ... VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats SET AveragePrice = ... LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted SQL (PostgreSQL):**
```sql
BEGIN;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, clock_timestamp()
    FROM productmanagement_dbo.products WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = clock_timestamp() WHERE statid = 1;
    UPDATE productmanagement_dbo.products SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;
COMMIT;
```

**Key Changes:** `DECLARE @var`/`SET @var` → subqueries, `GETDATE()` → `clock_timestamp()`, order adjusted to capture old values before update, all identifiers lowercase.

---

### Statement 5: DeleteProductAsync

| Property | Value |
|---|---|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `DeleteProductAsync(int productId)` |
| **Line Location** | ~213-244 |
| **Complexity** | Hard |
| **DMS Conversion** | FAILED - Metadata model creation timeout |
| **Manual Conversion** | Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR - "'uniqueID'" |

**Original SQL (MS SQL Server):**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory ... VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 THEN ... ELSE 0 END, LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**Converted SQL (PostgreSQL):**
```sql
BEGIN;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, clock_timestamp()
    FROM productmanagement_dbo.products WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts - 1,
        averageprice = CASE WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0 END, lastupdated = clock_timestamp()
    WHERE statid = 1;
    DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId;
COMMIT;
```

**Key Changes:** `DECLARE @var` → subqueries, order adjusted (history/stats before delete), `GETDATE()` → `clock_timestamp()`, all identifiers lowercase.

---

### Statement 6: GetProductsByPriceRangeAsync

| Property | Value |
|---|---|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)` |
| **Line Location** | ~262-280 |
| **Complexity** | Medium |
| **DMS Conversion** | FAILED - Metadata model creation timeout |
| **Manual Conversion** | Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR - "'uniqueID'" |

**Original SQL (MS SQL Server):**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
           PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE ... END as PriceSegment FROM RankedProducts rp ORDER BY rp.PriceRank
```

**Converted SQL (PostgreSQL):**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
           PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE ... END as pricesegment FROM rankedproducts rp ORDER BY rp.pricerank
```

**Key Changes:** All identifiers lowercase, schema prefix. Window functions `RANK()` and `PERCENT_RANK()` are compatible.

---

### Statement 7: GetLowStockProductsAsync

| Property | Value |
|---|---|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | `GetLowStockProductsAsync(int threshold)` |
| **Line Location** | ~299-319 |
| **Complexity** | Medium |
| **DMS Conversion** | FAILED - Metadata model creation timeout |
| **Manual Conversion** | Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR - "'uniqueID'" |

**Original SQL (MS SQL Server):**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
           MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*, CASE ... END as StockStatus,
       ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted SQL (PostgreSQL):**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
           MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
)
SELECT sa.*, CASE ... END as stockstatus,
       ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Key Changes:** All identifiers lowercase, schema prefix, added `CAST(stockquantity AS NUMERIC)` to prevent integer division.

---

## Package Dependency Changes

| Change | Details |
|--------|---------|
| **Removed** | `Microsoft.Data.SqlClient` Version 5.1.4 |
| **Added** | `Npgsql` Version 8.0.6 |
| **Unchanged** | `Microsoft.Extensions.Configuration` 8.0.0 |
| **Unchanged** | `Microsoft.Extensions.Configuration.Json` 8.0.0 |
| **Unchanged** | `Microsoft.Extensions.DependencyInjection` 8.0.0 |

---

## Connection String Changes

| Connection | Old (SQL Server) | New (PostgreSQL) |
|---|---|---|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |
| ProdConnection | Same as Dev | Same as Dev |

### Parameter Mapping
| SQL Server | PostgreSQL | Notes |
|---|---|---|
| `Server=` | `Host=` | Hostname parameter |
| `Database=` | `Database=` | Same |
| `Trusted_Connection=True` | Removed | Not applicable; use Username/Password |
| `MultipleActiveResultSets=true` | Removed | Not supported by PostgreSQL |
| `TrustServerCertificate=True` | Removed | Can add `SSL Mode=Prefer` if needed |
| N/A | `Username=postgres` | Added for authentication |
| N/A | `Password=postgres` | Added as placeholder |

---

## ADO.NET Class Replacements

| Original (SqlClient) | Replacement (Npgsql) | Files Modified |
|---|---|---|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | ProductRepository.cs |
| `SqlConnection` | `NpgsqlConnection` | ProductRepository.cs (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | ProductRepository.cs (all command usages) |
| `SqlDataReader` | `NpgsqlDataReader` | ProductRepository.cs (MapProductFromReader) |
| `BeginTransactionAsync` | `BeginTransactionAsync` | Compatible - no change needed |
| `CommitAsync` | `CommitAsync` | Compatible - no change needed |
| `RollbackAsync` | `RollbackAsync` | Compatible - no change needed |
| `AddWithValue` | `AddWithValue` | Compatible - no change needed |
| `ExecuteReaderAsync` | `ExecuteReaderAsync` | Compatible - no change needed |
| `ExecuteScalarAsync` | `ExecuteScalarAsync` | Compatible - no change needed |
| `ExecuteNonQueryAsync` | `ExecuteNonQueryAsync` | Compatible - no change needed |

---

## SQL Syntax Conversion Rules Applied

| SQL Server Feature | PostgreSQL Equivalent | Applied To |
|---|---|---|
| `SCOPE_IDENTITY()` | `RETURNING productid` + `currval()` | InsertProductAsync |
| `GETDATE()` | `clock_timestamp()` | Insert, Update, Delete |
| `DECLARE @var` / `SET @var` | Subqueries / CTEs | Update, Delete, Insert |
| `BEGIN TRANSACTION` / `COMMIT` | `BEGIN` / `COMMIT` | Insert, Update, Delete |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` | All table references |
| CTE names matching table names | Renamed with `_cte` suffix | GetAllProductsAsync |
| Integer division in `ROUND()` | `CAST(... AS NUMERIC)` | GetLowStockProductsAsync |
| Column reader names | Lowercase to match schema | MapProductFromReader |

---

## Build Verification

| Step | Build Command | Result |
|------|------|--------|
| Step 3 (Code Changes) | `dotnet build AdoCore.sln` | FAILED (Npgsql package not yet added) |
| Step 4 (Package + Config) | `dotnet build AdoCore.sln` | **SUCCESS** (0 errors, 0 security warnings) |
| Step 5 (Final) | `dotnet build AdoCore.sln` | **SUCCESS** |

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted, ADO.NET classes replaced |
| `AdoCore.csproj` | Microsoft.Data.SqlClient → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated for PostgreSQL |

## Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | All 7 original SQL Server statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report (7 statements, all ERROR) |
| `dms_conversion_summary.md` | DMS failure documentation and conversion details |
| `migration_report.md` | This report |

---

## Statements Requiring Manual Review

All 7 statements should be manually reviewed because:
1. **DMS Conversion Failed**: All statements were manually converted due to DMS tool timeout
2. **Equivalency Validation Failed**: SQL Equivalency tool returned ERROR for all statements

### Recommended Validation Steps:
1. Execute each PostgreSQL statement against the target database
2. Compare output with SQL Server results for the same data
3. Verify transaction atomicity for statements 3, 4, and 5
4. Test parameterized queries with various inputs
5. Validate that `currval()` returns correct IDs after insert operations

---

## Notes on SQL Scripts (Out of Scope)

The following SQL scripts in the project contain SQL Server-specific DDL and require separate database schema migration:
- `Scripts/01_InitialSetup.sql`
- `Database/Scripts/01_InitialSetup.sql`

These contain:
- `IF NOT EXISTS` with `sys.objects`
- `GO` batch separators
- `IDENTITY` column specifications
- `GETDATE()` defaults
- Stored procedures

These scripts are managed by the DMS schema migration and are out of scope for this application code migration.
