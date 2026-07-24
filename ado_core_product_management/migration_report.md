# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements sent to DMS MCP tool | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with the same error:

**Error:** `AccessDeniedException: User arn:aws:sts::340752807109:assumed-role/ATX_MDE_SECURE_EXECUTION_ROLE/e-433b42c111314611909829e49404afb3 is not authorized to perform: dms:StartMetadataModelCreation on resource: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

**Manual Conversion Applied:** All statements were manually converted using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rules.

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency MCP tool. All returned ERROR status:

**Error:** `'uniqueID'` - This appears to be a systemic tool infrastructure issue affecting all queries including trivial test cases.

## Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE and Window Functions)
- **Source:** DataAccess/ProductRepository.cs
- **Changes:** Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **SQL Features Preserved:** CTE, AVG() OVER(), COUNT() OVER(), CASE WHEN, ROUND(), INNER JOIN

### Statement 2: GetProductByIdAsync (SELECT with CTE and LAG)
- **Source:** DataAccess/ProductRepository.cs
- **Changes:** Lowercase schema objects
- **SQL Features Preserved:** CTE, LAG() OVER(), CASE WHEN, ROUND(), LEFT JOIN

### Statement 3: InsertProductAsync (Transaction with INSERT)
- **Source:** DataAccess/ProductRepository.cs
- **Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid` (writable CTE pattern)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTE (atomic single statement)
  - `DECLARE @var` → Eliminated via CTE structure
  - Lowercase schema objects

### Statement 4: UpdateProductAsync (Transaction with UPDATE)
- **Source:** DataAccess/ProductRepository.cs
- **Changes:**
  - `DECLARE @OldPrice/DECLARE @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTE (atomic single statement)
  - Lowercase schema objects

### Statement 5: DeleteProductAsync (Transaction with DELETE)
- **Source:** DataAccess/ProductRepository.cs
- **Changes:**
  - `DECLARE @OldPrice/DECLARE @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTE (atomic single statement)
  - Lowercase schema objects

### Statement 6: GetProductsByPriceRangeAsync (SELECT with RANK/PERCENT_RANK)
- **Source:** DataAccess/ProductRepository.cs
- **Changes:** Lowercase schema objects
- **SQL Features Preserved:** CTE, RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE WHEN

### Statement 7: GetLowStockProductsAsync (SELECT with AVG/MIN/MAX)
- **Source:** DataAccess/ProductRepository.cs
- **Changes:** Lowercase schema objects, added `::numeric` cast for integer division
- **SQL Features Preserved:** CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE WHEN, ROUND()

## Static Code Changes

### Package References (AdoCore.csproj)
- **Removed:** `Microsoft.Data.SqlClient` Version 5.1.4
- **Added:** `Npgsql` Version 8.0.3 (CVE scan: PASS)

### ADO.NET Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection Strings (appsettings.json)
- `Server=localhost` → `Host=localhost`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed: `MultipleActiveResultSets=true` (not supported/needed in PostgreSQL)
- Removed: `TrustServerCertificate=True` (SQL Server specific)

### Column Name References in MapProductFromReader
- Updated all reader index names to lowercase (e.g., `reader["ProductId"]` → `reader["productid"]`)

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of original MS SQL statements
2. `converted_statements.sql` - Complete catalog of converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report
