# Migration Report: SQL Server to PostgreSQL - AdoCore Application

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-24 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Total SQL Statements Processed** | 7 |
| **DMS Conversion Successes** | 0 |
| **DMS Conversion Failures** | 7 |
| **Manual Conversions (with lowercase schema)** | 7 |
| **Equivalency Validated** | 7 (all returned ERROR from tool) |
| **Build Status** | SUCCESS (0 errors, 10 pre-existing warnings) |

## DMS Tool Status

The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements.
All 7 attempts failed with metadata model creation/conversion timeout errors.

The DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) was successful and provided the following schema mappings:

| Source (MS SQL) | Target (PostgreSQL) |
|-----------------|---------------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

All column names were mapped to lowercase per DMS schema mapping.

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, CASE, JOIN
- **DMS Status**: FAILED (Metadata model conversion timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID' error from tool)
- **Key Changes**: Schema `[dbo].[Products]` → `productmanagement_dbo.products`, all columns lowercase

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, CASE
- **DMS Status**: FAILED (Metadata model conversion timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID' error from tool)
- **Key Changes**: Schema prefix, lowercase columns, parameterized WHERE

### Statement 3: InsertProductAsync
- **Type**: Transaction block (INSERT + INSERT + UPDATE + SELECT)
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID' error from tool)
- **Key Changes**: `BEGIN TRANSACTION`→`BEGIN`, `COMMIT TRANSACTION`→`COMMIT`, `SCOPE_IDENTITY()`→`lastval()`, `GETDATE()`→`clock_timestamp()`

### Statement 4: UpdateProductAsync
- **Type**: Transaction block (INSERT subquery + UPDATE + UPDATE subquery)
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID' error from tool)
- **Key Changes**: `SELECT TOP 1`→`SELECT ... LIMIT 1`, `GETDATE()`→`clock_timestamp()`

### Statement 5: DeleteProductAsync
- **Type**: Transaction block (INSERT subquery + DELETE + UPDATE with CASE)
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID' error from tool)
- **Key Changes**: `ISNULL()`→`COALESCE()`, `SELECT TOP 1`→`SELECT ... LIMIT 1`

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID' error from tool)
- **Key Changes**: Schema prefix, lowercase columns

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR ('uniqueID' error from tool)
- **Key Changes**: Schema prefix, lowercase columns

## SQL Equivalency Validation

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).
All 7 returned `ERROR` status with error message `'uniqueID'`, which appears to be a tool-side issue.

| Total Processed | Equivalent | Non-Equivalent | Errors |
|-----------------|-----------|----------------|--------|
| 7 | 0 | 0 | 7 |

Full report: `sql_equivalency_validation_report.json`

## Package Dependencies

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` | **Removed** |
| N/A | `Npgsql 8.0.6` |
| `Microsoft.Extensions.Configuration 8.0.0` | `Microsoft.Extensions.Configuration 8.0.0` (unchanged) |
| `Microsoft.Extensions.Configuration.Json 8.0.0` | `Microsoft.Extensions.Configuration.Json 8.0.0` (unchanged) |
| `Microsoft.Extensions.DependencyInjection 8.0.0` | `Microsoft.Extensions.DependencyInjection 8.0.0` (unchanged) |

## Code Changes Inventory

### DataAccess/ProductRepository.cs
- **Imports**: `using Npgsql;` (was `using Microsoft.Data.SqlClient;`)
- **ADO.NET Classes**: All using Npgsql equivalents:
  - `NpgsqlConnection` (was `SqlConnection`)
  - `NpgsqlCommand` (was `SqlCommand`)
  - `NpgsqlDataReader` (was `SqlDataReader`)
- **SQL Statements**: All 7 converted to PostgreSQL syntax
- **MapProductFromReader**: Column references updated to lowercase (`reader["productid"]`, etc.)
- **Transaction handling**: Using `BeginTransactionAsync()`/`CommitAsync()`/`RollbackAsync()` (PostgreSQL compatible)

### appsettings.json
- **Connection Strings**: PostgreSQL format with `Host=`, `Database=`, `Username=`, `Password=`
- No SQL Server format remnants

### AdoCore.csproj
- Npgsql 8.0.6 package reference present
- No Microsoft.Data.SqlClient reference

### Program.cs
- No SQL Server references

## Transformation Artifacts

| Artifact | Location |
|----------|----------|
| Extracted SQL Statements Catalog | `extracted_statements.sql` |
| Converted SQL Statements Catalog | `converted_statements.sql` |
| SQL Equivalency Validation Report | `sql_equivalency_validation_report.json` |
| Migration Report | `migration_report.md` |

## Key MS SQL → PostgreSQL Conversion Patterns Applied

| MS SQL Server | PostgreSQL |
|---------------|------------|
| `[dbo].[TableName]` | `productmanagement_dbo.tablename` |
| `SCOPE_IDENTITY()` | `lastval()` |
| `GETDATE()` | `clock_timestamp()` |
| `BEGIN TRANSACTION` | `BEGIN` |
| `COMMIT TRANSACTION` | `COMMIT` |
| `SELECT TOP 1 ... ORDER BY` | `SELECT ... ORDER BY ... LIMIT 1` |
| `ISNULL(x, y)` | `COALESCE(x, y)` |
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| PascalCase columns | lowercase columns |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Notes for Manual Review

1. All 7 DMS statement conversions failed with timeout - manual conversion applied using DMS schema mapping tool's confirmed schema mappings
2. All 7 equivalency validations returned ERROR from the tool - these require manual review to confirm correctness
3. The conversion patterns applied are standard MS SQL → PostgreSQL conversions verified against DMS schema mapping output
