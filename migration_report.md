# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (code) | 7 |
| Total SQL statements processed (scripts) | 16 |
| **Total SQL statements processed** | **23** |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 23 |
| Statements validated as equivalent (by SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 23 |

## DMS Tool Status

All 23 SQL statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) as required. The tool consistently failed with the following error:

```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
```

Per the transformation definition, manual conversion was applied with lowercase schema object names for all statements. The conversion method is documented as `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Tool Status

All 23 SQL statement pairs (original MS SQL and converted PostgreSQL) were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). The tool consistently returned:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

No agent judgment was used to determine equivalency — all statuses come exclusively from the tool output.

## Key Conversions Applied

### SQL Syntax Changes
| SQL Server | PostgreSQL | Context |
|-----------|-----------|---------|
| `IDENTITY(1,1)` | `SERIAL` | Auto-increment primary keys |
| `GETDATE()` | `NOW()` | Current timestamp |
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` | Get last inserted ID |
| `nvarchar(n)` | `VARCHAR(n)` | String types |
| `datetime` | `TIMESTAMP` | Date/time types |
| `bit` | `BOOLEAN` | Boolean values |
| `DEFAULT 0/1` (bit) | `DEFAULT FALSE/TRUE` | Boolean defaults |
| `DECLARE @var / SET @var` | Separate queries or PL/pgSQL variables | Variable handling |
| `BEGIN TRANSACTION / COMMIT` | Programmatic `NpgsqlTransaction` | Transaction management |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Stored procedures → Functions |
| `CREATE TRIGGER...inserted/deleted` | `CREATE TRIGGER...TG_OP, NEW, OLD` | Trigger syntax |
| `SYSTEM_USER` | `current_user` | Current user reference |
| `IsDiscontinued = 1` | `isdiscontinued = TRUE` | Boolean comparisons |
| `GO` delimiter | Removed | Batch separator |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP IF EXISTS` / `CREATE TABLE IF NOT EXISTS` | Object existence checks |

### Schema Name Changes
All schema object names (tables, columns, aliases, CTEs) were converted to lowercase for PostgreSQL compatibility.

### ADO.NET Class Replacements
| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All SQL statements converted; SqlClient → Npgsql; Transaction handling restructured |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (comprehensive version) |
| `README.md` | Updated to reflect PostgreSQL as target database |

## New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements from code |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 23 statements |
| `migration_report.md` | This migration report |

## Code Statement Details (from ProductRepository.cs)

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER)
- **Changes**: Lowercase schema names, compatible PostgreSQL syntax
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window functions
- **Changes**: Lowercase schema names
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Changes**: SCOPE_IDENTITY() → RETURNING clause; GETDATE() → NOW(); DECLARE/SET removed; Restructured to use programmatic NpgsqlTransaction with separate commands
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, UPDATE, INSERT
- **Changes**: DECLARE removed; GETDATE() → NOW(); Restructured to use separate commands within NpgsqlTransaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, CASE expression, DELETE
- **Changes**: DECLARE removed; GETDATE() → NOW(); Restructured to use separate commands within NpgsqlTransaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK and PERCENT_RANK window functions
- **Changes**: Lowercase schema names
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, ROUND
- **Changes**: Lowercase schema names; Added CAST to numeric for integer division in ROUND
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

## Statements Requiring Manual Review

All 23 statements require manual review since:
1. DMS tool was unavailable (metadata model creation failure) — manual conversion applied
2. SQL Equivalency tool returned ERROR for all pairs — automated equivalency could not be verified

**Recommendation**: Manual testing against a PostgreSQL database is required to verify functional correctness of all converted statements.

## Build Status

The application builds successfully after migration:
- **Build Result**: Success
- **Errors**: 0
- **Warnings**: 10 (pre-existing nullable reference warnings, not related to migration)
- **Package**: Npgsql 8.0.6 (no known security vulnerabilities)
