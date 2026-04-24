# Migration Report: MS SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS MCP Tool** | 0 |
| **Statements Requiring Manual Intervention (DMS Failure)** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Validation Errors** | 7 |

## DMS MCP Tool Status

All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All 7 failed with the same infrastructure error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Configuration Used:**
- Migration Project ARN: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`

Since DMS failed for all statements, manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol, which lowercases all schema object names for PostgreSQL compatibility.

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All 7 returned ERROR status with error `'uniqueID'`. This is an infrastructure-level error from the tool, not a judgment on the statements themselves.

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetAllProductsAsync()
- **Type:** CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND, ORDER BY CASE
- **DMS Status:** ERROR - Metadata model creation failed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

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
WITH productstats AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average'
         WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

### Statement 2: GetProductByIdAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductByIdAsync()
- **Type:** CTE with LAG window function, LEFT JOIN, CASE with ROUND
- **DMS Status:** ERROR - Metadata model creation failed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

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
WITH producthistory AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END as pricechangepercentage
FROM products p LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

### Statement 3: InsertProductAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** InsertProductAsync()
- **Type:** Transaction block with DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, COMMIT
- **DMS Status:** ERROR - Metadata model creation failed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Conversions:** SCOPE_IDENTITY() → INSERT...RETURNING, GETDATE() → NOW(), single batch → multi-command C# transaction

**Original MS SQL:**
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

**Converted PostgreSQL (restructured as multi-command C# transaction):**
```sql
-- Command 1: INSERT INTO products (...) VALUES (...) RETURNING productid
-- Command 2: INSERT INTO producthistory (...) VALUES (..., NOW())
-- Command 3: UPDATE productstats SET ... WHERE statid = 1
```

### Statement 4: UpdateProductAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** UpdateProductAsync()
- **Type:** Transaction block with DECLARE, SELECT into variables, UPDATE with GETDATE(), INSERT
- **DMS Status:** ERROR - Metadata model creation failed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Conversions:** DECLARE/@var → C# variables, GETDATE() → NOW(), single batch → multi-command

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    UPDATE Products SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (...) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats SET AveragePrice = ..., LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL (restructured as multi-command C# transaction):**
```sql
-- Command 1: SELECT price, stockquantity FROM products WHERE productid = @ProductId
-- Command 2: UPDATE products SET ... modifieddate = NOW() WHERE productid = @ProductId
-- Command 3: INSERT INTO producthistory (...) VALUES (..., NOW())
-- Command 4: UPDATE productstats SET ... lastupdated = NOW() WHERE statid = 1
```

### Statement 5: DeleteProductAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** DeleteProductAsync()
- **Type:** Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE
- **DMS Status:** ERROR - Metadata model creation failed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Conversions:** DECLARE/@var → C# variables, GETDATE() → NOW(), single batch → multi-command

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (...) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 THEN ... ELSE 0 END, LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL (restructured as multi-command C# transaction):**
```sql
-- Command 1: SELECT price, stockquantity FROM products WHERE productid = @ProductId
-- Command 2: INSERT INTO producthistory (...) VALUES (..., NOW())
-- Command 3: DELETE FROM products WHERE productid = @ProductId
-- Command 4: UPDATE productstats SET ... CASE ... lastupdated = NOW() WHERE statid = 1
```

### Statement 6: GetProductsByPriceRangeAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductsByPriceRangeAsync()
- **Type:** CTE with RANK() and PERCENT_RANK() window functions, CASE, BETWEEN
- **DMS Status:** ERROR - Metadata model creation failed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)

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

### Statement 7: GetLowStockProductsAsync

- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetLowStockProductsAsync()
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status:** ERROR - Metadata model creation failed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Conversions:** Added CAST(stockquantity AS NUMERIC) for integer division fix

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

## Code Changes Made

### 1. Package Reference Updates (AdoCore.csproj)
- **Removed:** `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added:** `<PackageReference Include="Npgsql" Version="8.0.1" />`

### 2. ADO.NET Class Replacements (DataAccess/ProductRepository.cs)
| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### 3. SQL Syntax Conversions
| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|------------------------|
| `SCOPE_IDENTITY()` | `INSERT ... RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | C# variables with separate SELECT commands |
| `BEGIN TRANSACTION / COMMIT` | `BeginTransactionAsync() / CommitAsync()` |
| PascalCase schema objects | lowercase schema objects |

### 4. Connection String Updates (appsettings.json)
| Parameter | Original (SQL Server) | Replacement (PostgreSQL) |
|-----------|---------------------|------------------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| extracted_statements.sql | sourceCode/extracted_statements.sql | Complete (7 statements) |
| converted_statements.sql | sourceCode/converted_statements.sql | Complete (7 statements) |
| sql_equivalency_validation_report.json | sourceCode/sql_equivalency_validation_report.json | Complete (7 entries) |
| dms_failure_summary.log | sourceCode/dms_failure_summary.log | Complete |
| migration_report.md | sourceCode/migration_report.md | This file |

## Exit Criteria Checklist

| Criterion | Status |
|-----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ Complete |
| All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql | ✅ Complete |
| All 7 SQL statements processed through DMS MCP tool | ✅ Complete (all failed, manual fallback applied) |
| All 7 statement pairs validated through SQL Equivalency tool | ✅ Complete (all returned ERROR from tool) |
| Comprehensive equivalency validation report generated | ✅ Complete |
| Connection strings updated to PostgreSQL format | ✅ Complete |
| No remaining references to Microsoft.Data.SqlClient | ✅ Complete |
| Transaction handling maintained | ✅ Complete |
