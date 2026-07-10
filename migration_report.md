# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-07-10

## SQL Statement Processing

### Total Statements: 7

| # | Method | DMS Status | Manual Conversion | Equivalency Status |
|---|--------|-----------|-------------------|-------------------|
| 1 | GetAllProductsAsync | FAILED | Yes (lowercase schema) | ERROR |
| 2 | GetProductByIdAsync | FAILED | Yes (lowercase schema) | ERROR |
| 3 | InsertProductAsync | FAILED | Yes (lowercase schema + restructure) | ERROR |
| 4 | UpdateProductAsync | FAILED | Yes (lowercase schema + restructure) | ERROR |
| 5 | DeleteProductAsync | FAILED | Yes (lowercase schema + restructure) | ERROR |
| 6 | GetProductsByPriceRangeAsync | FAILED | Yes (lowercase schema) | ERROR |
| 7 | GetLowStockProductsAsync | FAILED | Yes (lowercase schema) | ERROR |

### DMS Tool Results
- **Statements passed to DMS**: 7/7
- **Statements successfully converted by DMS**: 0
- **DMS Error**: Metadata model creation failed: 'Metadata model creation did not complete after 15 attempts'
- **Statements requiring manual conversion**: 7

### SQL Equivalency Validation Results
- **Statements validated**: 7/7
- **Equivalent**: 0
- **Not Equivalent**: 0
- **Error**: 7 (tool returned ERROR with "'uniqueID'" for all statements)

### Manual Conversion Approach (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
All SQL statements were manually converted with the following rules applied:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` replaced with `INSERT...RETURNING` via writable CTEs
3. `GETDATE()` replaced with `NOW()`
4. `DECLARE @variable` / `SET @variable` patterns replaced with CTEs
5. `BEGIN TRANSACTION` / `COMMIT` patterns replaced with single-statement writable CTEs (implicit transaction)
6. Added `::numeric` casts for `ROUND()` function compatibility
7. Window functions (LAG, RANK, PERCENT_RANK, AVG, MIN, MAX, COUNT) preserved as-is (compatible)
8. CTE syntax preserved as-is (compatible)
9. CASE expressions preserved as-is (compatible)
10. BETWEEN operator preserved as-is (compatible)

## Static Code Changes

### Package Dependencies
- **Removed**: `Microsoft.Data.SqlClient` 5.1.4
- **Added**: `Npgsql` 8.0.3 (no known CVEs)

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL Equivalent |
|-----------------|---------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

### Connection String Updates
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=productmanagement;Username=postgres;Password=postgres`

### Parameter mapping in reader
- Column names updated to lowercase to match PostgreSQL schema (e.g., `"ProductId"` → `"productid"`)

## Files Modified
1. `DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, imports, column name references
2. `AdoCore.csproj` - Package reference replacement
3. `appsettings.json` - Connection string format update

## Files Created (Artifacts)
1. `extracted_statements.sql` - Catalog of all original MS SQL statements
2. `converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report
