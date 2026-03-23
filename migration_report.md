# Migration Report: MS SQL Server to PostgreSQL

## Project Overview
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-03-23
- **Migration Method**: DMS MCP tool (with manual fallback due to AccessDeniedException)

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS Tool** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent (by tool)** | 0 |
| **Validated as Non-Equivalent (by tool)** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
All 7 DMS conversion attempts failed with `AccessDeniedException`:
```
User not authorized to perform dms:StartMetadataModelCreation on resource 
arn:aws:dms:us-east-1:812756961751:migration-project:*
```
Manual conversion was applied using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rules.

### SQL Equivalency Tool Status
All 7 equivalency validation attempts returned `ERROR` with `'uniqueID'` error (systemic tool issue, not statement-specific). No agent judgment was used for equivalency determination.

---

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync
- **Source**: `ProductRepository.cs` → `GetAllProductsAsync()`
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**: Table/column/CTE/alias names lowercased

### Statement 2: GetProductByIdAsync
- **Source**: `ProductRepository.cs` → `GetProductByIdAsync()`
- **Type**: SELECT with CTE, LAG Window Function, CASE, ROUND, parameterized
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**: Table/column/CTE/alias names lowercased

### Statement 3: InsertProductAsync
- **Source**: `ProductRepository.cs` → `InsertProductAsync()`
- **Type**: Transaction with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**:
  - `SCOPE_IDENTITY()` → Writable CTE with `RETURNING` clause
  - `GETDATE()` → `NOW()`
  - `DECLARE @var` → Removed (restructured with CTEs)
  - `BEGIN TRANSACTION/COMMIT` → Removed (single statement with CTEs)
  - All schema objects lowercased

### Statement 4: UpdateProductAsync
- **Source**: `ProductRepository.cs` → `UpdateProductAsync()`
- **Type**: Transaction with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` → Writable CTE `old_values` for variable capture
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Removed (single statement with CTEs)
  - All schema objects lowercased

### Statement 5: DeleteProductAsync
- **Source**: `ProductRepository.cs` → `DeleteProductAsync()`
- **Type**: Transaction with DECLARE, SELECT INTO, INSERT history, DELETE, UPDATE stats with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` → Writable CTE `old_values` for variable capture
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Removed (single statement with CTEs)
  - All schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `ProductRepository.cs` → `GetProductsByPriceRangeAsync()`
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**: Table/column/CTE/alias names lowercased

### Statement 7: GetLowStockProductsAsync
- **Source**: `ProductRepository.cs` → `GetLowStockProductsAsync()`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**:
  - Added `CAST(stockquantity AS DECIMAL)` for integer division in ROUND
  - All schema objects lowercased

---

## Code Changes Summary

### Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements replaced; all ADO.NET classes replaced |
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

### ADO.NET Class Replacements

| Original (MS SQL) | Replacement (PostgreSQL) |
|---|---|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (none present) |

### Connection String Changes

| Parameter | MS SQL Server | PostgreSQL |
|-----------|--------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

### Package Reference Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.6 |

### Files NOT Changed (No SQL Server-specific code)

- `Business/ProductService.cs` - Business logic only, no database access
- `CLI/CommandLineInterface.cs` - CLI interface, no database access
- `CLI/InteractiveMenu.cs` - Interactive menu, no database access
- `Models/Product.cs` - Data model, no database access
- `Program.cs` - Application entry point, no database access
- `README.md` - Documentation

### SQL Setup Scripts (Require Separate PostgreSQL Conversion)

- `Scripts/01_InitialSetup.sql` - Contains MS SQL-specific syntax:
  - `IF NOT EXISTS (SELECT * FROM sys.databases/sys.objects)`
  - `GO` batch separators
  - `IDENTITY(1,1)` columns
  - `CREATE OR ALTER PROCEDURE`
  - `GETDATE()`
- `Database/Scripts/01_InitialSetup.sql` - Contains all of the above plus:
  - `CREATE TRIGGER` with `inserted`/`deleted` pseudo-tables
  - `[dbo].[tablename]` schema syntax
  - `SYSTEM_USER` function
  - Foreign key constraints with SQL Server syntax

These scripts are database deployment scripts and are NOT executed by the application code. They require separate manual conversion for PostgreSQL deployment.

---

## Build Status

**Build: SUCCEEDED**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings from original code)
- No security vulnerability warnings

---

## Final Validation Checklist

| Check | Status |
|-------|--------|
| All `SqlConnection` → `NpgsqlConnection` replacements | ✅ Done |
| All `SqlCommand` → `NpgsqlCommand` replacements | ✅ Done |
| All `SqlDataReader` → `NpgsqlDataReader` replacements | ✅ Done |
| `Microsoft.Data.SqlClient` package replaced with `Npgsql` | ✅ Done (8.0.6) |
| Connection strings updated to PostgreSQL format | ✅ Done |
| All 7 SQL statements processed through DMS tool | ✅ Done (all failed, manual fallback) |
| All 7 statement pairs validated through SQL Equivalency tool | ✅ Done (all returned ERROR) |
| No agent judgment used for equivalency determination | ✅ Confirmed |
| Complete catalog of original statements exists | ✅ `extracted_statements.sql` |
| Complete catalog of converted statements exists | ✅ `converted_statements.sql` |
| SQL Equivalency validation report exists | ✅ `sql_equivalency_validation_report.json` |
| DMS conversion log exists | ✅ `dms_conversion_log.md` |
| Application compiles without errors | ✅ Build succeeded |
| No remaining Microsoft.Data.SqlClient references in .cs files | ✅ Confirmed |

---

## Transformation Artifacts

1. **`extracted_statements.sql`** - Complete catalog of all 7 original MS SQL statements with source annotations
2. **`converted_statements.sql`** - Complete catalog of all 7 converted PostgreSQL statements with conversion notes
3. **`sql_equivalency_validation_report.json`** - Comprehensive JSON report with all 7 statement pairs
4. **`dms_conversion_log.md`** - Detailed log of all 7 DMS attempts and manual interventions
5. **`migration_report.md`** - This report
