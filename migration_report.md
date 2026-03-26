# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore - .NET ADO.NET Application
- **Source Database**: Microsoft SQL Server (ProductManagement)
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-03-26

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Failure Details
All 7 statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following configuration:
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: `ProductManagement`
- **Schema**: `dbo`

All 7 conversions failed with metadata model creation/conversion timeout errors. Manual conversion was applied with lowercase schema object naming convention per the transformation rules (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

### SQL Equivalency Tool Details
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned `ERROR` with error: `'uniqueID'` (tool-level backend configuration issue). Per transformation rules, all are marked as `ERROR` — no agent judgment was used for equivalency determination.

---

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync
- **Source**: `DataAccess/ProductRepository.cs`, `GetAllProductsAsync()` method
- **Type**: SELECT with CTE, window functions (AVG, COUNT OVER), INNER JOIN, CASE, ROUND
- **DMS Status**: FAILED (Metadata model conversion timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Lowercased all table/column names. SQL syntax (CTE, window functions) already PostgreSQL-compatible.
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 2: GetProductByIdAsync
- **Source**: `DataAccess/ProductRepository.cs`, `GetProductByIdAsync()` method
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE, ROUND
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Lowercased all table/column names. LAG, ROUND, CASE syntax already PostgreSQL-compatible.
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 3: InsertProductAsync
- **Source**: `DataAccess/ProductRepository.cs`, `InsertProductAsync()` method
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), INSERT into ProductHistory, UPDATE ProductStats
- **DMS Status**: FAILED (Statement definition is not valid)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Removed `DECLARE @NewProductId INT` and `SET @NewProductId = SCOPE_IDENTITY()` pattern
  - Replaced `SCOPE_IDENTITY()` with `lastval()` (PostgreSQL equivalent)
  - Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
  - Replaced `BEGIN TRANSACTION` with `BEGIN`
  - Lowercased all table/column names
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 4: UpdateProductAsync
- **Source**: `DataAccess/ProductRepository.cs`, `UpdateProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, UPDATE stats
- **DMS Status**: FAILED (Metadata model conversion timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Replaced T-SQL DECLARE/variable pattern with subqueries for old values
  - Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
  - Replaced `BEGIN TRANSACTION` with `BEGIN`
  - Lowercased all table/column names
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 5: DeleteProductAsync
- **Source**: `DataAccess/ProductRepository.cs`, `DeleteProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Replaced T-SQL DECLARE/variable pattern with subqueries for old values
  - Reordered: log deletion and update stats before DELETE (to access values before they're removed)
  - Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
  - Replaced `BEGIN TRANSACTION` with `BEGIN`
  - Lowercased all table/column names
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `DataAccess/ProductRepository.cs`, `GetProductsByPriceRangeAsync()` method
- **Type**: SELECT with CTE, RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Lowercased all table/column names. RANK(), PERCENT_RANK(), BETWEEN, CASE syntax already PostgreSQL-compatible.
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Source**: `DataAccess/ProductRepository.cs`, `GetLowStockProductsAsync()` method
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Lowercased all table/column names. Added explicit `CAST(stockquantity AS DECIMAL)` to prevent integer division truncation in PostgreSQL. Window functions and CASE syntax already PostgreSQL-compatible.
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

---

## Static Code Changes Summary

### Package References (AdoCore.csproj)
| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

### C# Class Replacements (DataAccess/ProductRepository.cs)
| Original | Replacement | Occurrences |
|----------|-------------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### Connection String Changes (appsettings.json)
| Parameter | Original (SQL Server) | New (PostgreSQL) |
|-----------|----------------------|------------------|
| Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Removed | `MultipleActiveResultSets=true` | N/A |
| Removed | `TrustServerCertificate=True` | N/A |

### Files Not Changed (No DB References)
- `Models/Product.cs` - Data model only
- `Business/ProductService.cs` - Business logic only
- `CLI/CommandLineInterface.cs` - CLI interface only
- `CLI/InteractiveMenu.cs` - Interactive menu only
- `Program.cs` - Uses DI, no direct DB references
- `Scripts/01_InitialSetup.sql` - Reference script (not executed at runtime)
- `Database/Scripts/01_InitialSetup.sql` - Reference script (not executed at runtime)

---

## Transformation Artifacts

| Artifact | Status | Description |
|----------|--------|-------------|
| `extracted_statements.sql` | ✅ Complete | All 7 original MS SQL statements |
| `converted_statements.sql` | ✅ Complete | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | ✅ Complete | All 7 statement pairs with tool-based results |
| `dms_conversion_log.md` | ✅ Complete | All 7 DMS failures documented |
| `migration_report.md` | ✅ Complete | This report |

---

## Final Verification Checklist

- ✅ All `SqlConnection` → `NpgsqlConnection`
- ✅ All `SqlCommand` → `NpgsqlCommand`
- ✅ All `SqlDataReader` → `NpgsqlDataReader`
- ✅ `Microsoft.Data.SqlClient` → `Npgsql` in .csproj
- ✅ `using Microsoft.Data.SqlClient` → `using Npgsql`
- ✅ Connection strings updated to PostgreSQL format
- ✅ All 7 SQL statements converted (manual with lowercase schema due to DMS failures)
- ✅ All 7 SQL statement pairs validated through equivalency tool (all returned ERROR)
- ✅ Project compiles without errors (`dotnet build` succeeds with 0 errors)
- ✅ No MS SQL-specific syntax remains in SQL strings (SCOPE_IDENTITY, GETDATE, BEGIN TRANSACTION, DECLARE @)
- ✅ No `Microsoft.Data.SqlClient` references remain in application code
