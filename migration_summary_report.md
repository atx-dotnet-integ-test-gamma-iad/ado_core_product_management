# Migration Summary Report

## Microsoft SQL Server to PostgreSQL Migration - AdoCore Application

**Date:** 2026-04-26  
**Application:** AdoCore (.NET 9.0 ADO.NET Application)  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  

---

## 1. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| DMS conversion successes | 0 |
| DMS conversion failures | 7 |
| Manual conversions (with lowercase schema) | 7 |
| Equivalency validated as EQUIVALENT | 0 |
| Equivalency validated as NOT_EQUIVALENT | 0 |
| Equivalency validation errors | 7 |

### DMS Tool Status
- **Tool:** dms-mcp___statement_conversion_tool
- **Migration Project:** arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Status:** All 7 statements were submitted to DMS. All failed with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Schema Mapping:** Successfully retrieved via dms-mcp___schema_mapping_tool, confirming target schema naming conventions (lowercase tables/columns, `productmanagement_dbo` schema)

### SQL Equivalency Tool Status
- **Tool:** sql-equivalency___validate_sql_equivalence
- **Status:** All 7 statement pairs were submitted for validation. All returned ERROR with: `'uniqueID'` (internal tool error)
- **Note:** Equivalency status values come exclusively from the tool output. No agent judgment was used to determine equivalency.

### Statements Requiring Manual Review
All 7 statements require manual review due to:
1. DMS conversion tool failure (manual conversion was applied)
2. SQL equivalency tool returning errors for all pairs

---

## 2. Statement Details

### Statement 1: GetAllProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Key Changes:** Table/column names lowercased, CTE renamed to `productstats_cte` to avoid table name conflict
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with LAG window function, LEFT JOIN, parameterized query
- **Key Changes:** Table/column names lowercased, CTE renamed to `producthistory_cte` to avoid table name conflict
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with SCOPE_IDENTITY(), GETDATE(), multi-table operations
- **Key Changes:** 
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @var` → C# variables with separate SQL commands
  - Single batch → Multiple NpgsqlCommand calls within C# transaction
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT
- **Key Changes:**
  - `DECLARE @OldPrice, @OldStock` → C# variables populated via separate SELECT query
  - `GETDATE()` → `NOW()`
  - Single batch → Multiple NpgsqlCommand calls within C# transaction
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** Transaction block with DECLARE, DELETE, CASE in UPDATE
- **Key Changes:**
  - `DECLARE @OldPrice, @OldStock` → C# variables populated via separate SELECT query
  - `GETDATE()` → `NOW()`
  - Single batch → Multiple NpgsqlCommand calls within C# transaction
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
- **Key Changes:** Table/column names lowercased (RANK/PERCENT_RANK are PostgreSQL-compatible)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **Type:** CTE with AVG/MIN/MAX OVER window functions, CASE, ROUND
- **Key Changes:** Table/column names lowercased, added `CAST(stockquantity AS NUMERIC)` for integer division
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## 3. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted; SqlClient→Npgsql class replacements; lowercase column names in MapProductFromReader |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings converted to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL conversion |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL conversion |

---

## 4. Package Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|--------------------| --------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Note:** Npgsql 8.0.0 was initially specified but upgraded to 8.0.6 to resolve known security vulnerability (GHSA-x9vc-6hfv-hg8c).

---

## 5. Class Replacements

| Original Class | Replacement Class | Occurrences |
|---------------|-------------------|-------------|
| SqlConnection | NpgsqlConnection | 3 |
| SqlCommand | NpgsqlCommand | 15 |
| SqlDataReader | NpgsqlDataReader | 1 |
| using Microsoft.Data.SqlClient | using Npgsql | 1 |

---

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
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| Server= | Host= |
| Database= | Database= (unchanged) |
| Trusted_Connection=True | Removed (N/A) |
| MultipleActiveResultSets=true | Removed (N/A) |
| TrustServerCertificate=True | Removed (N/A) |
| (N/A) | Port=5432 (added) |
| (N/A) | Username=postgres (added) |
| (N/A) | Password=postgres (added) |

---

## 7. SQL DDL Script Conversion Summary

### Key Transformations in Setup Scripts
| SQL Server Syntax | PostgreSQL Syntax |
|-------------------|-------------------|
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `GETDATE()` | `NOW()` |
| `[dbo].[TableName]` | `tablename` (lowercase, no brackets) |
| `GO` | Removed |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `BIT` | `BOOLEAN` |
| `NVARCHAR` | `VARCHAR` |
| `SYSTEM_USER` | `current_user` |
| `IF EXISTS (SELECT...sys.objects)` | `DROP TABLE IF EXISTS` |
| SQL Server trigger syntax | PostgreSQL trigger function + trigger |

---

## 8. Build Status

- **Final Build:** ✅ Success (0 errors, 10 warnings)
- **Warnings:** All pre-existing nullable reference warnings (CS8601, CS8618, CS8600, CS8603, CS8625) - no new warnings introduced
- **Security:** No known vulnerabilities in dependencies (Npgsql 8.0.6)

---

## 9. Artifacts Generated

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency validation report |
| migration_summary_report.md | sourceCode/ | This report |

---

## 10. Recommendations for Manual Review

1. **Verify all 7 converted SQL statements** against the actual PostgreSQL database schema to ensure table and column names match
2. **Test InsertProductAsync** thoroughly - this was the most significantly restructured method (SCOPE_IDENTITY → RETURNING, single batch → multiple commands)
3. **Verify transaction isolation** - the transaction handling was restructured from SQL-embedded transactions to C# NpgsqlTransaction management
4. **Run the SQL equivalency validation** again once the tool's internal error is resolved
5. **Consider connection pooling** - Npgsql has built-in connection pooling; verify the current connection management pattern works correctly
6. **Review the CAST in Statement 7** - added `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in PostgreSQL
