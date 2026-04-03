# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Converted by DMS Tool** | 0 |
| **Manually Converted (DMS Failure)** | 7 |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Validated** | 7 (all ERROR due to tool issue) |
| **Equivalency Status** | 0 EQUIVALENT, 0 NOT_EQUIVALENT, 7 ERROR |
| **Build Status** | SUCCESS (0 errors) |

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 statements with the following configuration:
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1

**Result**: All 7 statements failed with identical error:
> "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"

Multiple retry attempts were made with different configurations (poll intervals of 10-15 seconds, max attempts of 15-30).

## SQL Equivalency Validation Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs.

**Result**: All 7 validations returned ERROR with `'uniqueID'` error. This appears to be a tool-side issue, not related to the quality of conversions.

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | All 7 SQL statements converted to PostgreSQL; code restructured for transaction handling |
| `AdoCore.csproj` | Modified | `Microsoft.Data.SqlClient` 5.1.4 → `Npgsql` 8.0.6 |
| `appsettings.json` | Modified | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax |
| `README.md` | Modified | Updated to reflect PostgreSQL usage |
| `extracted_statements.sql` | New | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | New | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | New | Comprehensive equivalency validation report |
| `dms_conversion_summary.md` | New | DMS failure documentation |
| `migration_report.md` | New | This report |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions
- **Key Changes**: Schema objects lowercased, ROUND syntax preserved (compatible)
- **C# Changes**: SQL string replacement only

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window functions
- **Key Changes**: Schema objects lowercased, LAG preserved (compatible)
- **C# Changes**: SQL string replacement only

### Statement 3: InsertProductAsync
- **Type**: Transaction block with SCOPE_IDENTITY/GETDATE
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @var` → Removed (C# variable handling)
  - `BEGIN TRANSACTION/COMMIT` → C#-managed `NpgsqlTransaction`
- **C# Changes**: Restructured from single SQL command to 3 separate commands within a C#-managed transaction

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE/GETDATE
- **Key Changes**:
  - `DECLARE @var / SELECT @var = col` → Separate SELECT + C# DataReader
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → C#-managed `NpgsqlTransaction`
- **C# Changes**: Restructured from single SQL command to 4 separate commands within a C#-managed transaction

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE/GETDATE/CASE
- **Key Changes**:
  - `DECLARE @var / SELECT @var = col` → Separate SELECT + C# DataReader
  - `GETDATE()` → `NOW()`
  - `CASE` expression → Preserved (compatible)
  - `BEGIN TRANSACTION/COMMIT` → C#-managed `NpgsqlTransaction`
- **C# Changes**: Restructured from single SQL command to 4 separate commands within a C#-managed transaction

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK/PERCENT_RANK
- **Key Changes**: Schema objects lowercased, window functions preserved (compatible)
- **C# Changes**: SQL string replacement only

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions
- **Key Changes**: Schema objects lowercased, added `CAST(stockquantity AS numeric)` for integer division fix
- **C# Changes**: SQL string replacement only

## Package Dependency Changes

| Package | Before | After |
|---------|--------|-------|
| Microsoft.Data.SqlClient | 5.1.4 | Removed |
| Npgsql | N/A | 8.0.6 |
| Microsoft.Extensions.Configuration | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.Configuration.Json | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.DependencyInjection | 8.0.0 | 8.0.0 (unchanged) |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (not applicable) |
| TrustServerCertificate | `True` | Removed (not applicable) |

## ADO.NET Type Replacements

| SQL Server Type | PostgreSQL (Npgsql) Type |
|-----------------|--------------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlTransaction | NpgsqlTransaction |
| Microsoft.Data.SqlClient (namespace) | Npgsql (namespace) |

## SQL Script Conversions (Database/Scripts/01_InitialSetup.sql)

| SQL Server Feature | PostgreSQL Equivalent |
|-------------------|----------------------|
| `IDENTITY(1,1)` | `serial` |
| `nvarchar(n)` | `varchar(n)` |
| `datetime` | `timestamp` |
| `bit` | `boolean` |
| `GETDATE()` | `NOW()` |
| `GO` | Removed (not needed) |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` |
| `IF NOT EXISTS (SELECT * FROM sys.databases...)` | Database created externally |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `CREATE TRIGGER ... AS BEGIN ... END` | `CREATE FUNCTION + CREATE TRIGGER` |
| `SYSTEM_USER` | `current_user` |
| `SET NOCOUNT ON` | Not needed (PostgreSQL default behavior) |
| `SCOPE_IDENTITY()` | `RETURNING` clause |

## Issues and Manual Interventions

1. **DMS Tool Failure**: All 7 statements failed DMS conversion. Root cause: metadata model creation timeout. All statements were manually converted.

2. **SQL Equivalency Tool Error**: All 7 statement pairs returned ERROR ('uniqueID'). This is a tool-side issue, not a conversion quality issue.

3. **Transaction Block Restructuring**: SQL Server allows DECLARE variables within transaction blocks sent as a single SQL command. PostgreSQL does not support this pattern in regular SQL (only in PL/pgSQL). The solution was to restructure into multiple separate SQL commands managed by C#-level NpgsqlTransaction.

4. **Integer Division**: PostgreSQL performs integer division when both operands are integers (e.g., `5/2 = 2`), while SQL Server implicitly converts. Added explicit `CAST(col AS numeric)` where needed.

5. **Column Name Case Sensitivity**: PostgreSQL lowercases unquoted identifiers. To maintain compatibility with the C# DataReader column access (which uses PascalCase names), added explicit column aliases with quoted identifiers (e.g., `AS "ProductId"`).
