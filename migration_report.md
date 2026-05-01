# Migration Report: SQL Server to PostgreSQL

## 1. Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, replacing database driver packages and ADO.NET classes, and updating connection string configurations.

**Migration Date:** 2026-05-01  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

## 2. Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Package reference: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | SQL statements converted (7), ADO.NET classes replaced, import updated |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |
| `README.md` | Documentation updated to reflect PostgreSQL migration |

### New Artifacts Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL Server statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This migration report |

## 3. SQL Statement Migration Details

### Overview

| Metric | Value |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS | 0 |
| Requiring manual intervention | 7 |
| Equivalency validated as EQUIVALENT | 0 |
| Equivalency validated as NOT_EQUIVALENT | 0 |
| Equivalency validation ERROR | 7 |

### DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 statements. All attempts failed with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

As per the transformation rules, manual conversion was applied using lowercase schema object names for PostgreSQL compatibility (conversion_method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

### SQL Equivalency Tool Status

The SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence) was invoked for all 7 statement pairs. All returned an ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

All 7 statements are marked as `ERROR` in the equivalency report (status from tool, not agent judgment).

### Statement-by-Statement Details

| # | Source Method | Conversion Method | Equivalency Status | Key Changes |
|---|-------------|-------------------|-------------------|-------------|
| 1 | `GetAllProductsAsync()` | Manual (DMS Failed) | ERROR | Lowercase schema objects; CTE, window functions, CASE, ROUND compatible |
| 2 | `GetProductByIdAsync()` | Manual (DMS Failed) | ERROR | Lowercase schema objects; LAG window function, LEFT JOIN compatible |
| 3 | `InsertProductAsync()` | Manual (DMS Failed) | ERROR | `SCOPE_IDENTITY()` → `lastval()`; `GETDATE()` → `NOW()`; `BEGIN TRANSACTION` → `BEGIN` |
| 4 | `UpdateProductAsync()` | Manual (DMS Failed) | ERROR | `DECLARE @var` → subqueries; `GETDATE()` → `NOW()`; `BEGIN TRANSACTION` → `BEGIN` |
| 5 | `DeleteProductAsync()` | Manual (DMS Failed) | ERROR | `DECLARE @var` → subqueries; `GETDATE()` → `NOW()`; `BEGIN TRANSACTION` → `BEGIN` |
| 6 | `GetProductsByPriceRangeAsync()` | Manual (DMS Failed) | ERROR | Lowercase schema objects; RANK(), PERCENT_RANK(), BETWEEN compatible |
| 7 | `GetLowStockProductsAsync()` | Manual (DMS Failed) | ERROR | Lowercase schema objects; Added `CAST(stockquantity AS DECIMAL)` for integer division |

## 4. Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |
| `Microsoft.Extensions.Configuration 8.0.0` | `Microsoft.Extensions.Configuration 8.0.0` (unchanged) |
| `Microsoft.Extensions.Configuration.Json 8.0.0` | `Microsoft.Extensions.Configuration.Json 8.0.0` (unchanged) |
| `Microsoft.Extensions.DependencyInjection 8.0.0` | `Microsoft.Extensions.DependencyInjection 8.0.0` (unchanged) |

## 5. Class Replacements

| SQL Server Class | Npgsql Replacement | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 (field, method return type, new instance, connection param) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL statement method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## 6. Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Equivalent |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` (unchanged) |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Port=5432` (added) |

## 7. Known Issues / Manual Review Items

### Critical: All Equivalency Checks Returned ERROR
All 7 SQL statement pairs returned ERROR from the SQL Equivalency tool with error `'uniqueID'`. This appears to be a tool infrastructure issue rather than a statement-level problem. **Manual review of all 7 converted statements is recommended** to verify logical equivalence.

### DMS Tool Unavailable
The DMS conversion tool was unavailable during this migration (metadata model creation failure). All conversions were performed manually following the lowercase schema object naming convention for PostgreSQL.

### Statements Requiring Special Attention
- **Statement 3 (InsertProductAsync):** Uses `lastval()` to replace `SCOPE_IDENTITY()`. This relies on the most recent sequence value in the session, which should be the product ID from the preceding INSERT.
- **Statements 4 & 5 (UpdateProductAsync/DeleteProductAsync):** Original SQL used `DECLARE @var` pattern to capture old values before modification. Converted to use subqueries that read values before the UPDATE/DELETE within the same transaction, maintaining equivalent behavior.
- **Statement 7 (GetLowStockProductsAsync):** Added explicit `CAST(stockquantity AS DECIMAL)` to prevent integer division truncation, which could produce different results than SQL Server's implicit type promotion.

## 8. Build Status

The application compiles successfully after all changes:
- **Errors:** 0
- **Warnings:** 10 (all pre-existing nullable reference warnings, not related to migration)
- **Build output:** `AdoCore.dll` generated successfully
