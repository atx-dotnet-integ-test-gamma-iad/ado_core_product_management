# Migration Report: SQL Server to PostgreSQL

## Project Overview

| Property | Value |
|---|---|
| **Application** | AdoCore |
| **Framework** | .NET 9.0 |
| **Database Access** | ADO.NET (direct SQL) |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Migration Date** | 2026-04-08 |
| **DMS Migration Project** | arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4 |

---

## Executive Summary

The AdoCore .NET 9.0 application has been migrated from Microsoft SQL Server to PostgreSQL. The migration involved converting 7 SQL statements, replacing the SQL Server ADO.NET driver (Microsoft.Data.SqlClient) with the PostgreSQL driver (Npgsql), and updating connection strings. The application compiles successfully after migration.

---

## SQL Statement Conversion Summary

| Metric | Count |
|---|---|
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS Tool** | 0 |
| **Statements Requiring Manual Conversion** | 7 |
| **Equivalency Validated as EQUIVALENT** | 0 |
| **Equivalency Validated as NOT_EQUIVALENT** | 0 |
| **Equivalency Validation ERROR** | 7 |

### DMS Tool Status
- **DMS Statement Conversion Tool**: UNAVAILABLE
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Impact**: All 7 statements were manually converted using DMS schema mappings (obtained successfully) with lowercase schema object names
- **Manual Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
- **SQL Equivalency Tool**: UNAVAILABLE (service-side error)
- **Error**: `'uniqueID'` error returned for all 7 statement pairs
- **Impact**: All 7 statement pairs marked as ERROR per transformation rules
- **Note**: Tool was called for every statement pair as required; errors are service-side

### DMS Schema Mapping (Successfully Retrieved)
The DMS schema mapping tool was successfully used to obtain the target PostgreSQL schema:

| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |
| All column names (PascalCase) | All column names (lowercase) |

---

## Detailed Per-Statement Breakdown

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE alias renamed from `ProductStats` to `productstats_cte` to avoid conflict with the `productstats` table; all identifiers lowercased
- **Equivalency Status**: ERROR (tool service-side issue)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, ROUND, CASE, parameterized (@ProductId)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE alias renamed from `ProductHistory` to `producthistory_cte` to avoid conflict with the `producthistory` table; all identifiers lowercased
- **Equivalency Status**: ERROR (tool service-side issue)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), INSERT into ProductHistory, UPDATE ProductStats
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - Monolithic SQL block refactored into 3 separate Npgsql commands within a transaction
  - `DECLARE @NewProductId INT` → C# variable with RETURNING clause
- **Equivalency Status**: ERROR (tool service-side issue)

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → C# variables via separate SELECT query
  - `GETDATE()` → `NOW()`
  - Monolithic SQL block refactored into 4 separate Npgsql commands within a transaction
- **Equivalency Status**: ERROR (tool service-side issue)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → C# variables via separate SELECT query
  - `GETDATE()` → `NOW()`
  - Monolithic SQL block refactored into 4 separate Npgsql commands within a transaction
  - CASE expression in UPDATE preserved (PostgreSQL compatible)
- **Equivalency Status**: ERROR (tool service-side issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All identifiers lowercased; window functions are PostgreSQL-compatible
- **Equivalency Status**: ERROR (tool service-side issue)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER() Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All identifiers lowercased; added `CAST(stockquantity AS NUMERIC)` for integer division fix in PostgreSQL
- **Equivalency Status**: ERROR (tool service-side issue)

---

## Package Dependency Changes

| Before | After |
|---|---|
| `Microsoft.Data.SqlClient` Version `5.1.4` | `Npgsql` Version `8.0.1` |

Other packages unchanged:
- `Microsoft.Extensions.Configuration` Version `8.0.0`
- `Microsoft.Extensions.Configuration.Json` Version `8.0.0`
- `Microsoft.Extensions.DependencyInjection` Version `8.0.0`

---

## ADO.NET Class Replacements

| SQL Server (Before) | PostgreSQL/Npgsql (After) |
|---|---|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` (via cast) | `NpgsqlTransaction` (native) |

---

## Connection String Changes

### Development Connection
| Before | After |
|---|---|
| `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres` |

### Production Connection
| Before | After |
|---|---|
| `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres` |

### Connection String Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---|---|
| `Server=` | `Host=` |
| `Database=` | `Database=` (unchanged) |
| `Trusted_Connection=True` | Removed (use `Username`/`Password` instead) |
| `MultipleActiveResultSets=true` | Removed (not applicable to PostgreSQL) |
| `TrustServerCertificate=True` | Removed (use `SSL Mode=` if needed) |
| N/A | `Port=5432` (added) |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

---

## Files Modified

| File | Changes |
|---|---|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET types replaced, transaction logic refactored |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient to Npgsql |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

## Artifacts Generated

| File | Description |
|---|---|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 7 statement pairs |
| `migration_report.md` | This comprehensive migration summary |

---

## Build Verification

| Step | Build Status | Errors | Warnings |
|---|---|---|---|
| Step 1: SQL Statement Conversion | ✅ SUCCESS | 0 | ~10 (pre-existing nullable warnings) |
| Step 2: Package & Type Replacement | ✅ SUCCESS | 0 | 12 (pre-existing nullable warnings) |
| Step 3: Connection String Update | ✅ SUCCESS | 0 | 12 (pre-existing nullable warnings) |
| Step 4: Final Verification | ✅ SUCCESS | 0 | 12 (pre-existing nullable warnings) |

---

## Issues and Warnings

### DMS Statement Conversion Tool Failure
- **Severity**: High
- **Description**: The DMS MCP statement conversion tool consistently failed with "Metadata model creation failed: Unknown metadata model creation status: RECEIVED" for all 7 statements
- **Mitigation**: Used DMS schema mapping tool (which worked successfully) to obtain target schema names, then manually converted all statements using lowercase schema object naming convention
- **Impact**: All conversions were manual; recommend re-running DMS conversion when tool is available

### SQL Equivalency Tool Failure
- **Severity**: Medium
- **Description**: The SQL Equivalency MCP tool returned ERROR with `'uniqueID'` for all 7 statement pairs
- **Mitigation**: All pairs marked as ERROR per transformation rules; no agent judgment used for equivalency
- **Impact**: Equivalency could not be automatically validated; recommend manual review of all converted statements

### Integer Division in PostgreSQL
- **Severity**: Low
- **Description**: Statement 7 (GetLowStockProductsAsync) contains `StockQuantity / AvgStock` which in PostgreSQL would perform integer division
- **Mitigation**: Added `CAST(stockquantity AS NUMERIC)` to ensure decimal division matching SQL Server behavior

### CTE Name Conflicts
- **Severity**: Low
- **Description**: Original CTE names `ProductStats` and `ProductHistory` conflict with actual table names `productstats` and `producthistory` in PostgreSQL (case-insensitive)
- **Mitigation**: Renamed CTEs to `productstats_cte` and `producthistory_cte`

---

## Recommendations

1. **Re-run DMS Statement Conversion** when the DMS tool is operational to validate manual conversions
2. **Re-run SQL Equivalency Validation** when the equivalency tool is operational to confirm statement equivalence
3. **Test with PostgreSQL Database** to verify all queries execute correctly against actual PostgreSQL schema
4. **Review Transaction Behavior** - the refactored transaction methods (Insert, Update, Delete) use Npgsql transaction management instead of SQL-embedded transactions
5. **Update Production Credentials** - replace placeholder `postgres`/`postgres` credentials with secure production values using environment variables or a secrets manager
