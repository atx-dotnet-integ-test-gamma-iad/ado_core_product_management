# Migration Report: MS SQL Server to PostgreSQL

## Project: AdoCore - Product Management System
## Date: 2026-03-24
## Migration Type: Microsoft SQL Server → PostgreSQL (Npgsql ADO.NET)

---

## Executive Summary

Successfully migrated the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. All 7 SQL statements were converted, all database access code was updated from Microsoft.Data.SqlClient to Npgsql, and all connection strings were converted to PostgreSQL format. The application compiles successfully with 0 errors after migration.

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failure)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
- **Tool**: `dms-mcp___statement_conversion_tool`
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Status**: FAILED for all 7 statements
- **Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Attempts**: 8 total attempts across 7 statements (including retries)

### Schema Mapping (DMS schema_mapping_tool - Successful)
The DMS schema mapping tool successfully provided target schema information:
- **Source Schema**: `dbo`
- **Target Schema**: `productmanagement_dbo`
- **Products** → `products` (all columns lowercase: productid, name, description, price, stockquantity, createddate, modifieddate)
- **ProductHistory** → `producthistory` (all columns lowercase: historyid, productid, action, oldprice, newprice, oldstock, newstock, actiondate)
- **ProductStats** → `productstats` (all columns lowercase: statid, totalproducts, averageprice, lastupdated)

### SQL Equivalency Validation
- **Tool**: `sql-equivalency___validate_sql_equivalence`
- **Status**: All 7 statement pairs returned ERROR
- **Error**: Internal tool error: `'uniqueID'`
- **Note**: All equivalency statuses come exclusively from the tool output, not agent judgment

---

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT OVER, JOIN, CASE, ROUND
- **Conversion**: Table/column names to lowercase
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG OVER, LEFT JOIN, CASE, ROUND
- **Conversion**: Table/column names to lowercase
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Multi-statement transaction block
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → Connection-level transaction (NpgsqlTransaction)
  - `DECLARE @Variable` → C# local variables
  - Single batch split into 3 separate NpgsqlCommand executions
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Multi-statement transaction block
- **Key Changes**:
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @Variable` → C# local variables with reader
  - `BEGIN TRANSACTION/COMMIT` → Connection-level transaction
  - Single batch split into 4 separate NpgsqlCommand executions
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Multi-statement transaction block
- **Key Changes**:
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @Variable` → C# local variables with reader
  - `BEGIN TRANSACTION/COMMIT` → Connection-level transaction
  - Single batch split into 4 separate NpgsqlCommand executions
- **DMS Status**: FAILED (Metadata model conversion failed)
- **Equivalency**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK/PERCENT_RANK OVER, BETWEEN, CASE
- **Conversion**: Table/column names to lowercase
- **DMS Status**: FAILED
- **Equivalency**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX OVER, CASE, ROUND
- **Key Changes**:
  - Table/column names to lowercase
  - Added `CAST(stockquantity AS NUMERIC)` for integer division in ROUND
- **DMS Status**: FAILED
- **Equivalency**: ERROR

---

## Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| `AdoCore.csproj` | Package Reference | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | Using Statement | `using Microsoft.Data.SqlClient;` → `using Npgsql;` |
| `DataAccess/ProductRepository.cs` | Type References | `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, `SqlDataReader` → `NpgsqlDataReader`, `SqlTransaction` → `NpgsqlTransaction` |
| `DataAccess/ProductRepository.cs` | SQL Statements | All 7 SQL statements converted to PostgreSQL syntax |
| `DataAccess/ProductRepository.cs` | Transaction Handling | Inline SQL transactions → Connection-level `BeginTransactionAsync`/`CommitAsync`/`RollbackAsync` |
| `DataAccess/ProductRepository.cs` | Column References | `MapProductFromReader` updated to use lowercase column names |
| `appsettings.json` | Connection Strings | SQL Server format → PostgreSQL format (`Host=`, `Database=postgres`, `Username=`, `Password=`) |

## Files NOT Modified (No Changes Required)

| File | Reason |
|------|--------|
| `Business/ProductService.cs` | No database-specific code |
| `CLI/CommandLineInterface.cs` | No database-specific code |
| `CLI/InteractiveMenu.cs` | No database-specific code |
| `Models/Product.cs` | No database-specific code |
| `Program.cs` | No database-specific code |

---

## Code Changes Summary

### Package Replacement
- **Removed**: `Microsoft.Data.SqlClient` version `5.1.4`
- **Added**: `Npgsql` version `8.0.6` (initially 8.0.0 per plan, upgraded to fix known high severity vulnerability GHSA-x9vc-6hfv-hg8c)

### Type Replacements
- `SqlConnection` → `NpgsqlConnection` (3 occurrences)
- `SqlCommand` → `NpgsqlCommand` (15 occurrences)
- `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
- `SqlTransaction` → `NpgsqlTransaction` (11 occurrences)

### SQL Syntax Conversions
- `SCOPE_IDENTITY()` → `RETURNING productid` clause
- `GETDATE()` → `clock_timestamp()`
- `BEGIN TRANSACTION/COMMIT` → Connection-level `BeginTransactionAsync()`/`CommitAsync()`
- `DECLARE @Variable` → C# local variables
- All table names → lowercase (Products→products, ProductHistory→producthistory, ProductStats→productstats)
- All column names → lowercase per DMS schema mapping

### Connection String Updates
- `Server=` → `Host=`
- `Database=ProductManagement` → `Database=postgres`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed: `MultipleActiveResultSets=true`, `TrustServerCertificate=True`

---

## Transformation Artifacts

| Artifact | Location | Contents |
|----------|----------|----------|
| `extracted_statements.sql` | Project root | 7 original MS SQL statements with metadata |
| `converted_statements.sql` | Project root | 7 converted PostgreSQL statements with metadata |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive validation report for all 7 pairs |
| `migration_report.md` | Project root | This report |

---

## Final Validation Checklist

- [x] All Microsoft.Data.SqlClient references removed (0 remaining)
- [x] All Npgsql references added (package + using statement)
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents (0 remaining)
- [x] All 7 SQL statements converted to PostgreSQL syntax
- [x] All connection strings updated to PostgreSQL format
- [x] sql_equivalency_validation_report.json has all 7 entries with tool-determined equivalency status
- [x] Build succeeds with 0 errors
- [x] No known security vulnerabilities in dependencies

---

## Statements Requiring Manual Review

All 7 statements should be manually reviewed since:
1. DMS tool failed for all conversions (manual conversion was applied)
2. SQL Equivalency tool returned ERROR for all pairs (internal tool issue)
3. Transaction blocks (statements 3, 4, 5) were significantly restructured from inline SQL batches to connection-level transactions with separate commands

---

## Build Status

**Final Build**: SUCCESS (0 errors, 10 warnings - all pre-existing nullable warnings)
