# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore - Product Management System
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Tool**: DMS MCP Statement Conversion Tool (failed - see below)
- **Validation Tool**: SQL Equivalency MCP Tool (returned ERROR for all pairs)

## DMS Tool Results
All 7 SQL statements were submitted to the DMS MCP tool for conversion.
All 7 failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

As per transformation instructions, manual conversion was performed with lowercase schema object naming for PostgreSQL compatibility.

## SQL Equivalency Validation Results
All 7 statement pairs were submitted to the SQL Equivalency tool for validation.
All 7 returned ERROR status with: `'uniqueID'`

## Statement Conversion Summary

| # | Method | Location | SQL Server Feature | PostgreSQL Equivalent |
|---|--------|----------|-------------------|---------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | CTE + Window Functions | Same (lowercase) |
| 2 | GetProductByIdAsync | ProductRepository.cs | CTE + LAG | Same (lowercase) |
| 3 | InsertProductAsync | ProductRepository.cs | SCOPE_IDENTITY(), GETDATE(), Transaction | RETURNING, NOW(), Writable CTE |
| 4 | UpdateProductAsync | ProductRepository.cs | DECLARE, GETDATE(), Transaction | Writable CTE, NOW() |
| 5 | DeleteProductAsync | ProductRepository.cs | DECLARE, GETDATE(), Transaction | Writable CTE, NOW() |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | RANK, PERCENT_RANK | Same (lowercase) |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | AVG/MIN/MAX window funcs | Same + ::numeric cast |

## Static Code Changes

### Package References (AdoCore.csproj)
- Removed: `Microsoft.Data.SqlClient` Version 5.1.4
- Added: `Npgsql` Version 8.0.1

### Namespace/Import Changes (ProductRepository.cs)
- Removed: `using Microsoft.Data.SqlClient;`
- Added: `using Npgsql;`

### Class Replacements (ProductRepository.cs)
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Changes (appsettings.json)
- Replaced: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- With: `Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;`

### Column Name References (MapProductFromReader)
- All column name references updated to lowercase to match PostgreSQL schema conventions

## Files Modified
1. `sourceCode/AdoCore.csproj` - Package reference update
2. `sourceCode/DataAccess/ProductRepository.cs` - Complete rewrite for Npgsql/PostgreSQL
3. `sourceCode/appsettings.json` - Connection string update

## Files Created
1. `sourceCode/extracted_statements.sql` - Original SQL Server statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Equivalency validation report
4. `sourceCode/migration_report.md` - This report

## Key Conversion Patterns Applied

### 1. Transaction Blocks with Variables
SQL Server uses `DECLARE @var; BEGIN TRANSACTION; ... COMMIT;` pattern.
PostgreSQL equivalent uses writable CTEs (`WITH ... AS (INSERT/UPDATE/DELETE ... RETURNING ...)`) to achieve atomic multi-statement operations within a single query.

### 2. SCOPE_IDENTITY() → RETURNING
SQL Server's `SCOPE_IDENTITY()` is replaced by PostgreSQL's `INSERT ... RETURNING productid` clause.

### 3. GETDATE() → NOW()
Direct function replacement.

### 4. Integer Division
PostgreSQL requires explicit cast (`::numeric`) for decimal division of integer columns.

### 5. Schema Object Naming
All table and column names converted to lowercase for PostgreSQL compatibility (PostgreSQL folds unquoted identifiers to lowercase).
