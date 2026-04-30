# Migration Report: Microsoft SQL Server to PostgreSQL

## Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET database access code, changing package references, and converting database scripts.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (ProductRepository.cs) | 7 |
| SQL statements successfully converted by DMS | 0 |
| SQL statements requiring manual intervention | 7 |
| SQL equivalency validations performed | 7 |
| SQL equivalency results: EQUIVALENT | 0 |
| SQL equivalency results: NOT_EQUIVALENT | 0 |
| SQL equivalency results: ERROR | 7 |
| Database scripts converted | 2 |
| Source files modified | 4 |

## DMS Tool Status

The DMS MCP tool (statement_conversion_tool) was used for all 7 SQL statement conversions and 1 DDL conversion attempt. **All attempts failed** with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Parameters Used:**
- Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`

Since DMS failed for all statements, manual conversion was applied with lowercase schema object names as specified in the transformation rules (conversion method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Validation Status

The SQL Equivalency tool (validate_sql_equivalence) was used for all 7 statement pairs. **All validations returned ERROR** with the following error:

```
{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
```

The equivalency status is recorded as ERROR for all 7 statements in the `sql_equivalency_validation_report.json` file.

## SQL Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG, COUNT OVER), CASE, ROUND, INNER JOIN
- **Key Conversions**: Lowercase schema objects
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, CASE with ROUND
- **Key Conversions**: Lowercase schema objects, parameter @ProductId preserved
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY, GETDATE
- **Key Conversions**: 
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @NewProductId INT` → removed (using `lastval()` directly)
  - Lowercase schema objects
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, UPDATE, INSERT, GETDATE
- **Key Conversions**:
  - `DECLARE @OldPrice/@OldStock` → `SELECT INTO TEMP temp_old_values`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Lowercase schema objects
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, DELETE, CASE, GETDATE
- **Key Conversions**:
  - `DECLARE @OldPrice/@OldStock` → `SELECT INTO TEMP temp_old_values`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - CASE expression preserved
  - Lowercase schema objects
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
- **Key Conversions**: Lowercase schema objects (window functions compatible)
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Conversions**: `CAST(stockquantity AS DECIMAL)` for integer division, lowercase schema objects
- **DMS Status**: Failed
- **Equivalency**: ERROR

## Files Modified

### Source Code Files

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced `using Microsoft.Data.SqlClient` with `using Npgsql`; replaced `SqlConnection`/`SqlCommand`/`SqlDataReader` with `NpgsqlConnection`/`NpgsqlCommand`/`NpgsqlDataReader` |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.3` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

### Database Script Files

| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |

## Package Dependency Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.3 |

*Unchanged packages:*
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | N/A | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (not applicable) |
| TrustServerCertificate | `True` | Removed (not applicable) |

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class |
|-----------------|--------------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## Database Script Conversions

### Key Syntax Conversions Applied

| SQL Server Syntax | PostgreSQL Syntax |
|-------------------|-------------------|
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `[nvarchar](n)` | `varchar(n)` |
| `[datetime]` | `timestamp` |
| `[bit]` | `boolean` |
| `GETDATE()` | `NOW()` |
| `GO` | Removed |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SCOPE_IDENTITY()` | `RETURNING ... INTO` |
| `SYSTEM_USER` | `current_user` |
| `AFTER INSERT, UPDATE, DELETE` trigger | `AFTER INSERT OR UPDATE OR DELETE` with trigger function |
| Square bracket identifiers `[name]` | Unquoted identifiers |

## Build Status

- **Final build**: SUCCESS (0 errors, 10 warnings)
- **Warnings**: All pre-existing nullable reference warnings (CS8601, CS8618, CS8603, CS8600, CS8625) - not introduced by migration

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL statements |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report |
| `migration_report.md` | Project root | This migration report |

## Issues Encountered

1. **DMS Tool Failure**: The DMS MCP statement_conversion_tool failed for all conversion attempts with "Metadata model creation failed" error. All conversions were performed manually following the lowercase schema naming convention.

2. **SQL Equivalency Tool Error**: The SQL equivalency validation tool returned ERROR with `'uniqueID'` for all 7 statement pairs. This appears to be a tool configuration issue rather than a statement equivalency problem.

## Recommendations

1. **Manual Verification**: Since both the DMS conversion tool and SQL equivalency tool experienced errors, manual testing of all 7 SQL statements against a PostgreSQL database is strongly recommended.
2. **Integration Testing**: Run the full application against a PostgreSQL database to verify all CRUD operations work correctly.
3. **Performance Testing**: Compare query execution plans between the original SQL Server queries and converted PostgreSQL queries to ensure performance is acceptable.
4. **Connection String Security**: Update the placeholder credentials in `appsettings.json` with actual secure credentials before deployment.
