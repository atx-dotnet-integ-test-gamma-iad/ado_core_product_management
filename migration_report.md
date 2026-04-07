# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total inline SQL statements processed | 7 |
| DMS conversion attempts | 7 |
| DMS conversion successes | 0 |
| DMS conversion failures | 7 |
| Manual conversions (with lowercase schema) | 7 |
| SQL Equivalency validations attempted | 7 |
| SQL Equivalency result: EQUIVALENT | 0 |
| SQL Equivalency result: NOT_EQUIVALENT | 0 |
| SQL Equivalency result: ERROR | 7 |

## DMS Tool Status

All 7 inline SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All 7 failed with the same error:

> **Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}

Due to DMS failures, all statements were manually converted with the conversion method `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`, applying lowercase schema object names for PostgreSQL compatibility.

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All 7 returned ERROR:

> **Error**: 'uniqueID'

Per the transformation definition, these are marked as ERROR status in the report, as agent judgment was not used to determine equivalency.

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statement blocks with PostgreSQL equivalents; Replaced SqlClient with Npgsql classes; Updated column name references to lowercase |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax (including triggers) |

## Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Detailed equivalency validation report |
| `migration_report.md` | This report |

## Detailed SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE SELECT with AVG/COUNT window functions
- **Key Changes**: Schema names lowercased, CTE renamed from `ProductStats` to `productstats_cte` to avoid table name conflict
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: CTE SELECT with LAG window function
- **Key Changes**: Schema names lowercased, CTE renamed from `ProductHistory` to `producthistory_cte`
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**: `SCOPE_IDENTITY()` → `RETURNING productid`; `GETDATE()` → `NOW()`; Single SQL string split into 3 separate commands in C# managed transaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, UPDATE, GETDATE()
- **Key Changes**: `DECLARE @var` / `SELECT @var =` pattern → separate SELECT query in C#; `GETDATE()` → `NOW()`; Single SQL string split into 4 separate commands in C# managed transaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, DELETE, GETDATE(), CASE
- **Key Changes**: Same pattern as UpdateProductAsync; `GETDATE()` → `NOW()`; Split into 4 separate commands
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE SELECT with RANK/PERCENT_RANK
- **Key Changes**: Schema names lowercased; RANK/PERCENT_RANK syntax compatible between MS SQL and PostgreSQL
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE SELECT with AVG/MIN/MAX window functions
- **Key Changes**: Schema names lowercased; Added `CAST(stockquantity AS DECIMAL)` for proper integer division
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|------------------|-------------------|
| `Microsoft.Data.SqlClient` (using) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *(removed - not applicable)* |
| TLS | `TrustServerCertificate=True` | *(removed - not applicable)* |

## Database Script Conversions

### Scripts/01_InitialSetup.sql
- `IDENTITY(1,1)` → `SERIAL`
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `nvarchar` → `varchar`
- `IF NOT EXISTS (SELECT * FROM sys.objects ...)` → `CREATE TABLE IF NOT EXISTS`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql`
- Removed all `GO` statements

### Database/Scripts/01_InitialSetup.sql
- Same conversions as above, plus:
- `bit` → `boolean` (e.g., `IsActive`, `IsDiscontinued`)
- `SYSTEM_USER` → `current_user`
- SQL Server `TRIGGER` with `inserted`/`deleted` tables → PostgreSQL trigger function with `NEW`/`OLD` references and `TG_OP` checks
- `sys.objects` checks → `DROP TABLE IF EXISTS` / `DROP TRIGGER IF EXISTS`

## Build Status

The application compiles successfully after migration:
```
Build succeeded.
0 Error(s)
10 Warning(s) (all pre-existing nullable reference type warnings)
```

## Artifacts

- **Detailed equivalency report**: `sql_equivalency_validation_report.json`
- **Original SQL catalog**: `extracted_statements.sql`
- **Converted SQL catalog**: `converted_statements.sql`

## Manual Review Recommendations

1. All 7 equivalency validations returned ERROR - manual review of converted SQL statements is recommended
2. Transaction-based methods (Insert, Update, Delete) were restructured from single SQL strings to multiple C# commands - verify correct behavior with actual PostgreSQL database
3. Test the `RETURNING productid` pattern with actual NpgsqlCommand.ExecuteScalarAsync() to ensure proper ID retrieval
4. Verify integer division behavior in GetLowStockProductsAsync with the added CAST
