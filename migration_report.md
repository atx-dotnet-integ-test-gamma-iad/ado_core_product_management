# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Source**: Microsoft SQL Server 2019
- **Target**: PostgreSQL 13
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Migration Date**: 2026-05-11

## DMS Tool Status
- **Status**: FAILED for all statements
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Action Taken**: Manual conversion applied with lowercase schema object names per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules

## SQL Equivalency Tool Status
- **Status**: ERROR for all statement pairs
- **Error**: 'uniqueID' (tool-level error, not related to SQL content)
- **Action Taken**: All statements marked as ERROR per tool output

## Statement Processing Summary
| # | Method | DMS Result | Equivalency Result | Conversion Notes |
|---|--------|-----------|-------------------|-----------------|
| 1 | GetAllProductsAsync | FAILED | ERROR | Lowercase schema objects |
| 2 | GetProductByIdAsync | FAILED | ERROR | Lowercase schema objects |
| 3 | InsertProductAsync | FAILED | ERROR | SCOPE_IDENTITY->RETURNING, GETDATE->NOW, Transaction->Writable CTE |
| 4 | UpdateProductAsync | FAILED | ERROR | DECLARE/SET->CTE, GETDATE->NOW, Transaction->Writable CTE |
| 5 | DeleteProductAsync | FAILED | ERROR | DECLARE/SET->CTE, GETDATE->NOW, Transaction->Writable CTE |
| 6 | GetProductsByPriceRangeAsync | FAILED | ERROR | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | FAILED | ERROR | Lowercase schema objects, added ::numeric cast |

## Statistics
- **Total SQL statements processed**: 7
- **Successfully converted by DMS**: 0
- **Manually converted (DMS failure)**: 7
- **Validated as equivalent**: 0
- **Validated as non-equivalent**: 0
- **Equivalency validation errors**: 7

## Key SQL Server to PostgreSQL Conversions Applied
1. `SCOPE_IDENTITY()` → `RETURNING productid` (with writable CTE)
2. `GETDATE()` → `NOW()`
3. `BEGIN TRANSACTION` / `COMMIT` → Writable CTE (atomic in single statement)
4. `DECLARE @variable` / `SET @variable` → CTE subqueries
5. All schema object names converted to lowercase
6. `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock` (explicit numeric cast for integer division)

## Static Code Changes
1. **Package**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.0`
2. **Connection Class**: `SqlConnection` → `NpgsqlConnection`
3. **Command Class**: `SqlCommand` → `NpgsqlCommand`
4. **Reader Class**: `SqlDataReader` → `NpgsqlDataReader`
5. **Namespace**: `using Microsoft.Data.SqlClient` → `using Npgsql`
6. **Connection Strings**: SQL Server format → PostgreSQL format
   - `Server=` → `Host=`
   - `Database=ProductManagement` → `Database=productmanagement`
   - `Trusted_Connection=True` → `Username=postgres;Password=postgres`
   - Removed `MultipleActiveResultSets=true` (not needed in PostgreSQL)
   - Removed `TrustServerCertificate=True` (SQL Server specific)

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements and ADO.NET classes
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings

## Artifacts Generated
1. `sourceCode/extracted_statements.sql` - All original SQL Server statements
2. `sourceCode/converted_statements.sql` - All converted PostgreSQL statements
3. `sourceCode/sql_equivalency_validation_report.json` - Equivalency validation results
4. `sourceCode/migration_report.md` - This report
