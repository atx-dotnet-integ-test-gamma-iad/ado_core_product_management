# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0
- **Statements requiring manual conversion (DMS failure)**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Status
All 7 DMS conversion attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

All statements were manually converted applying lowercase schema object naming conventions per the transformation definition rule: "DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA".

## SQL Equivalency Tool Status
All 7 equivalency validation attempts returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This appears to be a tool infrastructure issue unrelated to the SQL statements themselves. Per the transformation definition, these are marked as ERROR in the report.

## Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE + Window Functions)
- **Changes**: Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **SQL Features**: CTE, AVG/COUNT OVER(), CASE, INNER JOIN, ROUND - all natively supported in PostgreSQL

### Statement 2: GetProductByIdAsync (SELECT with CTE + LAG)
- **Changes**: Lowercase schema objects
- **SQL Features**: CTE, LAG() OVER(), LEFT JOIN, CASE, ROUND - all natively supported in PostgreSQL

### Statement 3: InsertProductAsync (Multi-statement Transaction)
- **Changes**: 
  - Replaced DECLARE @var / SCOPE_IDENTITY() with PostgreSQL writable CTE + RETURNING clause
  - Replaced GETDATE() with NOW()
  - Replaced BEGIN TRANSACTION/COMMIT with atomic writable CTE (inherently transactional)
  - Lowercase schema objects

### Statement 4: UpdateProductAsync (Multi-statement Transaction)
- **Changes**:
  - Replaced DECLARE @var with CTE subquery (old_values)
  - Replaced GETDATE() with NOW()
  - Replaced BEGIN TRANSACTION/COMMIT with writable CTE (inherently transactional)
  - Lowercase schema objects

### Statement 5: DeleteProductAsync (Multi-statement Transaction)
- **Changes**:
  - Replaced DECLARE @var with CTE subquery (old_values)
  - Replaced GETDATE() with NOW()
  - Replaced BEGIN TRANSACTION/COMMIT with writable CTE (inherently transactional)
  - Lowercase schema objects

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE + RANK/PERCENT_RANK)
- **Changes**: Lowercase schema objects
- **SQL Features**: CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE - all natively supported in PostgreSQL

### Statement 7: GetLowStockProductsAsync (SELECT with CTE + Window Aggregates)
- **Changes**: 
  - Lowercase schema objects
  - Added CAST(stockquantity AS NUMERIC) for proper division behavior in PostgreSQL
- **SQL Features**: CTE, AVG/MIN/MAX OVER(), CASE, ROUND - all natively supported in PostgreSQL

## Static Code Changes

### Package References (AdoCore.csproj)
- Removed: `Microsoft.Data.SqlClient` Version 5.1.4
- Added: `Npgsql` Version 8.0.1

### ADO.NET Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String (appsettings.json)
- Replaced `Server=localhost` with `Host=localhost`
- Replaced `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` with `Username=postgres;Password=postgres`

## Artifacts Generated
1. `extracted_statements.sql` - Original MS SQL statements catalog
2. `converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report
