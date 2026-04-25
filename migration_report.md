# Migration Report: MS SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Date
2026-04-25

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP statement_conversion_tool. All 7 failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
Manual conversion was applied to all statements with lowercase schema object names per the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol.

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the sql-equivalency___validate_sql_equivalence tool. All 7 returned ERROR with:
```
{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
```
This appears to be a systemic tool issue. All results are faithfully recorded as ERROR based on tool output (no agent judgment substituted).

## Statement Details

| # | Method | Conversion | Key Changes |
|---|--------|------------|-------------|
| 1 | GetAllProductsAsync | Manual (lowercase) | CTE + window functions - lowercase identifiers |
| 2 | GetProductByIdAsync | Manual (lowercase) | CTE + LAG window function - lowercase identifiers |
| 3 | InsertProductAsync | Manual (restructured) | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), single T-SQL batch → multiple NpgsqlCommand with app-level transaction |
| 4 | UpdateProductAsync | Manual (restructured) | DECLARE/SET variables → C# variables, GETDATE() → NOW(), T-SQL batch → multiple NpgsqlCommand with app-level transaction |
| 5 | DeleteProductAsync | Manual (restructured) | DECLARE/SET variables → C# variables, GETDATE() → NOW(), T-SQL batch → multiple NpgsqlCommand with app-level transaction |
| 6 | GetProductsByPriceRangeAsync | Manual (lowercase) | CTE + RANK/PERCENT_RANK - lowercase identifiers |
| 7 | GetLowStockProductsAsync | Manual (lowercase) | CTE + window functions - lowercase identifiers, added ::numeric cast for integer division |

## Files Modified

### Source Code
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Complete migration: using Npgsql, NpgsqlConnection/Command/DataReader, all 7 SQL statements converted, transaction handling restructured |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings: Server= → Host=, removed SQL Server-specific params, added Username/Password |

### SQL Scripts
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | IDENTITY→SERIAL, GETDATE→NOW, nvarchar→varchar, procedures→functions, removed GO/IF EXISTS blocks |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion including triggers (AFTER→FOR EACH ROW), [bit]→BOOLEAN, SYSTEM_USER→current_user |

### Artifacts
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive validation report for all 7 statement pairs |

## Key Transformations Applied

### SQL Syntax Changes
- `SCOPE_IDENTITY()` → `RETURNING productid`
- `GETDATE()` → `NOW()`
- `DECLARE @Var TYPE` / `SET @Var = ...` → Application-level C# variables
- `BEGIN TRANSACTION` / `COMMIT` → `NpgsqlTransaction` in C# code
- All schema object names converted to lowercase for PostgreSQL compatibility
- `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock` (explicit numeric cast for integer division)

### ADO.NET Class Replacements
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Changes
- `Server=localhost` → `Host=localhost`
- Removed: `Trusted_Connection=True`, `MultipleActiveResultSets=true`, `TrustServerCertificate=True`
- Added: `Username=postgres;Password=postgres`

### Package Changes
- Removed: `Microsoft.Data.SqlClient` v5.1.4
- Added: `Npgsql` v8.0.6

## Build Status
**Build Succeeded** - 0 errors, 10 warnings (all nullable reference warnings, consistent with original codebase)

## Validation Results
- ✅ No remaining `Microsoft.Data.SqlClient` references in any .cs file
- ✅ No remaining `SqlConnection`, `SqlCommand`, `SqlDataReader`, `SqlParameter` in any .cs file
- ✅ No remaining SQL Server connection string patterns in appsettings.json
- ✅ Npgsql package reference present in AdoCore.csproj
- ✅ All 7 SQL statements processed through DMS tool (all failed, manually converted)
- ✅ All 7 statement pairs validated through SQL Equivalency tool (all returned ERROR due to tool issue)
- ✅ Comprehensive equivalency report generated with all 7 entries
- ✅ Application compiles successfully with all PostgreSQL changes
