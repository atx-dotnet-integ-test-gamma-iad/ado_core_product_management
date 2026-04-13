# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Converted by DMS | 0 |
| Statements Requiring Manual Conversion | 7 |
| Manual Conversion Reason | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validated as ERROR | 7 |

## DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`). All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Region**: us-east-1
- **Schema**: dbo
- **Root Cause**: Infrastructure issue with DMS metadata model creation (RECEIVED status not handled)

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

- **Root Cause**: Infrastructure issue with the SQL Equivalency tool ('uniqueID' error)
- **Note**: Per transformation rules, all results are marked as ERROR (never substituted with agent judgment)

## Files Modified

| File | Change Description |
|------|-------------------|
| `DataAccess/ProductRepository.cs` | Full rewrite: SqlClient → Npgsql, all 7 SQL statements converted to PostgreSQL |
| `AdoCore.csproj` | Package: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings: SQL Server format → PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted from SQL Server DDL to PostgreSQL DDL |
| `Database/Scripts/01_InitialSetup.sql` | Converted from SQL Server DDL to PostgreSQL DDL (tables, triggers, functions, data) |

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE + window functions
- **Key Changes**: Schema objects lowercased, syntax compatible
- **DMS Status**: Failed
- **Equivalency Status**: ERROR (tool infrastructure issue)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE + LAG window function
- **Key Changes**: Schema objects lowercased, LAG/ROUND compatible
- **DMS Status**: Failed
- **Equivalency Status**: ERROR (tool infrastructure issue)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with SCOPE_IDENTITY
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - Single SQL block → Multiple commands with .NET-managed transaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR (tool infrastructure issue)

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE/SET variables
- **Key Changes**:
  - `DECLARE @var / SELECT @var = col` → .NET variables with separate SELECT
  - `GETDATE()` → `NOW()`
  - Single SQL block → Multiple commands with .NET-managed transaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR (tool infrastructure issue)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE/SET variables and CASE
- **Key Changes**:
  - `DECLARE @var / SELECT @var = col` → .NET variables with separate SELECT
  - `GETDATE()` → `NOW()`
  - Single SQL block → Multiple commands with .NET-managed transaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR (tool infrastructure issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE + RANK/PERCENT_RANK
- **Key Changes**: Schema objects lowercased, RANK/PERCENT_RANK/BETWEEN compatible
- **DMS Status**: Failed
- **Equivalency Status**: ERROR (tool infrastructure issue)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE + AVG/MIN/MAX window functions
- **Key Changes**: Schema objects lowercased, added CAST for integer division in ROUND
- **DMS Status**: Failed
- **Equivalency Status**: ERROR (tool infrastructure issue)

## Package Changes

| Package | Old Version | New Version |
|---------|------------|------------|
| Microsoft.Data.SqlClient | 5.1.4 | Removed |
| Npgsql | N/A | 8.0.6 |

**Note**: Npgsql 8.0.0 was initially specified but upgraded to 8.0.6 to resolve known vulnerability (GHSA-x9vc-6hfv-hg8c).

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | N/A | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Type Replacements

| SQL Server Type | Npgsql Type |
|----------------|-------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

## SQL DDL Conversions

| SQL Server Feature | PostgreSQL Equivalent |
|-------------------|---------------------|
| `IDENTITY(1,1)` | `SERIAL` |
| `nvarchar(n)` | `varchar(n)` |
| `datetime` | `timestamp` |
| `bit` | `boolean` |
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` |
| `GO` | Removed |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SYSTEM_USER` | `current_user` |
| SQL Server trigger syntax | PostgreSQL trigger + function |
| `sys.objects` checks | `DROP IF EXISTS` |

## Build Status

**Final build: SUCCESSFUL** (0 errors, 10 pre-existing nullable reference warnings)

## Artifacts

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report with all 7 statement pairs |
| `dms_conversion_summary.md` | DMS failure documentation |
| `migration_report.md` | This report |

## Issues and Manual Interventions

1. **DMS Tool Unavailable**: All DMS conversion calls failed due to metadata model creation issue. Manual conversion was applied with lowercase schema naming per transformation rules.

2. **SQL Equivalency Tool Unavailable**: All equivalency validation calls returned ERROR due to 'uniqueID' infrastructure issue. Results are documented as ERROR per transformation rules (no agent judgment substituted).

3. **Npgsql Vulnerability**: Initial Npgsql 8.0.0 had high-severity vulnerability GHSA-x9vc-6hfv-hg8c. Upgraded to 8.0.6 which resolves the issue.

4. **Transaction Block Restructuring**: The original SQL Server code used single SQL strings with inline `BEGIN TRANSACTION`/`COMMIT` and `DECLARE`/`SET` for variable handling (statements 3, 4, 5). These were restructured into multiple sequential NpgsqlCommand calls within .NET-managed transactions, maintaining the same transactional atomicity.
