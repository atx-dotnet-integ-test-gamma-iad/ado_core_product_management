# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| Migration Date | 2026-05-06 |
| Source Database | Microsoft SQL Server 2019 (ProductManagement) |
| Target Database | PostgreSQL 13 (postgres) |
| Application Framework | .NET 9.0, ADO.NET |
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS Tool | 0 |
| Requiring Manual Intervention | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS Tool Status

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All failed with the same systemic error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

This was a DMS infrastructure issue, not related to the SQL statements themselves. All statements were manually converted following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach as specified in the transformation definition.

## SQL Equivalency Tool Status

All 7 statement pairs were validated through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR with:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This was a systemic tool infrastructure issue. Per the transformation definition, all statements are marked with equivalency_status = "ERROR".

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; SqlClient types replaced with Npgsql types; Transaction handling restructured |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` replaced with `Npgsql 8.0.0` |
| `appsettings.json` | SQL Server connection strings replaced with PostgreSQL format |

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.0 |

Other packages remain unchanged:
- `Microsoft.Extensions.Configuration` v8.0.0
- `Microsoft.Extensions.Configuration.Json` v8.0.0
- `Microsoft.Extensions.DependencyInjection` v8.0.0

## Connection String Changes

| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (N/A) |
| TrustServerCertificate | `True` | Removed (N/A) |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE and Window Functions (AVG OVER, COUNT OVER, CASE, ROUND)
- **Conversion:** Direct lowercase schema mapping. CTE and window functions are compatible between SQL Server and PostgreSQL.
- **Key Changes:** All table/column names lowercased

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG Window Function, Parameterized Query
- **Conversion:** Direct lowercase schema mapping. LAG() window function syntax is identical in PostgreSQL.
- **Key Changes:** All table/column names lowercased

### Statement 3: InsertProductAsync
- **Type:** Transaction block with SCOPE_IDENTITY(), GETDATE(), multiple INSERT/UPDATE
- **Conversion:** Major restructuring required
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - `DECLARE @variable` pattern removed; transaction managed at application level
  - Single multi-statement batch split into individual commands with explicit transaction

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT INTO variables, UPDATE
- **Conversion:** Major restructuring required
- **Key Changes:**
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → Separate SELECT query with results stored in C# variables
  - `GETDATE()` → `NOW()`
  - Transaction managed at application level with explicit begin/commit/rollback

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE variables, DELETE, UPDATE with CASE
- **Conversion:** Major restructuring required
- **Key Changes:**
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → Separate SELECT query with results stored in C# variables
  - `GETDATE()` → `NOW()`
  - CASE expression in UPDATE preserved (compatible)
  - Transaction managed at application level

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN
- **Conversion:** Direct lowercase schema mapping. RANK() and PERCENT_RANK() are identical in PostgreSQL.
- **Key Changes:** All table/column names lowercased

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion:** Mostly direct mapping with one critical fix
- **Key Changes:**
  - All table/column names lowercased
  - Added `CAST(stockquantity AS DECIMAL)` to prevent integer division (PostgreSQL performs integer division for int/int)

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL Equivalent |
|-----------------|---------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL Server statements |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report |
| `migration_report.md` | Project root | This report |

## Build Status

Final build: **SUCCESS** (0 errors, 12 warnings - all nullable reference type warnings pre-existing in the codebase)

## Notes and Recommendations

1. **DMS Tool:** The DMS tool was unavailable due to infrastructure issues. All conversions were performed manually with lowercase schema naming convention. When DMS becomes available, statements should be re-validated.

2. **SQL Equivalency:** The equivalency tool was unavailable due to infrastructure issues. Manual review of all conversions confirms logical equivalency. When the tool becomes available, statements should be re-validated.

3. **Integer Division:** PostgreSQL performs integer division when both operands are integers. The `StockQuantity / AvgStock` calculation in Statement 7 was wrapped with `CAST(stockquantity AS DECIMAL)` to ensure correct decimal division.

4. **Transaction Handling:** SQL Server supports multi-statement batches with DECLARE/SET in a single command. PostgreSQL with Npgsql requires individual commands within a transaction. The transactional methods (Insert, Update, Delete) were restructured to use explicit `BeginTransactionAsync()`/`CommitAsync()`/`RollbackAsync()` patterns.

5. **Parameter Syntax:** Npgsql supports `@ParameterName` syntax (same as SqlClient), so no parameter syntax changes were needed.

6. **Column Name Case:** PostgreSQL column names are case-insensitive by default (stored in lowercase), so the `MapProductFromReader` method was updated to use lowercase column names in the indexer.
