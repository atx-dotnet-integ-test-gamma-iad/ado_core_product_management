# Migration Report: MS SQL Server to PostgreSQL

## Summary
Migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. This report documents all SQL statements processed, conversion results, and changes made.

**Migration Date:** 2026-02-28  
**Source Database:** ProductManagement (SQL Server 2019)  
**Target Database:** PostgreSQL 13  
**DMS Migration Project:** arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
All 7 statements were submitted to the DMS MCP tool as required. All returned the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
Manual conversion was performed using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol.

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency validation tool. All returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

---

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync
**Source:** `sourceCode/DataAccess/ProductRepository.cs`, method `GetAllProductsAsync`  
**Type:** SELECT with CTE, window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND, ORDER BY CASE  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool internal error)

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts FROM Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

**Changes:** Lowercased all schema object and column names.

---

### Statement 2: GetProductByIdAsync
**Source:** `sourceCode/DataAccess/ProductRepository.cs`, method `GetProductByIdAsync`  
**Type:** SELECT with CTE, LAG window function, LEFT JOIN, CASE with NULL check, ROUND  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool internal error)

**Changes:** Lowercased all schema object and column names.

---

### Statement 3: InsertProductAsync
**Source:** `sourceCode/DataAccess/ProductRepository.cs`, method `InsertProductAsync`  
**Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats, GETDATE()  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool internal error)

**Key Changes:**
- `SCOPE_IDENTITY()` → `RETURNING productid` clause
- `GETDATE()` → `NOW()`
- T-SQL `DECLARE @NewProductId`/`SET @NewProductId` → C# variable from `ExecuteScalarAsync()` with RETURNING
- Single batch → 3 separate NpgsqlCommand calls within C# transaction
- All schema objects lowercased

---

### Statement 4: UpdateProductAsync
**Source:** `sourceCode/DataAccess/ProductRepository.cs`, method `UpdateProductAsync`  
**Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats, GETDATE()  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool internal error)

**Key Changes:**
- `DECLARE @OldPrice`/`DECLARE @OldStock` → C# variables from DataReader
- `SELECT @OldPrice = Price, @OldStock = StockQuantity` → Standard SELECT with reader
- `GETDATE()` → `NOW()`
- Single T-SQL batch → 4 separate NpgsqlCommand calls within C# transaction
- All schema objects lowercased

---

### Statement 5: DeleteProductAsync
**Source:** `sourceCode/DataAccess/ProductRepository.cs`, method `DeleteProductAsync`  
**Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE, GETDATE()  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool internal error)

**Key Changes:**
- Same as Statement 4: DECLARE variables → C# variables
- `GETDATE()` → `NOW()`
- Single T-SQL batch → 4 separate NpgsqlCommand calls within C# transaction
- All schema objects lowercased

---

### Statement 6: GetProductsByPriceRangeAsync
**Source:** `sourceCode/DataAccess/ProductRepository.cs`, method `GetProductsByPriceRangeAsync`  
**Type:** SELECT with CTE, RANK, PERCENT_RANK window functions, BETWEEN, CASE  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool internal error)

**Changes:** Lowercased all schema object and column names.

---

### Statement 7: GetLowStockProductsAsync
**Source:** `sourceCode/DataAccess/ProductRepository.cs`, method `GetLowStockProductsAsync`  
**Type:** SELECT with CTE, AVG, MIN, MAX window functions, CASE, ROUND  
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA  
**Equivalency Status:** ERROR (tool internal error)

**Key Changes:**
- Lowercased all schema object and column names
- Added `CAST(stockquantity AS NUMERIC)` to prevent integer division in ROUND

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.6 |
| `Microsoft.Extensions.Configuration` 8.0.0 | `Microsoft.Extensions.Configuration` 8.0.0 (unchanged) |
| `Microsoft.Extensions.Configuration.Json` 8.0.0 | `Microsoft.Extensions.Configuration.Json` 8.0.0 (unchanged) |
| `Microsoft.Extensions.DependencyInjection` 8.0.0 | `Microsoft.Extensions.DependencyInjection` 8.0.0 (unchanged) |

Note: Initially added Npgsql 8.0.1 as specified in plan, but upgraded to 8.0.6 to address known vulnerability GHSA-x9vc-6hfv-hg8c.

---

## Connection String Changes

| Connection | Before | After |
|-----------|--------|-------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |
| ProdConnection | Same as above | Same as above |

**Parameter Mapping:**
- `Server=` → `Host=`
- `Database=` → `Database=` (unchanged)
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- `MultipleActiveResultSets=true` → Removed (not applicable to PostgreSQL)
- `TrustServerCertificate=True` → Removed (not applicable to PostgreSQL)

---

## ADO.NET Class Replacements

| MS SQL Server Class | Npgsql Equivalent | Locations |
|-------------------|-------------------|-----------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | Line 5 |
| `SqlConnection` | `NpgsqlConnection` | Field declaration, GetConnectionAsync return type, constructor |
| `SqlCommand` | `NpgsqlCommand` | All 11 command creation instances |
| `SqlDataReader` | `NpgsqlDataReader` | MapProductFromReader parameter, all reader usages |

---

## Files Modified

| File | Changes |
|------|---------|
| `sourceCode/DataAccess/ProductRepository.cs` | SQL statements, ADO.NET classes, using directive |
| `sourceCode/AdoCore.csproj` | Package reference SqlClient → Npgsql |
| `sourceCode/appsettings.json` | Connection strings to PostgreSQL format |
| `sourceCode/Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL/function conversion |
| `sourceCode/Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL/function/trigger conversion |

## Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements with source locations |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report with all 7 statement pairs |
| `migration_report.md` | This comprehensive migration report |

---

## Build Status
**Final Build: SUCCESS** (0 errors, warnings are pre-existing nullable reference type warnings)
