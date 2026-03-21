# Migration Report: MS SQL Server to PostgreSQL

## Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using ADO.NET with Npgsql. The migration involved extracting, converting, and validating 7 SQL statements from the application's data access layer, along with updating all static code dependencies, connection strings, and ADO.NET class references.

**Migration Date:** 2026-03-21  
**Application:** AdoCore Product Management System  
**Source Database:** Microsoft SQL Server (ProductManagement database, dbo schema)  
**Target Database:** PostgreSQL (ProductManagement database, productmanagement_dbo schema)  
**Framework:** .NET 9.0 with ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Successes | 0 |
| DMS Tool Conversion Failures | 7 |
| Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA) | 7 |
| SQL Equivalency: EQUIVALENT | 0 |
| SQL Equivalency: NOT_EQUIVALENT | 0 |
| SQL Equivalency: ERROR | 7 |

---

## DMS Conversion Results

All 7 statements were submitted to the AWS DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`). All conversions failed due to metadata model conversion timeouts or validation errors.

### DMS Tool Parameters Used
- **migration_project_identifier:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **database_name:** `ProductManagement`
- **schema_name:** `dbo`
- **region:** `us-east-1`

### Statement-by-Statement DMS Results

| # | Statement | DMS Status | DMS Error | Timestamp |
|---|-----------|------------|-----------|-----------|
| 1 | GetAllProductsAsync | FAILED | Metadata model conversion did not complete after 15 attempts | 2026-03-21T04:50:25 |
| 2 | GetProductByIdAsync | FAILED | Metadata model conversion did not complete after 15 attempts | 2026-03-21T05:13:33 |
| 3 | InsertProductAsync | FAILED | Metadata model creation failed: Statement definition is not valid. | 2026-03-21T05:18:33 |
| 4 | UpdateProductAsync | FAILED | Metadata model conversion did not complete after 15 attempts | 2026-03-21T05:20:58 |
| 5 | DeleteProductAsync | FAILED | Metadata model conversion did not complete after 15 attempts | 2026-03-21T05:24:29 |
| 6 | GetProductsByPriceRangeAsync | FAILED | Metadata model conversion did not complete after 15 attempts | 2026-03-21T05:29:36 |
| 7 | GetLowStockProductsAsync | FAILED | Metadata model conversion did not complete after 15 attempts | 2026-03-21T05:34:43 |

**Note:** Statement 1 (GetAllProductsAsync) was attempted 3 times with different polling configurations. All attempts resulted in the same timeout error.

---

## SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`). All validations returned ERROR status.

| # | Statement | Equivalency Status | Tool Error | Timestamp |
|---|-----------|-------------------|------------|-----------|
| 1 | GetAllProductsAsync | ERROR | 'uniqueID' | 2026-03-21T05:41:59 |
| 2 | GetProductByIdAsync | ERROR | 'uniqueID' | 2026-03-21T05:42:17 |
| 3 | InsertProductAsync | ERROR | 'uniqueID' | 2026-03-21T05:42:38 |
| 4 | UpdateProductAsync | ERROR | 'uniqueID' | 2026-03-21T05:42:56 |
| 5 | DeleteProductAsync | ERROR | 'uniqueID' | 2026-03-21T05:43:13 |
| 6 | GetProductsByPriceRangeAsync | ERROR | 'uniqueID' | 2026-03-21T05:43:31 |
| 7 | GetLowStockProductsAsync | ERROR | 'uniqueID' | 2026-03-21T05:43:48 |

**Note:** All equivalency statuses come exclusively from the SQL Equivalency tool output. No agent judgment was used to determine equivalency.

---

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type:** CTE with AVG/COUNT window functions, INNER JOIN, ORDER BY with CASE
- **Key Conversions:**
  - `[dbo].[Products]` → `productmanagement_dbo.products`
  - All column/alias names lowercased
  - Added `NULLS FIRST` to ORDER BY clauses
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function, LEFT OUTER JOIN
- **Key Conversions:**
  - `[dbo].[Products]` → `productmanagement_dbo.products`
  - `LAG()` syntax preserved (compatible)
  - All column/alias names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY, INSERT history, UPDATE stats
- **Key Conversions:**
  - `BEGIN TRANSACTION/COMMIT TRANSACTION` → `DO $$ BEGIN...END $$`
  - `SCOPE_IDENTITY()` → `currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'))`
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @var INT` → `DECLARE var_var INTEGER`
  - `[dbo].[Products]` → `productmanagement_dbo.products`
  - `[dbo].[ProductHistory]` → `productmanagement_dbo.producthistory`
  - `[dbo].[ProductStats]` → `productmanagement_dbo.productstats`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with SELECT INTO vars, UPDATE, INSERT history, UPDATE stats
- **Key Conversions:**
  - `BEGIN TRANSACTION/COMMIT TRANSACTION` → `DO $$ BEGIN...END $$`
  - `DECLARE @var DECIMAL(18,2)` → `DECLARE var_var NUMERIC(18,2)`
  - `SELECT @var = col` → `SELECT col INTO var`
  - `GETDATE()` → `clock_timestamp()`
  - Schema object names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with SELECT INTO vars, INSERT history, DELETE, UPDATE stats with CASE
- **Key Conversions:**
  - `BEGIN TRANSACTION/COMMIT TRANSACTION` → `DO $$ BEGIN...END $$`
  - `DECLARE @var DECIMAL(18,2)` → `DECLARE var_var NUMERIC(18,2)`
  - `SELECT @var = col` → `SELECT col INTO var`
  - `GETDATE()` → `clock_timestamp()`
  - Schema object names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK/PERCENT_RANK window functions, BETWEEN, ORDER BY
- **Key Conversions:**
  - `[dbo].[Products]` → `productmanagement_dbo.products`
  - `PERCENT_RANK()` → `percent_rank()` (lowercased)
  - All column/alias names lowercased
  - Added `NULLS FIRST` to ORDER BY
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX window functions, CAST, ORDER BY
- **Key Conversions:**
  - `[dbo].[Products]` → `productmanagement_dbo.products`
  - `CAST(x AS DECIMAL)` → `CAST(x AS NUMERIC)`
  - All column/alias names lowercased
  - Added `NULLS FIRST` to ORDER BY
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Static Code Migration Summary

### Package References
| Change | Status |
|--------|--------|
| Remove `Microsoft.Data.SqlClient` | ✅ Not present (already removed) |
| Add `Npgsql` 8.0.3 | ✅ Present in AdoCore.csproj |

### Import Statements
| Change | Status |
|--------|--------|
| Remove `using Microsoft.Data.SqlClient` | ✅ Not present |
| Remove `using System.Data.SqlClient` | ✅ Not present |
| Add `using Npgsql` | ✅ Present in ProductRepository.cs |

### ADO.NET Class Replacements
| SQL Server Class | Npgsql Equivalent | Status |
|-----------------|-------------------|--------|
| SqlConnection | NpgsqlConnection | ✅ Replaced |
| SqlCommand | NpgsqlCommand | ✅ Replaced |
| SqlDataReader | NpgsqlDataReader | ✅ Replaced |
| SqlParameter | AddWithValue pattern | ✅ Using AddWithValue |

### Connection Strings
| Parameter | SQL Server | PostgreSQL | Status |
|-----------|-----------|------------|--------|
| Server/Host | Server= | Host=localhost | ✅ Updated |
| Database | Database= | Database=ProductManagement | ✅ Maintained |
| Authentication | Integrated Security/Trusted_Connection | Username/Password | ✅ Updated |
| MARS | MultipleActiveResultSets=true | N/A (removed) | ✅ Not present |
| TrustServerCertificate | TrustServerCertificate=true | N/A (removed) | ✅ Not present |

### Transaction Handling
| Method | Status |
|--------|--------|
| BeginTransactionAsync | ✅ Using Npgsql-compatible |
| CommitAsync | ✅ Using Npgsql-compatible |
| RollbackAsync | ✅ Using Npgsql-compatible |

---

## Files Modified During Migration

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | SQL statements converted, Npgsql classes used |
| AdoCore.csproj | Npgsql 8.0.3 package reference |
| appsettings.json | PostgreSQL connection strings |
| Database/Scripts/01_InitialSetup.sql | PostgreSQL DDL schema |
| Scripts/01_InitialSetup.sql | PostgreSQL DDL schema |

---

## Migration Artifacts

| Artifact | Description | Location |
|----------|-------------|----------|
| extracted_statements.sql | All 7 original MS SQL + PostgreSQL statement pairs | sourceCode/extracted_statements.sql |
| converted_statements.sql | All 7 DMS conversion results with detailed output | sourceCode/converted_statements.sql |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report (JSON) | sourceCode/sql_equivalency_validation_report.json |
| migration_report.md | This report | sourceCode/migration_report.md |

---

## Build Status

```
Build succeeded.
0 Error(s)
10 Warning(s) (pre-existing nullable reference warnings)
```

**Build command:** `dotnet build`  
**Target framework:** net9.0  
**Output:** AdoCore.dll  

---

## Validation Checklist

| # | Criterion | Status |
|---|-----------|--------|
| 1 | All SQL Server packages replaced with PostgreSQL equivalents | ✅ |
| 2 | All SqlConnection/SqlCommand/etc. replaced with Npgsql equivalents | ✅ |
| 3 | ALL 7 SQL statements processed through DMS MCP tool | ✅ (all failed, manual conversion applied) |
| 4 | Comprehensive catalog of all SQL statements exists | ✅ (extracted_statements.sql, converted_statements.sql) |
| 5 | ALL 7 SQL statement pairs validated through SQL Equivalency tool | ✅ (all returned ERROR) |
| 6 | Comprehensive equivalency validation report generated | ✅ (sql_equivalency_validation_report.json) |
| 7 | No agent judgment used for equivalency determination | ✅ |
| 8 | DMS failures documented with original statement, error, and manual conversion | ✅ |
| 9 | Connection strings updated to PostgreSQL format | ✅ |
| 10 | Transaction handling updated for PostgreSQL | ✅ |
| 11 | Application compiles without errors | ✅ (0 errors, 10 warnings) |
| 12 | All equivalency statuses from tool output only | ✅ |

---

## Schema Mapping Reference

| MS SQL Server | PostgreSQL |
|--------------|------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

## Function/Syntax Mapping Reference

| MS SQL Server | PostgreSQL |
|--------------|------------|
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `currval(pg_get_serial_sequence(...))` |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` |
| `INT` | `INTEGER` |
| `NVARCHAR` | `VARCHAR` |
| `DATETIME` | `TIMESTAMP WITHOUT TIME ZONE` |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `BEGIN TRANSACTION/COMMIT` | `DO $$ BEGIN...END $$` |
| `SELECT @var = col` | `SELECT col INTO var` |
| `SET @var = expr` | `var := expr` |
