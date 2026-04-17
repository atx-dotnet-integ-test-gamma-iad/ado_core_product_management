# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Conversion Successful | 0 |
| DMS Conversion Failed | 7 |
| Manual Conversions Applied | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |

## DMS Tool Results

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied for all statements using lowercase schema object names, as per the transformation definition guideline: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR status:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a tool-side issue affecting all validations. Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR."

## SQL Statements Converted

### 1. GetAllProductsAsync
- **Type**: SELECT with CTE, window functions
- **Key Changes**: Lowercase schema objects
- **Compatibility**: High (standard SQL window functions)

### 2. GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function
- **Key Changes**: Lowercase schema objects
- **Compatibility**: High (standard SQL window functions)

### 3. InsertProductAsync
- **Type**: Transaction with INSERT, SCOPE_IDENTITY, GETDATE
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING` with writable CTE
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `DECLARE @var` / `SET` → Writable CTE pattern
  - `BEGIN TRANSACTION`/`COMMIT` → Single atomic CTE statement
- **Compatibility**: Medium (significant restructuring)

### 4. UpdateProductAsync
- **Type**: Transaction with DECLARE, SELECT INTO, UPDATE, INSERT
- **Key Changes**:
  - `DECLARE @var` / `SELECT INTO @var` → Writable CTE with `old_values`
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `BEGIN TRANSACTION`/`COMMIT` → Single atomic CTE statement
- **Compatibility**: Medium (significant restructuring)

### 5. DeleteProductAsync
- **Type**: Transaction with DECLARE, SELECT INTO, DELETE, UPDATE
- **Key Changes**:
  - `DECLARE @var` / `SELECT INTO @var` → Writable CTE with `old_values`
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `BEGIN TRANSACTION`/`COMMIT` → Single atomic CTE statement
  - `CASE` expression in `UPDATE` preserved
- **Compatibility**: Medium (significant restructuring)

### 6. GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK, PERCENT_RANK
- **Key Changes**: Lowercase schema objects
- **Compatibility**: High (standard SQL window functions)

### 7. GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER
- **Key Changes**: 
  - Lowercase schema objects
  - Added `::numeric` cast for integer division in `ROUND`
- **Compatibility**: High (minor casting change)

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL strings, updated all type references, updated column reader keys |
| `appsettings.json` | Updated connection strings to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL and functions |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL, triggers, functions, and sample data |

## Package Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |

## Type Replacements

| Original (Microsoft.Data.SqlClient) | Replacement (Npgsql) |
|--------------------------------------|---------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Port | (default 1433) | `Port=5432` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed |

## SQL Script Conversions

### Key SQL Server → PostgreSQL Syntax Changes Applied
- `IF NOT EXISTS (SELECT * FROM sys.objects...)` → `CREATE TABLE IF NOT EXISTS` / `DROP TABLE IF EXISTS`
- `IDENTITY(1,1)` → `SERIAL`
- `NVARCHAR(n)` → `VARCHAR(n)`
- `BIT` → `BOOLEAN`
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `SYSTEM_USER` → `current_user`
- `GO` batch separators → Removed
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- SQL Server triggers → PostgreSQL trigger functions + `CREATE TRIGGER`
- `SCOPE_IDENTITY()` → `RETURNING` clause

## Build Verification

**Final build status: SUCCESS**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings)

## Artifacts

| Artifact | Location |
|----------|----------|
| Extracted SQL Statements | `extracted_statements.sql` |
| Converted SQL Statements | `converted_statements.sql` |
| SQL Equivalency Report | `sql_equivalency_validation_report.json` |
| Migration Report | `migration_report.md` |

## Manual Interventions Required

All 7 SQL statements required manual conversion due to DMS tool failure. The following conversions required significant restructuring:

1. **InsertProductAsync**: Restructured from sequential `DECLARE`/`INSERT`/`SCOPE_IDENTITY()` to PostgreSQL writable CTE pattern with `INSERT...RETURNING`
2. **UpdateProductAsync**: Restructured from `DECLARE`/`SELECT INTO @var` to writable CTE pattern
3. **DeleteProductAsync**: Restructured from `DECLARE`/`SELECT INTO @var` to writable CTE pattern

These restructured statements maintain the same logical behavior but use PostgreSQL-idiomatic patterns that work with Npgsql parameterized queries.
