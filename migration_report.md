# Migration Report: MS SQL Server to PostgreSQL

## Executive Summary
This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET database access classes, updating connection strings, and converting database setup scripts.

## Migration Statistics

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS | 0 |
| Statements Requiring Manual Intervention | 7 |
| Manual Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Validations Performed | 7 |
| Equivalent Statements | 0 |
| Non-Equivalent Statements | 0 |
| Equivalency Errors | 7 |

## DMS Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Status**: All 7 conversion attempts failed
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback**: Manual conversion with lowercase schema object names applied per transformation rules

## SQL Equivalency Validation Status
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Status**: All 7 validations returned ERROR
- **Error**: `'uniqueID'`
- **Note**: Errors are tool-side; all equivalency statuses recorded as ERROR per transformation rules (no agent judgment used)

## Files Modified

### Source Code Changes
| File | Change Description |
|------|-------------------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL, ADO.NET classes replaced |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings converted to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

### New Files Created
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_failure_summary.md` | DMS failure documentation |
| `migration_report.md` | This report |

## Detailed SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- **Changes**: Schema objects lowercased (Products→products, ProductId→productid, etc.)
- **PostgreSQL Compatibility**: Fully compatible (window functions, CTEs, ROUND all supported)

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, CASE, ROUND
- **Changes**: Schema objects lowercased
- **PostgreSQL Compatibility**: Fully compatible (LAG function supported)

### Statement 3: InsertProductAsync
- **Type**: Transaction with INSERT, SCOPE_IDENTITY(), history logging, stats update
- **Changes**:
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid` + `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → C# `BeginTransactionAsync()/CommitAsync()`
  - `DECLARE @var` → C# variables
  - Single monolithic SQL split into separate commands with transaction management in C#

### Statement 4: UpdateProductAsync
- **Type**: Transaction with DECLARE, SELECT into vars, UPDATE, history logging, stats update
- **Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice/@OldStock` → C# variables fetched via SELECT
  - Transaction management moved to C# layer
  - Schema objects lowercased

### Statement 5: DeleteProductAsync
- **Type**: Transaction with DECLARE, SELECT into vars, history logging, DELETE, stats update with CASE
- **Changes**:
  - Same patterns as Statement 4
  - `GETDATE()` → `NOW()`
  - Transaction management moved to C# layer

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **Changes**: Schema objects lowercased
- **PostgreSQL Compatibility**: Fully compatible

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Changes**: Schema objects lowercased, added `CAST(stockquantity AS NUMERIC)` for integer division
- **PostgreSQL Compatibility**: Required CAST for correct numeric division behavior

## Dependency Changes

### Package References
| Package | Before | After |
|---------|--------|-------|
| Microsoft.Data.SqlClient | 5.1.4 | Removed |
| Npgsql | N/A | 8.0.6 |
| Microsoft.Extensions.Configuration | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.Configuration.Json | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.DependencyInjection | 8.0.0 | 8.0.0 (unchanged) |

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL Equivalent |
|-----------------|---------------------|
| `Microsoft.Data.SqlClient` (namespace) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameters Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=` | `Host=` |
| `Database=` | `Database=` (unchanged) |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Port=5432` (added) |

## Database Script Changes

### Scripts/01_InitialSetup.sql
- `IF NOT EXISTS (SELECT * FROM sys.databases...)` → PostgreSQL comment (handle separately)
- `USE ProductManagement; GO` → Removed (connect to database directly)
- `IDENTITY(1,1)` → `SERIAL`
- `[dbo].[Products]` → `products` (lowercase, no brackets)
- `nvarchar` → `varchar`
- `datetime` → `timestamp`
- `GETDATE()` → `NOW()`
- `GO` batch separators → Removed
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- `SET NOCOUNT ON` → Removed
- `SCOPE_IDENTITY()` → `RETURNING ... INTO`

### Database/Scripts/01_InitialSetup.sql
- Same conversions as above, plus:
- `[bit]` → `boolean`
- `DEFAULT 1` (for bit) → `DEFAULT TRUE`
- `DEFAULT 0` (for bit) → `DEFAULT FALSE`
- `SYSTEM_USER` → `current_user`
- SQL Server trigger syntax → PostgreSQL trigger function + CREATE TRIGGER
- All indexes converted (same syntax, lowercase names)

## Build Status
- **Final Build**: ✅ Success (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **No vulnerability warnings** (Npgsql 8.0.6 resolves GHSA-x9vc-6hfv-hg8c)

## Artifacts
1. `extracted_statements.sql` - Complete catalog of original MS SQL statements
2. `converted_statements.sql` - Complete catalog of converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report with all 7 pairs
4. `dms_failure_summary.md` - Documentation of DMS tool failures and manual conversions
5. `migration_report.md` - This comprehensive migration report
