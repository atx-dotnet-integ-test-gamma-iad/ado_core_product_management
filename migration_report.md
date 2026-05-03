# AdoCore SQL Server to PostgreSQL Migration Report

## Executive Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention (DMS Failed) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS Tool Status

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with migration project ARN: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`.

**All 7 conversions failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS `schema_mapping_tool` was successful and provided the following schema mappings used for manual conversion:
- `dbo.Products` → `productmanagement_dbo.products` (all columns lowercased)
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercased)
- `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercased)

## SQL Equivalency Tool Status

All 7 statement pairs were passed through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 validations returned ERROR** with the same error:
```json
{
  "equivalence_status": "ERROR",
  "error": "'uniqueID'"
}
```

This appears to be a systemic tool issue unrelated to the SQL statements themselves.

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, AVG/COUNT window functions, ROUND, CASE, INNER JOIN
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool error, not agent judgment)

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
    FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average'
         WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

**Changes**: All schema objects lowercased, CTE name changed to avoid collision with table name

---

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG window function, ROUND, CASE, LEFT JOIN, parameterized
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

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
        ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END as PriceChangePercentage
FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory_cte AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) as previousprice,
           LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END as pricechangepercentage
FROM products p LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Changes**: All schema objects lowercased, CTE name changed to avoid collision with table name

---

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

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

**Converted PostgreSQL (decomposed into 3 separate C# commands):**
```sql
-- Command 1: INSERT with RETURNING (replaces SCOPE_IDENTITY)
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid;

-- Command 2: INSERT history log
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3: UPDATE stats
UPDATE productstats SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW() WHERE statid = 1;
```

**Changes**: SCOPE_IDENTITY() → RETURNING clause, GETDATE() → NOW(), DECLARE/@var → C# variables, transaction decomposed into separate NpgsqlCommand calls wrapped in NpgsqlTransaction

---

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT into vars, UPDATE, INSERT, GETDATE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

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

**Converted PostgreSQL (decomposed into 4 separate C# commands):**
```sql
-- Command 1: SELECT old values into C# variables
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Command 2: UPDATE product
UPDATE products SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;
-- Command 3: INSERT history
INSERT INTO producthistory (...) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
-- Command 4: UPDATE stats
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1;
```

**Changes**: DECLARE/@var → C# variables via ExecuteReaderAsync, GETDATE() → NOW(), transaction decomposed

---

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT into vars, INSERT, DELETE, UPDATE, GETDATE, CASE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (...) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 THEN (...) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL (decomposed into 4 separate C# commands):**
```sql
-- Command 1: SELECT old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Command 2: INSERT history
INSERT INTO producthistory (...) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
-- Command 3: DELETE product
DELETE FROM products WHERE productid = @ProductId;
-- Command 4: UPDATE stats
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 THEN (...) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1;
```

**Changes**: DECLARE/@var → C# variables, GETDATE() → NOW(), transaction decomposed

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

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
    FROM products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
    WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

**Changes**: All schema objects lowercased

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR

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
    FROM products p
)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical'
    WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Changes**: All schema objects lowercased, added CAST(stockquantity AS NUMERIC) for integer division to avoid PostgreSQL integer truncation

---

## Static Code Changes Summary

### Package Dependencies (AdoCore.csproj)
| Change | Before | After |
|--------|--------|-------|
| Removed | `Microsoft.Data.SqlClient` v5.1.4 | - |
| Added | - | `Npgsql` v8.0.6 |
| Retained | `Microsoft.Extensions.Configuration` v8.0.0 | Unchanged |
| Retained | `Microsoft.Extensions.Configuration.Json` v8.0.0 | Unchanged |
| Retained | `Microsoft.Extensions.DependencyInjection` v8.0.0 | Unchanged |

### Import Statements (ProductRepository.cs)
| Change | Before | After |
|--------|--------|-------|
| Replaced | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### ADO.NET Type Replacements (ProductRepository.cs)
| Original Type | Replacement | Count |
|---------------|-------------|-------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, new, return type) |
| `SqlCommand` | `NpgsqlCommand` | 15 instances |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |
| `(System.Data.Common.DbTransaction)` | `(NpgsqlTransaction)` | 11 instances |

### Connection Strings (appsettings.json)
| Connection | Before | After |
|------------|--------|-------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=postgres;Username=postgres;Password=postgres` |
| ProdConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=postgres;Username=postgres;Password=postgres` |

### Build Status
- **Build Result**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, no new warnings)
- **Vulnerability Warnings**: 0 (fixed by using Npgsql 8.0.6)

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. **DMS tool failed** for all conversions - manual lowercase conversion applied
2. **SQL Equivalency tool returned ERROR** for all validations - tool had systemic issue

While the conversions follow standard SQL Server to PostgreSQL patterns and use the DMS schema mapping output, they should be tested against a live PostgreSQL database to confirm correctness.

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| `extracted_statements.sql` | sourceCode/ | Complete (7 statements) |
| `converted_statements.sql` | sourceCode/ | Complete (7 statements) |
| `sql_equivalency_validation_report.json` | sourceCode/ | Complete (7 pairs) |
| `migration_report.md` | sourceCode/ | Complete |
| `AdoCore.csproj` | sourceCode/ | Modified |
| `ProductRepository.cs` | sourceCode/DataAccess/ | Modified |
| `appsettings.json` | sourceCode/ | Modified |

## Final Validation Checklist

- [x] All Microsoft.Data.SqlClient references removed
- [x] Npgsql package reference added (v8.0.6)
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- [x] All SQL statements converted to PostgreSQL syntax (lowercase schema objects)
- [x] All GETDATE() → NOW()
- [x] SCOPE_IDENTITY() → RETURNING clause
- [x] All DECLARE/@var patterns → C# variable retrieval
- [x] All transaction blocks properly decomposed into separate NpgsqlCommand calls
- [x] Connection strings updated to PostgreSQL format
- [x] EVERY SQL statement pair passed through DMS MCP tool (7/7)
- [x] EVERY SQL statement pair validated through SQL Equivalency tool (7/7)
- [x] Application builds successfully with 0 errors
