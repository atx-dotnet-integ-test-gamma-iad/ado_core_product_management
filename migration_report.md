# Migration Report: SQL Server to PostgreSQL for AdoCore Application

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Converted by DMS MCP Tool | 0 |
| Statements Requiring Manual Intervention | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 statements but consistently failed with the error:

```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
```

**Migration Project:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

4 total DMS attempts were made (including retries with increased polling parameters). All returned the same metadata model creation failure. Per the transformation definition, manual conversion was applied with lowercase schema object names.

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs but returned ERROR for all with the error:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Each pair was validated independently despite the errors. All equivalency statuses were determined solely by the tool's output - no agent judgment was used.

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient` (5.1.4) with `Npgsql` (8.0.6) |
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced all SqlClient classes with Npgsql equivalents; updated column name references to lowercase |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync()
- **Source Method:** `GetAllProductsAsync()`
- **Type:** CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Schema objects lowercased, SQL syntax compatible with PostgreSQL

### Statement 2: GetProductByIdAsync()
- **Source Method:** `GetProductByIdAsync(int productId)`
- **Type:** CTE with LAG window function, parameterized query
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Schema objects lowercased, LAG window function compatible

### Statement 3: InsertProductAsync()
- **Source Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `SCOPE_IDENTITY()` → CTE with `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` with `DECLARE` → Single CTE-based writable statement
  - Schema objects lowercased

### Statement 4: UpdateProductAsync()
- **Source Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE variables, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `DECLARE @var` / `SELECT INTO @var` → CTE with `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Single CTE-based writable statement
  - Schema objects lowercased

### Statement 5: DeleteProductAsync()
- **Source Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE, CASE for division-by-zero protection
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `DECLARE @var` / `SELECT INTO @var` → CTE with `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Single CTE-based writable statement
  - CASE for division-by-zero preserved
  - Schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync()
- **Source Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Schema objects lowercased, window functions compatible

### Statement 7: GetLowStockProductsAsync()
- **Source Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** CTE with AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - Schema objects lowercased
  - Added `::numeric` cast for integer division in ROUND expression

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server identification | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not supported) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Equivalency validation report with all 7 pairs |
| `dms_failure_summary.txt` | `sourceCode/` | Detailed DMS tool failure documentation |
| `migration_report.md` | `sourceCode/` | This comprehensive migration report |

## Build Status

Final build: **SUCCESS** (0 errors, 10 pre-existing nullable warnings)
