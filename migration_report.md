# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET database access code, and modifying configuration to use PostgreSQL-compatible settings.

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS MCP Tool Results

All 7 SQL statements were passed through the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`). All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Tool Parameters Used:**
- `migration_project_identifier`: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- `database_name`: `ProductManagement`
- `schema_name`: `dbo`
- `region`: `us-east-1`

Since DMS failed for all statements, manual conversion was applied with lowercase schema object names per the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol.

## SQL Equivalency Validation Results

All 7 statement pairs were validated using the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR status with error `'uniqueID'`. The equivalency status for each statement comes exclusively from the tool output, not from agent judgment.

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs`, method `GetAllProductsAsync`
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND, ORDER BY with CASE
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema objects
- **Key Changes**: Table/column names lowercased (Products → products, ProductId → productid, etc.)
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 2: GetProductByIdAsync
- **Source File**: `DataAccess/ProductRepository.cs`, method `GetProductByIdAsync`
- **Type**: CTE with LAG window functions, LEFT JOIN, CASE with ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema objects
- **Key Changes**: Table/column names lowercased, LAG window functions preserved
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 3: InsertProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`, method `InsertProductAsync`
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT into ProductHistory, UPDATE ProductStats, GETDATE()
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema + functional conversions
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId` / `SET @NewProductId` → removed, using `lastval()` directly
  - `BEGIN TRANSACTION` / `COMMIT` → removed (transaction managed by C# code)
  - Added `SELECT lastval()` at end for `ExecuteScalarAsync()` return value
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 4: UpdateProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`, method `UpdateProductAsync`
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE Products with GETDATE(), INSERT into ProductHistory, UPDATE ProductStats
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema + structural conversions
- **Key Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → replaced with inline subqueries
  - `GETDATE()` → `NOW()`
  - Variable references replaced with `(SELECT ... FROM products WHERE productid = @ProductId)` subqueries
  - Reordered operations: INSERT history first (captures old values), then UPDATE stats, then UPDATE product
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 5: DeleteProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`, method `DeleteProductAsync`
- **Type**: Transaction block with DECLARE, SELECT into variables, INSERT into ProductHistory, DELETE, UPDATE ProductStats with CASE
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema + structural conversions
- **Key Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → replaced with inline subqueries
  - `GETDATE()` → `NOW()`
  - Reordered operations: INSERT history first (captures old values before delete), then UPDATE stats, then DELETE
  - CASE expression for AveragePrice calculation preserved
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: `DataAccess/ProductRepository.cs`, method `GetProductsByPriceRangeAsync`
- **Type**: CTE with RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema objects
- **Key Changes**: Table/column/alias names lowercased, RANK/PERCENT_RANK preserved (PostgreSQL compatible)
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs`, method `GetLowStockProductsAsync`
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema + type casting
- **Key Changes**:
  - Table/column/alias names lowercased
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND(CAST(stockquantity AS NUMERIC) / CAST(avgstock AS NUMERIC) * 100, 2)` (PostgreSQL integer division fix)
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

## All Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure on all statements
2. SQL Equivalency tool returning ERROR for all statements
3. Manual conversion applied with lowercase schema mapping rules

## File Changes Summary

### Modified Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL strings converted to PostgreSQL; `using Microsoft.Data.SqlClient` → `using Npgsql`; `SqlConnection` → `NpgsqlConnection`; `SqlCommand` → `NpgsqlCommand`; `SqlDataReader` → `NpgsqlDataReader` |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient` 5.1.4 → `Npgsql` 8.0.6 |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

### New Files
| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This migration report |

## Package Dependency Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

Other packages unchanged:
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

## Connection String Transformation

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server | PostgreSQL |
|-----------|-----------|
| `Server=localhost` | `Host=localhost` |
| (implicit) | `Port=5432` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | (removed - not applicable) |
| `TrustServerCertificate=True` | (removed - not applicable) |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `Microsoft.Data.SqlClient` (namespace) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## Build Status

**Final Build: SUCCESS** (0 errors, 10 pre-existing nullable reference warnings)

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

## Artifacts Checklist

- [x] `extracted_statements.sql` - Complete catalog of all 7 original SQL statements
- [x] `converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements
- [x] `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report with all 7 pairs
- [x] `migration_report.md` - This final migration report
- [x] All 7 SQL statements accounted for in all artifacts

## Notes and Recommendations

1. **DMS Tool Failure**: The DMS MCP tool consistently failed with metadata model creation errors. This may be a temporary infrastructure issue. It is recommended to re-run DMS conversion when the tool is operational to validate the manual conversions.

2. **SQL Equivalency Tool Errors**: The SQL Equivalency tool returned errors for all statements. The manual conversions should be validated against a live PostgreSQL database to ensure correctness.

3. **Transaction Management**: The original SQL embedded BEGIN TRANSACTION/COMMIT blocks within the SQL strings. These were removed in the PostgreSQL conversion since Npgsql handles transactions at the C# connection level via `BeginTransactionAsync()`, `CommitAsync()`, and `RollbackAsync()`.

4. **Variable Elimination**: SQL Server's DECLARE/SET variable pattern was replaced with inline subqueries in PostgreSQL. For the UpdateProductAsync and DeleteProductAsync methods, the operations were reordered to capture old values (via INSERT into history) before modifying the source data.

5. **Integer Division**: PostgreSQL performs integer division differently from SQL Server. CAST to NUMERIC was added where integer division could produce incorrect results (Statement 7: GetLowStockProductsAsync).

6. **Connection String Security**: The placeholder credentials (Username=postgres;Password=postgres) in appsettings.json should be replaced with environment-specific credentials and should use secure configuration providers in production.
