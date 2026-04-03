# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL, including all SQL statement conversions, ADO.NET class replacements, package updates, and connection string changes.

**Migration Date:** 2026-04-03  
**Application:** AdoCore (.NET 9.0)  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**DMS Migration Project:** arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (by equivalency tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

### DMS Tool Status
The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was called for every SQL statement but consistently failed with metadata model creation/conversion timeouts:
- **Error:** "Metadata model creation/conversion did not complete after N attempts"
- **Attempts:** 4 separate calls with varying configurations (different poll attempts, intervals, explicit parameters)
- **All 7 statements were submitted** to DMS before falling back to manual conversion

### DMS Schema Mapping Tool Status
The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was successfully used to obtain target schema mappings:
- **Products** → `products` (schema: `productmanagement_dbo`)
- **ProductHistory** → `producthistory` (schema: `productmanagement_dbo`)
- **ProductStats** → `productstats` (schema: `productmanagement_dbo`)
- All column names mapped to lowercase per DMS schema mapping

### SQL Equivalency Tool Status
The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs but returned ERROR for each:
- **Error:** `'uniqueID'` (consistent internal tool error)
- **All 7 pairs were submitted** independently

---

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync
- **Method:** `GetAllProductsAsync()`
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model conversion did not complete after 15 attempts
- **Equivalency Status:** ERROR ('uniqueID')
- **Key Changes:** Table/column names to lowercase, CTE name changed to `productstats_cte` to avoid conflict with `productstats` table

### Statement 2: GetProductByIdAsync
- **Method:** `GetProductByIdAsync(int productId)`
- **Type:** CTE with LAG window function, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model conversion did not complete after 15 attempts
- **Equivalency Status:** ERROR ('uniqueID')
- **Key Changes:** Table/column names to lowercase, CTE name changed to `producthistory_cte`

### Statement 3: InsertProductAsync
- **Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction with SCOPE_IDENTITY(), GETDATE(), INSERT, UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation did not complete after 20 attempts
- **Equivalency Status:** ERROR ('uniqueID')
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - T-SQL `DECLARE`/`BEGIN TRANSACTION`/`COMMIT` → Split into 3 separate SQL statements within C# managed `NpgsqlTransaction`
  - Table/column names to lowercase

### Statement 4: UpdateProductAsync
- **Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction with DECLARE variables, GETDATE(), SELECT INTO variables
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation did not complete after 20 attempts
- **Equivalency Status:** ERROR ('uniqueID')
- **Key Changes:**
  - `DECLARE @var` / `SELECT @var = col` → Separate SELECT query read via `ExecuteReaderAsync()`
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → Split into 4 separate SQL statements within C# `NpgsqlTransaction`
  - Table/column names to lowercase

### Statement 5: DeleteProductAsync
- **Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction with DECLARE variables, CASE, GETDATE(), DELETE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation did not complete after 20 attempts
- **Equivalency Status:** ERROR ('uniqueID')
- **Key Changes:**
  - `DECLARE @var` / `SELECT @var = col` → Separate SELECT query read via `ExecuteReaderAsync()`
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → Split into 4 separate SQL statements within C# `NpgsqlTransaction`
  - CASE expression preserved (compatible with PostgreSQL)
  - Table/column names to lowercase

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** CTE with RANK, PERCENT_RANK window functions, CASE, BETWEEN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation did not complete after 20 attempts
- **Equivalency Status:** ERROR ('uniqueID')
- **Key Changes:** Table/column names to lowercase

### Statement 7: GetLowStockProductsAsync
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error:** Metadata model creation did not complete after 20 attempts
- **Equivalency Status:** ERROR ('uniqueID')
- **Key Changes:** Table/column names to lowercase

---

## Code Changes Summary

### Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All SQL statements replaced with PostgreSQL equivalents; all SqlClient classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

### Files Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Full equivalency validation report with all 7 statement pairs |
| `migration_report.md` | This comprehensive migration report |

### Package Changes
- **Removed:** `Microsoft.Data.SqlClient` v5.1.4
- **Added:** `Npgsql` v8.0.6 (v8.0.6 chosen over v8.0.0 to avoid known vulnerability GHSA-x9vc-6hfv-hg8c)

### ADO.NET Class Replacements
| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (not specified) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | (removed - not applicable) |
| TrustServerCertificate | `True` | (removed - not applicable) |

### SQL Syntax Changes
| SQL Server | PostgreSQL |
|-----------|------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var` / inline transactions | C# managed `NpgsqlTransaction` with separate statements |
| `SELECT @var = col FROM table` | Separate `SELECT` query with `ExecuteReaderAsync()` |
| `Products` (table) | `products` |
| `ProductHistory` (table) | `producthistory` |
| `ProductStats` (table) | `productstats` |
| `ProductId`, `Name`, etc. | `productid`, `name`, etc. |

---

## Exit Criteria Verification

| Criteria | Status |
|----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ Complete |
| All SqlClient ADO.NET classes replaced with Npgsql | ✅ Complete |
| All 7 SQL statements processed through DMS MCP tool | ✅ Complete (all failed, manual conversion applied) |
| Comprehensive catalog of all SQL statements exists | ✅ Complete (extracted_statements.sql, converted_statements.sql) |
| All 7 statement pairs validated through SQL Equivalency tool | ✅ Complete (all returned ERROR) |
| Comprehensive equivalency validation report generated | ✅ Complete (sql_equivalency_validation_report.json) |
| No agent judgment used for equivalency determination | ✅ Compliant |
| DMS failures documented with original statement and error | ✅ Complete |
| Connection strings updated to PostgreSQL format | ✅ Complete |
| Transaction handling updated for PostgreSQL | ✅ Complete |
| Application compiles without errors | ✅ Complete (Build succeeded, 0 errors) |

---

## Build Status
```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```
All warnings are pre-existing nullable reference type warnings, not related to the migration.
