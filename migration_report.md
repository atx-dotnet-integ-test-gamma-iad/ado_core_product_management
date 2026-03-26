# Migration Report: SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| Migration Date | 2026-03-25 |
| Source Database | Microsoft SQL Server 2019 |
| Target Database | PostgreSQL 13 |
| Application Framework | .NET 9.0 (ADO.NET) |
| Total SQL Statements Processed | 7 |
| DMS Successful Conversions | 0 |
| Manual Conversions (DMS Failure) | 7 |
| Equivalency: Validated as Equivalent | 0 |
| Equivalency: Validated as Non-Equivalent | 0 |
| Equivalency: Validation Errors | 7 |

## DMS Tool Results

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) as required. All 7 failed with timeout errors:

| Statement | Method | DMS Error |
|-----------|--------|-----------|
| 1 | GetAllProductsAsync | Metadata model conversion timeout after 15 attempts |
| 2 | GetProductByIdAsync | Metadata model conversion timeout after 15 attempts |
| 3 | InsertProductAsync | Metadata model creation timeout after 15 attempts |
| 4 | UpdateProductAsync | Metadata model creation timeout after 15 attempts |
| 5 | DeleteProductAsync | Metadata model creation timeout after 15 attempts |
| 6 | GetProductsByPriceRangeAsync | Metadata model conversion timeout after 15 attempts |
| 7 | GetLowStockProductsAsync | Metadata model creation timeout after 15 attempts |

All 7 statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:
- All schema object names converted to lowercase for PostgreSQL compatibility
- MS SQL-specific functions replaced with PostgreSQL equivalents

## SQL Equivalency Validation Results

All 7 statement pairs were validated using the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR status with error: `'uniqueID'`.

The equivalency tool appears to have experienced a systematic error. No agent judgment was used to determine equivalency status. All statements are marked as ERROR per the transformation definition requirements.

**Full report available in:** `sql_equivalency_validation_report.json`

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | 7 SQL statements converted to PostgreSQL; all SqlClient classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 9.0.5` |
| `appsettings.json` | SQL Server connection strings → PostgreSQL connection strings |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL syntax (comprehensive) |

## Transformations Applied

### Package Dependencies
- `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 9.0.5`

### ADO.NET Class Replacements
| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|-------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### SQL Syntax Conversions
| MS SQL Server | PostgreSQL |
|---------------|-----------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (via CTE) |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION` | Removed (ADO.NET transaction management) |
| `DECLARE @var` / `SET @var` | Restructured to use CTEs with subqueries |
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR` | `VARCHAR` |
| `DATETIME` | `TIMESTAMP` |
| `BIT` | `BOOLEAN` |
| `[dbo].[TableName]` | `tablename` (lowercase) |
| `SYSTEM_USER` | `CURRENT_USER` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `GO` | Removed |

### Connection String Conversions
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Port=5432` |

## SQL Statement Details

### Statement 1: GetAllProductsAsync
- **Type:** CTE with AVG/COUNT OVER(), INNER JOIN, CASE, ROUND
- **Key Changes:** Lowercase schema objects
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG OVER(), LEFT JOIN, CASE, ROUND
- **Key Changes:** Lowercase schema objects
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes:** Restructured using CTE with INSERT...RETURNING, lastval() replaced SCOPE_IDENTITY(), NOW() replaced GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Key Changes:** Restructured using CTE with old_values pattern to avoid DECLARE blocks, NOW() replaced GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE
- **Key Changes:** Restructured using CTE with old_values pattern, INSERT...SELECT for history, NOW() replaced GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK()/PERCENT_RANK() OVER(), BETWEEN, CASE
- **Key Changes:** Lowercase schema objects
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX OVER(), CASE, ROUND
- **Key Changes:** Lowercase schema objects, added `::numeric` cast for integer division in ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool was unavailable (timeout errors on all attempts)
2. SQL Equivalency tool returned ERROR status for all pairs
3. Manual conversion was applied with lowercase schema naming convention

**Recommended Actions:**
- Verify SQL statement behavior against a live PostgreSQL database
- Test all CRUD operations end-to-end
- Validate transaction behavior (especially for Statements 3, 4, 5 which were significantly restructured)
- Confirm CTE-based INSERT/UPDATE/DELETE with RETURNING clause works as expected with Npgsql

## Build Status

- **Final Build:** ✅ SUCCESS (0 errors, 10 warnings - all pre-existing nullability warnings)
- **dotnet restore:** ✅ SUCCESS
- **No remaining SQL Server references in code**

## Exit Criteria Verification

| Criteria | Status |
|----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ |
| All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents | ✅ |
| ALL SQL statements processed through DMS MCP tool | ✅ (all 7 attempted, all failed) |
| Comprehensive catalog of SQL statements exists | ✅ |
| ALL statement pairs validated through SQL Equivalency tool | ✅ (all 7 validated, all ERROR) |
| Comprehensive equivalency validation report generated | ✅ |
| DMS failures documented with manual conversion | ✅ |
| Connection strings updated to PostgreSQL format | ✅ |
| Transaction handling updated | ✅ |
| Application compiles without errors | ✅ |

## Artifact Files

| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report |
| `migration_report.md` | This report |
