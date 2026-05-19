# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Status
All 7 statements were passed to the DMS MCP tool for conversion. All failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using lowercase schema object naming convention for PostgreSQL compatibility (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Status
All 7 statement pairs were passed to the SQL Equivalency validation tool. All returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

## Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE + Window Functions)
- **Source**: ProductRepository.cs, GetAllProductsAsync method
- **Conversion**: Lowercase schema objects (Products → products, ProductId → productid, etc.)
- **SQL features preserved**: CTE, AVG() OVER(), COUNT() OVER(), CASE expression, ROUND()

### Statement 2: GetProductByIdAsync (SELECT with CTE + LAG)
- **Source**: ProductRepository.cs, GetProductByIdAsync method
- **Conversion**: Lowercase schema objects
- **SQL features preserved**: CTE, LAG() window function, CASE expression, ROUND()

### Statement 3: InsertProductAsync (Transaction with INSERT + SCOPE_IDENTITY)
- **Source**: ProductRepository.cs, InsertProductAsync method
- **Conversion**: Restructured from DECLARE/BEGIN TRANSACTION/SCOPE_IDENTITY to writable CTE with RETURNING clause
- **Key changes**: SCOPE_IDENTITY() → INSERT...RETURNING, GETDATE() → NOW(), BEGIN/COMMIT → atomic CTE

### Statement 4: UpdateProductAsync (Transaction with UPDATE)
- **Source**: ProductRepository.cs, UpdateProductAsync method
- **Conversion**: Restructured from DECLARE/BEGIN TRANSACTION to writable CTE
- **Key changes**: DECLARE @var/SELECT INTO → CTE subquery, GETDATE() → NOW()

### Statement 5: DeleteProductAsync (Transaction with DELETE)
- **Source**: ProductRepository.cs, DeleteProductAsync method
- **Conversion**: Restructured from DECLARE/BEGIN TRANSACTION to writable CTE
- **Key changes**: DECLARE @var/SELECT INTO → CTE subquery, GETDATE() → NOW()

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE + RANK/PERCENT_RANK)
- **Source**: ProductRepository.cs, GetProductsByPriceRangeAsync method
- **Conversion**: Lowercase schema objects
- **SQL features preserved**: CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE expression

### Statement 7: GetLowStockProductsAsync (SELECT with CTE + AVG/MIN/MAX OVER)
- **Source**: ProductRepository.cs, GetLowStockProductsAsync method
- **Conversion**: Lowercase schema objects, CAST(x AS DECIMAL) → x::numeric
- **SQL features preserved**: CTE, AVG/MIN/MAX OVER(), CASE expression, ROUND()

## Static Code Changes

### Package References (AdoCore.csproj)
- Removed: `Microsoft.Data.SqlClient` 5.1.4
- Added: `Npgsql` 8.0.1

### ADO.NET Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String (appsettings.json)
- Replaced `Server=localhost` with `Host=localhost`
- Removed `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- Added `Username=postgres;Password=postgres`

### Column Name References in MapProductFromReader
- Updated reader index names to lowercase: `ProductId` → `productid`, `Name` → `name`, etc.

## Artifacts
- `extracted_statements.sql` - All original MS SQL statements
- `converted_statements.sql` - All converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
