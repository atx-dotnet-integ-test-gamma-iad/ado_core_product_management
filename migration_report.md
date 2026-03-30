# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-30 |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **DMS Tool Conversion Successful** | 0 |
| **DMS Tool Conversion Failed** | 7 |
| **Manual Conversion Required** | 7 |
| **Equivalency Validated (EQUIVALENT)** | 0 |
| **Equivalency Validated (NOT_EQUIVALENT)** | 0 |
| **Equivalency Validation ERROR** | 7 |

## DMS Tool Status

The AWS DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 SQL statements. All attempts failed with metadata model conversion/creation timeouts:

- **Error**: "Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts"
- **Error**: "Metadata model creation failed: Metadata model creation did not complete after 15 attempts"

As a result, all 7 statements were manually converted with lowercase schema object names as specified in the transformation definition (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was invoked for all 7 statement pairs. All returned ERROR status:

- **Error**: `'uniqueID'` for all 7 pairs
- This appears to be a systemic tool issue, not specific to any statement

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Source**: CTE with ProductStats, AVG/COUNT OVER(), ROUND, CASE, INNER JOIN, ORDER BY CASE
- **Key Changes**: CTE renamed `productstats_cte` to avoid table name conflict, all identifiers lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR ('uniqueID')

### Statement 2: GetProductByIdAsync
- **Source**: CTE with LAG OVER(), parameterized @ProductId, LEFT JOIN, ROUND
- **Key Changes**: CTE renamed `producthistory_cte`, LAG window function preserved (compatible), lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR ('uniqueID')

### Statement 3: InsertProductAsync
- **Source**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**: SCOPE_IDENTITY() → RETURNING productid (PostgreSQL writeable CTE), GETDATE() → NOW(), transaction management moved to C# code level
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR ('uniqueID')

### Statement 4: UpdateProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history
- **Key Changes**: Restructured using PostgreSQL writeable CTEs, GETDATE() → NOW(), variable handling via CTE subqueries
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR ('uniqueID')

### Statement 5: DeleteProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, CASE
- **Key Changes**: Restructured using PostgreSQL writeable CTEs, GETDATE() → NOW(), CASE preserved (compatible)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR ('uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: CTE with RANK, PERCENT_RANK OVER(), BETWEEN, CASE
- **Key Changes**: Lowercase identifiers only, RANK/PERCENT_RANK window functions preserved (compatible)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR ('uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Source**: CTE with AVG, MIN, MAX OVER(), ROUND, CASE
- **Key Changes**: Lowercase identifiers, added CAST(stockquantity AS decimal) for integer division compatibility
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR ('uniqueID')

## Package Dependency Changes

| Change | Old | New |
|--------|-----|-----|
| Database Driver | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |
| Microsoft.Extensions.Configuration | 8.0.0 (unchanged) | 8.0.0 |
| Microsoft.Extensions.Configuration.Json | 8.0.0 (unchanged) | 8.0.0 |
| Microsoft.Extensions.DependencyInjection | 8.0.0 (unchanged) | 8.0.0 |

Note: Npgsql 8.0.1 (originally specified) had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to 8.0.6 to address the security concern.

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Replacements

| SQL Server Type | Npgsql Type | Occurrences |
|----------------|-------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, return type, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## SQL Syntax Conversions Applied

| SQL Server | PostgreSQL | Notes |
|-----------|-----------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | PostgreSQL writeable CTE pattern |
| `GETDATE()` | `NOW()` | Equivalent timestamp function |
| `IDENTITY(1,1)` | `SERIAL` | Auto-increment column |
| `nvarchar(n)` | `varchar(n)` | PostgreSQL uses varchar |
| `bit` | `boolean` | Boolean type |
| `SYSTEM_USER` | `current_user` | Current user function |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | PostgreSQL uses functions |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS` | PostgreSQL pattern |
| `GO` | Removed | Not needed in PostgreSQL |
| `SET NOCOUNT ON` | Removed | Not applicable in PostgreSQL |
| SQL Server triggers (`inserted`/`deleted` tables) | PostgreSQL trigger functions (`NEW`/`OLD` records) | Different trigger model |

## Files Modified

1. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements converted, ADO.NET classes replaced
2. **sourceCode/AdoCore.csproj** - Package reference updated
3. **sourceCode/appsettings.json** - Connection strings updated
4. **sourceCode/Scripts/01_InitialSetup.sql** - Converted to PostgreSQL syntax
5. **sourceCode/Database/Scripts/01_InitialSetup.sql** - Converted to PostgreSQL syntax

## Artifacts Generated

1. **sourceCode/extracted_statements.sql** - Catalog of all 7 original MS SQL statements
2. **sourceCode/converted_statements.sql** - Catalog of all 7 converted PostgreSQL statements
3. **sourceCode/sql_equivalency_validation_report.json** - Comprehensive equivalency validation report
4. **sourceCode/migration_report.md** - This report

## Build Status

**Final Build: SUCCESS** (0 errors, warnings are pre-existing nullable reference warnings)
