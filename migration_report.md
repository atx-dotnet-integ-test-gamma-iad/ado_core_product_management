# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration covered all database access code, SQL statements, package dependencies, connection strings, and setup scripts.

## Migration Scope

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Status

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) consistently failed for all 7 statements with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) worked successfully and was used to determine the correct PostgreSQL schema naming conventions for manual conversion.

### DMS Schema Mapping Results

| Source Table | Target Table | Target Schema |
|-------------|-------------|---------------|
| Products | products | productmanagement_dbo |
| ProductHistory | producthistory | productmanagement_dbo |
| ProductStats | productstats | productmanagement_dbo |

## SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR for all 7 statement pairs with error: `'uniqueID'`. This appears to be a systemic tool issue unrelated to statement content.

## Manual Conversion Method

All 7 statements were manually converted using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:
- Applied lowercase schema object names per DMS schema mapping output
- Key transformations: `SCOPE_IDENTITY()` → `RETURNING`, `GETDATE()` → `clock_timestamp()`, `DECLARE @var` → C# variables, `BEGIN TRANSACTION/COMMIT` → `NpgsqlTransaction` in C#

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Changes**: All schema objects lowercase, CTE renamed to `productstats_cte` to avoid table name conflict
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, CASE, ROUND, LEFT JOIN, parameterized
- **Changes**: All schema objects lowercase, CTE renamed to `producthistory_cte`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), multiple operations
- **Changes**: Restructured from monolithic SQL to separate ADO.NET commands; `SCOPE_IDENTITY()` → `RETURNING productid`; `GETDATE()` → `clock_timestamp()`; transaction managed via `NpgsqlTransaction`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT
- **Changes**: Restructured to separate commands; `DECLARE @var/SELECT @var = ...` → C# reader + variables; `GETDATE()` → `clock_timestamp()`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, DELETE, CASE in UPDATE
- **Changes**: Same restructuring as Statement 4; CASE expression preserved (PostgreSQL compatible)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK, BETWEEN, CASE, parameterized
- **Changes**: All schema objects lowercase; RANK(), PERCENT_RANK(), BETWEEN all PostgreSQL compatible
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND, parameterized
- **Changes**: All schema objects lowercase; added `::NUMERIC` cast for integer division in ROUND()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR

## Files Modified

| File | Description |
|------|-------------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced `SqlConnection`→`NpgsqlConnection`, `SqlCommand`→`NpgsqlCommand`, `SqlDataReader`→`NpgsqlDataReader`; updated `using Microsoft.Data.SqlClient` → `using Npgsql`; restructured transaction-based methods |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server format (`Server=`, `Trusted_Connection=`, etc.) to PostgreSQL format (`Host=`, `Username=`, `Password=`) |
| `Database/Scripts/01_InitialSetup.sql` | Converted comprehensive setup script to PostgreSQL syntax (tables, triggers, functions, sample data) |
| `Scripts/01_InitialSetup.sql` | Converted simple setup script to PostgreSQL syntax |
| `README.md` | Updated to reflect PostgreSQL instead of SQL Server |

## Files Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_failure_summary.log` | DMS failure documentation |
| `migration_report.md` | This report |

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |
| `Microsoft.Extensions.Configuration 8.0.0` | *(unchanged)* |
| `Microsoft.Extensions.Configuration.Json 8.0.0` | *(unchanged)* |
| `Microsoft.Extensions.DependencyInjection 8.0.0` | *(unchanged)* |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `True` | *(removed - not applicable)* |
| TrustServerCertificate | `True` | *(removed - not applicable)* |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|-------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `System.Data.Common.DbTransaction` cast | `NpgsqlTransaction` cast | 11 |

## SQL Setup Script Conversions

### Key Syntax Changes
- `GO` → removed
- `[int] IDENTITY(1,1)` → `INTEGER GENERATED ALWAYS AS IDENTITY`
- `[nvarchar](n)` → `VARCHAR(n)`
- `[decimal](p,s)` → `NUMERIC(p,s)`
- `[datetime]` → `TIMESTAMP`
- `[bit]` → `BOOLEAN`
- `GETDATE()` → `NOW()`
- `SYSTEM_USER` → `CURRENT_USER`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION` (plpgsql)
- `SCOPE_IDENTITY()` → `RETURNING` clause
- MS SQL trigger syntax → PostgreSQL trigger function + trigger

## Issues and Warnings

1. **DMS Statement Conversion Tool Failure**: All 7 statements failed conversion via DMS. Manual conversion was applied using DMS schema mapping as reference. All conversions documented in `dms_failure_summary.log`.

2. **SQL Equivalency Tool Error**: All 7 statement pair validations returned ERROR with `'uniqueID'` error. This appears to be a systemic tool issue. All results are recorded exactly as returned by the tool in `sql_equivalency_validation_report.json`.

3. **Integer Division in PostgreSQL**: Statement 7 (GetLowStockProductsAsync) required an explicit `::NUMERIC` cast for the `stockquantity / avgstock` division to prevent PostgreSQL integer division truncation.

4. **Transaction Restructuring**: Statements 3, 4, 5 (Insert, Update, Delete) were restructured from monolithic SQL blocks with `DECLARE` and `SET` to separate ADO.NET commands with C# variable management and `NpgsqlTransaction` for transaction control. This maintains the same transactional guarantees while being compatible with PostgreSQL.
