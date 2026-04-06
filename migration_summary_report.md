# Migration Summary Report: MS SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-06  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  
**Application Framework:** .NET 9.0, ADO.NET  

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS | 0 |
| Statements Requiring Manual Intervention | 7 |
| Manual Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

### DMS Tool Status
The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements. All attempts failed with timeout errors:
- **Error:** `Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts`
- **Root Cause:** The DMS metadata model conversion step timed out consistently during polling

### Schema Mapping
The DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) was successfully used to obtain accurate schema mappings:

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `products` |
| `dbo.ProductHistory` | `producthistory` |
| `dbo.ProductStats` | `productstats` |
| `dbo.Categories` | `categories` |
| `dbo.Suppliers` | `suppliers` |
| `ProductId` (column) | `productid` |
| `StockQuantity` (column) | `stockquantity` |
| `CreatedDate` (column) | `createddate` |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `RETURNING` clause |
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `nvarchar` | `VARCHAR` |
| `decimal` | `NUMERIC` |
| `bit` | `NUMERIC(1,0)` |

---

## SQL Equivalency Validation Summary

| Metric | Count |
|--------|-------|
| Total Statement Pairs Validated | 7 |
| Equivalent Statements | 0 |
| Non-Equivalent Statements | 0 |
| Statements with Equivalency Error | 7 |

### Equivalency Tool Status
The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs. All calls returned an internal error:
- **Error:** `'uniqueID'`
- **Note:** This appears to be an internal tool error unrelated to the SQL statements themselves
- **Impact:** Equivalency status for all statements is recorded as `ERROR` per the transformation definition requirements

---

## Statement Details

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion:** Table/column names lowercased per DMS schema mapping
- **Key Changes:** `Products` → `products`, `ProductId` → `productid`, etc.
- **Equivalency:** ERROR (tool internal error)

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG window function, LEFT JOIN, CASE with ROUND
- **Conversion:** Table/column names lowercased per DMS schema mapping
- **Key Changes:** `Products` → `products`, `ModifiedDate` → `modifieddate`, etc.
- **Equivalency:** ERROR (tool internal error)

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), ProductHistory INSERT, ProductStats UPDATE
- **Conversion:** Restructured from single multi-statement SQL to separate commands within C#-managed transaction
- **Key Changes:** `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `clock_timestamp()`, `BEGIN TRANSACTION/COMMIT` → C# transaction management
- **Equivalency:** ERROR (tool internal error)

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT into variables, UPDATE, ProductHistory INSERT, ProductStats UPDATE
- **Conversion:** Restructured from single multi-statement SQL to separate commands within C#-managed transaction
- **Key Changes:** `DECLARE @var` → C# variables via reader, `GETDATE()` → `clock_timestamp()`
- **Equivalency:** ERROR (tool internal error)

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT into variables, ProductHistory INSERT, DELETE, ProductStats UPDATE with CASE
- **Conversion:** Restructured from single multi-statement SQL to separate commands within C#-managed transaction
- **Key Changes:** `DECLARE @var` → C# variables via reader, `GETDATE()` → `clock_timestamp()`, division-by-zero CASE preserved
- **Equivalency:** ERROR (tool internal error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **Conversion:** Table/column names lowercased per DMS schema mapping
- **Key Changes:** `Products` → `products`, `Price` → `price`, etc.
- **Equivalency:** ERROR (tool internal error)

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion:** Table/column names lowercased per DMS schema mapping
- **Key Changes:** `Products` → `products`, `StockQuantity` → `stockquantity`, added `::NUMERIC` cast for integer division in ROUND
- **Equivalency:** ERROR (tool internal error)

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, SqlClient → Npgsql classes, column names lowercased in reader |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL, functions, and DML |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL, functions, triggers, indexes, and DML |

---

## Package Dependency Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|--------------------:|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Note:** Version 8.0.6 was used instead of 8.0.1 due to known high severity vulnerability (GHSA-x9vc-6hfv-hg8c) in versions prior to 8.0.6.

---

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` | `NpgsqlTransaction` | 15 |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

---

## Connection String Changes

### Development Connection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`

### Production Connection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=` | `Host=` |
| `Trusted_Connection=True` | Removed (replaced with Username/Password) |
| `MultipleActiveResultSets=true` | Removed (SQL Server specific) |
| `TrustServerCertificate=True` | Removed (SQL Server specific) |
| N/A | `Port=5432` (added) |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

---

## Issues and Warnings

### DMS Tool Timeout
- **Issue:** DMS statement conversion tool consistently timed out for all 7 statements
- **Resolution:** Used manual conversion with lowercase schema mapping based on DMS schema_mapping_tool output
- **Impact:** All statements converted manually following DMS schema naming conventions

### SQL Equivalency Tool Internal Error
- **Issue:** SQL Equivalency tool returned `'uniqueID'` error for all 7 statement pairs
- **Resolution:** All equivalency statuses recorded as `ERROR` per transformation definition
- **Impact:** Equivalency validation could not be completed; manual review recommended

### Npgsql Version Security
- **Issue:** Npgsql 8.0.1 has known high severity vulnerability GHSA-x9vc-6hfv-hg8c
- **Resolution:** Used Npgsql 8.0.6 which resolves the vulnerability
- **Impact:** None - same API surface

### Transaction Pattern Restructuring
- **Issue:** SQL Server's `DECLARE @var` and `SCOPE_IDENTITY()` patterns don't work in PostgreSQL inline SQL
- **Resolution:** Restructured Insert/Update/Delete methods to use separate NpgsqlCommand instances within C#-managed transactions
- **Impact:** Functionally equivalent behavior; improved separation of concerns

---

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `sql_equivalency_validation_report.json` | `sourceCode/` | Complete equivalency validation report with all 7 statement pairs |
| `extracted_statements.sql` | `sourceCode/` | Catalog of all original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | Catalog of all converted PostgreSQL statements |
| `migration_summary_report.md` | `sourceCode/` | This report |

---

## Build Status
- **Final Build:** SUCCESS (0 errors)
- **Warnings:** Nullable reference type warnings only (pre-existing, not introduced by migration)
