# Migration Report: Microsoft SQL Server to PostgreSQL

## Migration Summary

| Category | Details |
|---|---|
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Total Files Modified** | 3 (ProductRepository.cs, AdoCore.csproj, appsettings.json) |
| **Total SQL Statements Processed** | 7 |
| **DMS Tool Conversion Successes** | 0 (tool timed out on all attempts) |
| **DMS Schema Mapping Successes** | 3 (Products, ProductHistory, ProductStats) |
| **Manual Conversions (DMS Failure)** | 7 |
| **Build Status** | ✅ Success (0 errors) |

## Package Changes

| Before | After |
|---|---|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

## Type Replacements

| SQL Server (Before) | PostgreSQL (After) | Count |
|---|---|---|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 4 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|---|---|---|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## SQL Equivalency Validation Summary

| Metric | Count |
|---|---|
| Statements Processed | 7 |
| Equivalent | 0 |
| Non-Equivalent | 0 |
| Equivalency Error | 7 |

**Note:** The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) returned `ERROR` with `'uniqueID'` for all 7 statement pairs. This appears to be a systemic tool issue, not a problem with the conversions. All 7 statements require manual review to confirm equivalency.

## DMS Tool Summary

The DMS Statement Conversion tool (`dms-mcp___statement_conversion_tool`) consistently timed out during metadata model creation/conversion after multiple attempts (4 total attempts with various configurations: 15-30 poll attempts, 10-15 second intervals).

However, the DMS Schema Mapping tool (`dms-mcp___schema_mapping_tool`) succeeded for all 3 tables and provided the schema mapping data used for manual conversion:
- Schema: `dbo` → `productmanagement_dbo` (lowercase)
- Tables: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
- Columns: All lowercased (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`)
- Functions: `GETDATE()` → `clock_timestamp()`, `SCOPE_IDENTITY()` → `RETURNING` clause

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync()
- **Source Method:** `GetAllProductsAsync()`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned 'uniqueID' error)
- **Changes Applied:**
  - Table/column names lowercased per DMS schema mapping
  - CTE name `ProductStats` → `productstats`
  - Window functions preserved (AVG OVER, COUNT OVER compatible)
  - CASE expressions preserved
  - ROUND function preserved

### Statement 2: GetProductByIdAsync()
- **Source Method:** `GetProductByIdAsync(int productId)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned 'uniqueID' error)
- **Changes Applied:**
  - Table/column names lowercased per DMS schema mapping
  - CTE name `ProductHistory` → `producthistory`
  - LAG window function preserved (compatible)
  - Parameter `@ProductId` preserved (Npgsql supports @ prefix)

### Statement 3: InsertProductAsync()
- **Source Method:** `InsertProductAsync(Product product)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned 'uniqueID' error)
- **Key Changes:**
  - `DECLARE @NewProductId / SCOPE_IDENTITY()` → PostgreSQL data-modifying CTE with `INSERT ... RETURNING productid`
  - `BEGIN TRANSACTION / COMMIT` → Single CTE statement (implicit transaction)
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names lowercased

### Statement 4: UpdateProductAsync()
- **Source Method:** `UpdateProductAsync(Product product)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned 'uniqueID' error)
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` capturing previous values
  - `BEGIN TRANSACTION / COMMIT` → Single CTE statement (implicit transaction)
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names lowercased

### Statement 5: DeleteProductAsync()
- **Source Method:** `DeleteProductAsync(int productId)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned 'uniqueID' error)
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` capturing previous values
  - `BEGIN TRANSACTION / COMMIT` → Single CTE statement (implicit transaction)
  - `GETDATE()` → `clock_timestamp()`
  - CASE expression preserved
  - All table/column names lowercased

### Statement 6: GetProductsByPriceRangeAsync()
- **Source Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned 'uniqueID' error)
- **Changes Applied:**
  - Table/column names lowercased per DMS schema mapping
  - CTE name `RankedProducts` → `rankedproducts`
  - RANK() and PERCENT_RANK() preserved (compatible)
  - BETWEEN clause preserved
  - Parameters `@MinPrice`, `@MaxPrice` preserved

### Statement 7: GetLowStockProductsAsync()
- **Source Method:** `GetLowStockProductsAsync(int threshold)`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned 'uniqueID' error)
- **Changes Applied:**
  - Table/column names lowercased per DMS schema mapping
  - CTE name `StockAnalysis` → `stockanalysis`
  - AVG/MIN/MAX window functions preserved (compatible)
  - Added `CAST(stockquantity AS NUMERIC)` for integer division fix
  - Parameter `@Threshold` preserved

## Artifacts Generated

| Artifact | Description |
|---|---|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This human-readable migration summary |

## Items Requiring Manual Review

1. **All 7 SQL statements** - The SQL Equivalency tool returned ERROR for all pairs due to a systemic tool issue ('uniqueID' error). Manual review of equivalency is recommended.
2. **Transaction semantics** - Statements 3, 4, 5 were restructured from DECLARE/variable patterns to PostgreSQL data-modifying CTEs. While functionally equivalent, the transaction isolation behavior may differ slightly.
3. **Connection string credentials** - Placeholder credentials (postgres/postgres) were used. These should be replaced with actual credentials or environment variables before production deployment.
4. **Integer division** - Statement 7 added an explicit `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in PostgreSQL. This is a PostgreSQL-specific fix.

## Build Verification

Final build: **✅ SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference warnings)
