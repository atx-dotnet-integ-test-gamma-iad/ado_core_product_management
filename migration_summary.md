# SQL Server to PostgreSQL Migration Summary

## Migration Overview
- **Source**: Microsoft SQL Server (Microsoft.Data.SqlClient 5.1.4)
- **Target**: PostgreSQL (Npgsql 8.0.3)
- **Source File**: DataAccess/ProductRepository.cs

## DMS Tool Results
- **Status**: ALL 7 statements FAILED conversion
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Resolution**: Manual conversion applied with lowercase schema object naming convention

## SQL Equivalency Tool Results
- **Status**: ALL 7 statement pairs returned ERROR
- **Error**: 'uniqueID' 
- **Note**: Tool-level error, not statement-level. All pairs marked as ERROR per transformation instructions.

## Statements Processed

| # | Method | Original SQL Server Feature | PostgreSQL Equivalent |
|---|--------|---------------------------|---------------------|
| 1 | GetAllProductsAsync | CTE with window functions | Same (lowercase schema) |
| 2 | GetProductByIdAsync | CTE with LAG window function | Same (lowercase schema) |
| 3 | InsertProductAsync | SCOPE_IDENTITY(), GETDATE(), DECLARE, BEGIN TRANSACTION | RETURNING, NOW(), writable CTEs |
| 4 | UpdateProductAsync | DECLARE, GETDATE(), BEGIN TRANSACTION | Writable CTEs, NOW() |
| 5 | DeleteProductAsync | DECLARE, GETDATE(), BEGIN TRANSACTION | Writable CTEs, NOW() |
| 6 | GetProductsByPriceRangeAsync | RANK(), PERCENT_RANK() | Same (lowercase schema) |
| 7 | GetLowStockProductsAsync | AVG/MIN/MAX OVER() | Same + ::numeric cast |

## Static Code Changes
- Replaced `Microsoft.Data.SqlClient` with `Npgsql` in .csproj
- Replaced `using Microsoft.Data.SqlClient` with `using Npgsql`
- Replaced `SqlConnection` with `NpgsqlConnection`
- Replaced `SqlCommand` with `NpgsqlCommand`
- Replaced `SqlDataReader` with `NpgsqlDataReader`
- Updated connection strings from SQL Server format to PostgreSQL format
- Updated column name references in reader to lowercase

## Key Conversion Patterns Applied
1. `SCOPE_IDENTITY()` → `RETURNING productid` (via writable CTE)
2. `GETDATE()` → `NOW()`
3. `DECLARE @var` + `BEGIN TRANSACTION/COMMIT` → Writable CTEs (atomic operations)
4. `Server=` → `Host=`
5. `Trusted_Connection=True` → `Username=postgres;Password=postgres`
6. Integer division: `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock`
7. All schema objects converted to lowercase for PostgreSQL compatibility
