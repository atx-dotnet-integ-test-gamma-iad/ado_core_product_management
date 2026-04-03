# Migration Report: SQL Server to PostgreSQL

## Overview
This report documents the complete migration of the ADO.NET Core application from Microsoft SQL Server to PostgreSQL.

## Migration Date
2026-04-03

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| DataAccess/ProductRepository.cs | Modified | Replaced all SQL statements with PostgreSQL equivalents; replaced all SqlClient classes with Npgsql |
| AdoCore.csproj | Modified | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| appsettings.json | Modified | Updated connection strings from SQL Server to PostgreSQL format |
| README.md | Modified | Updated documentation to reflect PostgreSQL usage |
| Scripts/01_InitialSetup.sql | Modified | Converted SQL Server script to PostgreSQL syntax |
| Database/Scripts/01_InitialSetup.sql | Modified | Converted comprehensive SQL Server script to PostgreSQL syntax |
| extracted_statements.sql | Created | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | Created | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Created | Comprehensive equivalency validation report |

## SQL Statement Conversion Summary

### Inline SQL Statements (from ProductRepository.cs)

| # | Method | Conversion Method | Equivalency Status |
|---|--------|-------------------|-------------------|
| 1 | GetAllProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 2 | GetProductByIdAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 3 | InsertProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 4 | UpdateProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 5 | DeleteProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 6 | GetProductsByPriceRangeAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 7 | GetLowStockProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |

### Statistics

- **Total inline SQL statements processed**: 7
- **Successfully converted by DMS tool**: 0
- **Manually converted (DMS failure)**: 7
- **Validated as EQUIVALENT**: 0
- **Validated as NOT_EQUIVALENT**: 0
- **Equivalency validation ERROR**: 7

### DMS Tool Failure Details

All 7 statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following parameters:
- `migration_project_identifier`: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- `database_name`: ProductManagement
- `schema_name`: dbo

All 7 statements failed with the same error:
```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after N attempts'}
```

Total DMS attempts: 8 (Statement 1 was attempted 3 times with different poll settings; Statements 2-7 attempted once each; plus 1 standalone test with a simple query).

### SQL Equivalency Tool Results

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with the error: `'uniqueID'`.

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR."

### Manual Conversion Details

Since DMS failed for all statements, manual conversion was applied following the rule: "Apply lowercase schema object names for PostgreSQL compatibility" with reason `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

Key conversions applied:
| SQL Server Construct | PostgreSQL Equivalent |
|---------------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING` clause + `currval(pg_get_serial_sequence())` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var` / `SET @var` | CTE-based approach |
| `BEGIN TRANSACTION` / `COMMIT` | Removed (managed at ADO.NET level) or `BEGIN` / `COMMIT` |
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `DATETIME` | `TIMESTAMP` |
| `GO` | Removed |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SYSTEM_USER` | `CURRENT_USER` |
| Table/column names | Converted to lowercase |

### Database Setup Script Conversions

Both SQL Server setup scripts were manually converted to PostgreSQL:
- **Scripts/01_InitialSetup.sql**: Simple version with CREATE TABLE, stored procedures → functions, INSERT sample data
- **Database/Scripts/01_InitialSetup.sql**: Comprehensive version including triggers, indexes, foreign keys, sample data

Key changes in setup scripts:
- Removed all `GO` batch separators
- Removed all `IF NOT EXISTS (SELECT * FROM sys.objects...)` patterns, replaced with `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS`
- Converted `IDENTITY(1,1)` to `SERIAL`
- Converted `NVARCHAR` to `VARCHAR`
- Converted `BIT` to `BOOLEAN`
- Converted `GETDATE()` to `CURRENT_TIMESTAMP`
- Converted `CREATE OR ALTER PROCEDURE` to `CREATE OR REPLACE FUNCTION ... RETURNS ... AS $$ ... $$ LANGUAGE plpgsql`
- Converted SQL Server triggers to PostgreSQL trigger functions + trigger definitions
- Converted `SYSTEM_USER` to `CURRENT_USER`
- Converted `SCOPE_IDENTITY()` to `RETURNING ... INTO` pattern

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## Package Dependency Changes

| Package | Action | Version |
|---------|--------|---------|
| Microsoft.Data.SqlClient | Removed | 5.1.4 |
| Npgsql | Added | 8.0.6 |

Note: Initially used Npgsql 8.0.0 per plan, upgraded to 8.0.6 to resolve known vulnerability (GHSA-x9vc-6hfv-hg8c).

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Build Status

**Build: SUCCESSFUL** (0 errors, 10 warnings - all nullable reference warnings pre-existing in original code)

## Detailed Equivalency Report

See `sql_equivalency_validation_report.json` in the project root for the complete equivalency validation report with all 7 statement pairs, including original statements, converted statements, conversion methods, equivalency status, and tool output.

## Recommendations

1. **Manual Review Required**: All 7 SQL statement pairs returned ERROR from the equivalency tool. Manual review is recommended to verify functional correctness.
2. **Integration Testing**: Execute comprehensive integration tests against a PostgreSQL database to verify all CRUD operations work correctly.
3. **Transaction Handling**: The converted statements removed explicit T-SQL transaction blocks. Verify that the ADO.NET level transaction management (via `BeginTransactionAsync`) provides equivalent behavior.
4. **Performance Testing**: Some conversions (e.g., CTE-based variable replacement for DECLARE/SET patterns) may have different performance characteristics. Benchmark critical operations.
5. **Schema Validation**: Verify that the PostgreSQL schema created by the setup scripts matches the expected structure.
