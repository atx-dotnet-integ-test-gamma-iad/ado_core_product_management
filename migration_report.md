# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET database access code, replacing package dependencies, and converting SQL script files.

## Migration Overview

| Metric | Value |
|--------|-------|
| Total SQL Statements from Code | 7 |
| DMS Tool Conversion Attempts | 7 |
| DMS Tool Successful Conversions | 0 |
| Manual Conversions (DMS Failure) | 7 |
| Equivalency Validations Attempted | 7 |
| Equivalency Status: EQUIVALENT | 0 |
| Equivalency Status: NOT_EQUIVALENT | 0 |
| Equivalency Status: ERROR | 7 |

## DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) with the following parameters:
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: `ProductManagement`
- **Schema**: `dbo`

**DMS Error**: All conversions failed with: `"Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"`

As per the transformation rules, all statements were manually converted applying lowercase schema naming convention, documented with reason `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Validation Status

All 7 statement pairs were submitted to the SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`).

**Equivalency Tool Error**: All validations returned ERROR with: `"'uniqueID'"` (service-side issue).

Per the transformation rules, all statement pairs are marked as ERROR. No agent judgment was used to determine equivalency.

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetAllProductsAsync()`
- **Type**: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- **Key Changes**: Lowercase schema objects
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductByIdAsync()`
- **Type**: CTE with LAG window functions, LEFT JOIN, CASE with NULL handling
- **Key Changes**: Lowercase schema objects
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `InsertProductAsync()`
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**: SCOPE_IDENTITY() → RETURNING; GETDATE() → NOW(); Transaction restructured to C# managed transaction with multiple commands
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `UpdateProductAsync()`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Key Changes**: DECLARE/SET → C# variables with separate SELECT; GETDATE() → NOW(); Transaction restructured to C# managed transaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `DeleteProductAsync()`
- **Type**: Transaction block with DECLARE, SELECT, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Key Changes**: DECLARE/SET → C# variables with separate SELECT; GETDATE() → NOW(); Transaction restructured to C# managed transaction
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductsByPriceRangeAsync()`
- **Type**: CTE with RANK/PERCENT_RANK window functions, CASE, BETWEEN
- **Key Changes**: Lowercase schema objects
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetLowStockProductsAsync()`
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: Lowercase schema objects; CAST for integer division in ROUND
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all SQL statements, updated ADO.NET classes (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader), updated using directive |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (stored procedures→functions, types, defaults) |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (tables, triggers, functions, indexes, sample data) |

## Key Conversion Patterns Applied

| SQL Server | PostgreSQL |
|------------|-----------|
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `DECLARE @var; SET @var = ...` | C# managed variables with separate SELECT |
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `DATETIME` | `TIMESTAMP` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `Server=` | `Host=` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SYSTEM_USER` | `current_user` |
| `GO` (batch separator) | Removed (not needed in PostgreSQL) |
| `sys.databases/sys.objects` checks | `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS` |
| SQL Server trigger syntax | PostgreSQL trigger function + trigger pattern |

## Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report with all 7 statement pairs |
| `migration_report.md` | This migration report |

## Build Status

The application compiles successfully after all migration changes:
- **0 errors**
- **10 warnings** (all pre-existing nullable reference warnings, not introduced by migration)
- **No vulnerable packages** (Npgsql 8.0.6 has no known vulnerabilities)

## Notes and Recommendations

1. **DMS Tool Failure**: The DMS MCP tool was unavailable during this migration due to metadata model creation failures. All conversions were done manually. It is recommended to re-validate converted statements through DMS when the service becomes available.

2. **SQL Equivalency Tool Failure**: The SQL Equivalency tool was unavailable due to service-side errors. Manual review of converted statements is recommended to ensure functional equivalency.

3. **Transaction Handling**: Transaction blocks that used T-SQL DECLARE/SET patterns were restructured to use C# managed transactions with separate Npgsql commands. This is the standard pattern for PostgreSQL with Npgsql.

4. **Schema Object Casing**: All schema object names (tables, columns, indexes, constraints) have been converted to lowercase for PostgreSQL compatibility, as PostgreSQL folds unquoted identifiers to lowercase.

5. **Connection Strings**: Connection strings use placeholder credentials (postgres/postgres). These should be updated with proper credentials in production environments, preferably using environment variables or a secrets manager.
