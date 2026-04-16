# Migration Report: Microsoft SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-16 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Source Framework** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Framework** | Npgsql 8.0.6 |
| **Application Framework** | .NET 9.0 (ADO.NET) |

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Statements successfully converted by DMS** | 0 |
| **Statements requiring manual intervention** | 7 |
| **Equivalency validated as EQUIVALENT** | 0 |
| **Equivalency validated as NOT_EQUIVALENT** | 0 |
| **Equivalency validation ERROR** | 7 |

### DMS Tool Status
All 7 statements were submitted to the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`). All failed with:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion method used**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency validation tool (`sql-equivalency___validate_sql_equivalence`). All returned:
- **Status**: `ERROR`
- **Error**: `'uniqueID'`
- This appears to be a service infrastructure issue unrelated to the SQL statements themselves.

### Schema Mapping (from DMS schema_mapping_tool - successful)
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

---

## SQL Statements Converted

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ORDER BY
- **Key changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo` added
- **Conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency status**: ERROR (tool infrastructure issue)

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, parameterized WHERE
- **Key changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo` added
- **Conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency status**: ERROR (tool infrastructure issue)

### Statement 3: InsertProductAsync
- **Type**: T-SQL transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE()
- **Key changes**: `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `clock_timestamp()`, single T-SQL block split into 3 separate NpgsqlCommand calls with C# transaction management
- **Conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency status**: ERROR (tool infrastructure issue)

### Statement 4: UpdateProductAsync
- **Type**: T-SQL transaction block with DECLARE variables, multiple operations
- **Key changes**: `GETDATE()` → `clock_timestamp()`, DECLARE variables removed (handled in C#), split into 4 separate NpgsqlCommand calls with C# transaction management
- **Conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency status**: ERROR (tool infrastructure issue)

### Statement 5: DeleteProductAsync
- **Type**: T-SQL transaction block with DECLARE, DELETE, CASE expression
- **Key changes**: `GETDATE()` → `clock_timestamp()`, DECLARE variables removed (handled in C#), split into 4 separate NpgsqlCommand calls with C# transaction management
- **Conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency status**: ERROR (tool infrastructure issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Key changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo` added
- **Conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency status**: ERROR (tool infrastructure issue)

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX OVER window functions, CASE, ROUND
- **Key changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo` added, `CAST(stockquantity AS NUMERIC)` for integer division fix
- **Conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency status**: ERROR (tool infrastructure issue)

---

## Files Modified

| File | Changes |
|------|---------|
| `sourceCode/DataAccess/ProductRepository.cs` | Replaced all SQL statements, ADO.NET types (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader), using statement, restructured transactional methods |
| `sourceCode/AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `sourceCode/appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

## Files Created

| File | Purpose |
|------|---------|
| `sourceCode/extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `sourceCode/converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sourceCode/sql_equivalency_validation_report.json` | Complete equivalency validation report in JSON format |
| `sourceCode/migration_report.md` | This migration report |

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` Version 5.1.4 | `Npgsql` Version 8.0.6 |
| `Microsoft.Extensions.Configuration` Version 8.0.0 | *(unchanged)* |
| `Microsoft.Extensions.Configuration.Json` Version 8.0.0 | *(unchanged)* |
| `Microsoft.Extensions.DependencyInjection` Version 8.0.0 | *(unchanged)* |

---

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Database=postgres;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=postgres` |
| `Trusted_Connection=True` | Removed (replaced with Username/Password auth) |
| `MultipleActiveResultSets=true` | Removed (not applicable to PostgreSQL) |
| `TrustServerCertificate=True` | Removed (not applicable to PostgreSQL) |
| *(N/A)* | `Username=postgres` |
| *(N/A)* | `Password=postgres` |

---

## ADO.NET Type Replacements

| SQL Server Type | Npgsql Type |
|----------------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` (via `BeginTransactionAsync()`) |

---

## T-SQL Specific Conversions

| T-SQL Construct | PostgreSQL Equivalent |
|----------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` clause |
| `GETDATE()` | `clock_timestamp()` |
| `DECLARE @var TYPE; SET @var = ...` | C# variables with separate SELECT query |
| `BEGIN TRANSACTION / COMMIT` (in SQL) | `NpgsqlTransaction` in C# code |
| Integer column names (PascalCase) | Lowercase column names |
| `[dbo].` schema prefix | `productmanagement_dbo.` schema prefix |

---

## Statements Requiring Manual Review

All 7 statements should be manually reviewed since:
1. DMS conversion tool was unavailable (metadata model creation failed)
2. SQL Equivalency validation tool returned ERROR for all pairs
3. Manual conversion was applied using DMS schema mapping data

Key areas requiring attention:
- Transaction handling in `InsertProductAsync`, `UpdateProductAsync`, `DeleteProductAsync` was restructured from single T-SQL blocks to multiple C# NpgsqlCommand calls
- Column name references in `MapProductFromReader` changed to lowercase (e.g., `reader["ProductId"]` → `reader["productid"]`)
- Schema prefix `productmanagement_dbo` was applied based on DMS schema_mapping_tool output

---

## Build Status

**Build: SUCCEEDED** (0 errors, 10 warnings)

All warnings are pre-existing nullable reference warnings, not introduced by the migration:
- CS8618: Non-nullable property/field warnings
- CS8601: Possible null reference assignment
- CS8600: Converting null literal warnings
- CS8603: Possible null reference return
- CS8625: Cannot convert null literal to non-nullable reference type

---

## Artifacts Location

- **Extracted statements**: `sourceCode/extracted_statements.sql`
- **Converted statements**: `sourceCode/converted_statements.sql`
- **Equivalency report**: `sourceCode/sql_equivalency_validation_report.json`
- **Migration report**: `sourceCode/migration_report.md`
