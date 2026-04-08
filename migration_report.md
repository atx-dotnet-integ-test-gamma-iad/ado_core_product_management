# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-08  
**Source Database:** Microsoft SQL Server (via Microsoft.Data.SqlClient 5.1.4)  
**Target Database:** PostgreSQL (via Npgsql 8.0.6)  
**Framework:** .NET 9.0  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention after DMS failure | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following parameters:
- **Migration Project ARN:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Region:** us-east-1
- **Database:** ProductManagement
- **Schema:** dbo

All 7 calls failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

All statements were manually converted applying lowercase schema object names per the DMS failure fallback procedure.

### SQL Equivalency Tool Status
All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

All 7 validations returned ERROR status with error: `'uniqueID'` — this appears to be an infrastructure issue with the equivalency tool. No agent judgment was used to determine equivalency.

---

## SQL Statements Converted

### Statement 1: GetAllProductsAsync
- **Method:** `GetAllProductsAsync()`
- **Type:** SELECT with CTE, window functions (AVG, COUNT OVER), INNER JOIN, CASE ORDER BY
- **Key Changes:** Schema objects lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error)

### Statement 2: GetProductByIdAsync
- **Method:** `GetProductByIdAsync(int productId)`
- **Type:** SELECT with CTE, LAG window function, LEFT JOIN, ROUND, CASE with NULL
- **Key Changes:** Schema objects lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error)

### Statement 3: InsertProductAsync
- **Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING` via writable CTE
  - `GETDATE()` → `NOW()`
  - `DECLARE @var / SET @var` → eliminated via writable CTE pattern
  - `BEGIN TRANSACTION / COMMIT` → removed (writable CTE provides atomicity)
  - Schema objects lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error)

### Statement 4: UpdateProductAsync
- **Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE, SELECT into vars, UPDATE, INSERT history, UPDATE stats
- **Key Changes:**
  - `DECLARE @OldPrice / @OldStock` → CTE subquery pattern
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION / COMMIT` → removed (writable CTE provides atomicity)
  - Schema objects lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error)

### Statement 5: DeleteProductAsync
- **Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE, SELECT into vars, INSERT history, DELETE, UPDATE stats with CASE
- **Key Changes:**
  - `DECLARE @OldPrice / @OldStock` → CTE subquery pattern
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION / COMMIT` → removed (writable CTE provides atomicity)
  - Schema objects lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error)

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** SELECT with CTE, RANK, PERCENT_RANK, BETWEEN, CASE
- **Key Changes:** Schema objects lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error)

### Statement 7: GetLowStockProductsAsync
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** SELECT with CTE, AVG/MIN/MAX window aggregates, CASE, ROUND
- **Key Changes:** Schema objects lowercased, added `CAST(stockquantity AS DECIMAL)` for integer division fix
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error)

---

## Files Modified

### 1. DataAccess/ProductRepository.cs
- **SQL Statements:** All 7 SQL statements replaced with PostgreSQL equivalents
- **ADO.NET Class Replacements:**
  - `using Microsoft.Data.SqlClient;` → `using Npgsql;`
  - `SqlConnection` → `NpgsqlConnection` (field declaration, return type, instantiation)
  - `SqlCommand` → `NpgsqlCommand` (all 7 command instantiations)
  - `SqlDataReader` → `NpgsqlDataReader` (MapProductFromReader parameter)
- **Parameter Syntax:** `@paramName` format preserved (compatible with both SQL Server and PostgreSQL/Npgsql)

### 2. AdoCore.csproj
- **Removed:** `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added:** `<PackageReference Include="Npgsql" Version="8.0.6" />`
- **Unchanged:** Microsoft.Extensions.Configuration (8.0.0), Configuration.Json (8.0.0), DependencyInjection (8.0.0)

### 3. appsettings.json
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection:** Same transformation
- **Key Mappings:** Server→Host, Trusted_Connection removed, MARS removed, TrustServerCertificate removed, explicit auth added

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Equivalency validation results for all 7 pairs |
| migration_report.md | sourceCode/ | This comprehensive migration report |

---

## Final Validation Checklist

- ✅ All SQL Server packages replaced with Npgsql (Microsoft.Data.SqlClient → Npgsql)
- ✅ All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- ✅ ALL 7 SQL statements processed through DMS MCP tool (all failed, manually converted)
- ✅ ALL 7 statement pairs validated through SQL Equivalency tool (all returned ERROR)
- ✅ All connection strings updated to PostgreSQL format
- ✅ Application compiles successfully (0 errors, 10 pre-existing warnings)
- ✅ No agent judgment used for equivalency determination (all results from tool)
- ✅ Complete catalog of all statements maintained (extracted + converted + report)

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure preventing automated conversion validation
2. SQL Equivalency tool returning ERROR for all pairs
3. Manual conversion applied with lowercase schema object names

**Priority areas for manual review:**
- Statements 3, 4, 5 (InsertProduct, UpdateProduct, DeleteProduct): These underwent significant structural changes from SQL Server transaction blocks with DECLARE/SET to PostgreSQL writable CTEs. The atomicity behavior should be verified.
- Statement 7 (GetLowStockProducts): Added explicit CAST for integer division to prevent truncation differences between SQL Server and PostgreSQL.

---

## Build Status

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All warnings are pre-existing nullable reference warnings, not introduced by the migration.
