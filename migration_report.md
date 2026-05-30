# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0
- **Statements requiring manual intervention**: 7 (all due to DMS tool failure)
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7 (tool returned ERROR for all)

## DMS Tool Failure Details
All 7 statements failed with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

## SQL Equivalency Tool Failure Details
All 7 statement pairs returned ERROR from the equivalency tool:
- **Error**: `'uniqueID'`
- **Note**: This appears to be a tool infrastructure issue, not a statement-level problem

## Manual Conversion Approach
Since DMS failed for all statements, manual conversion was applied with the following rules:
1. All schema object names converted to lowercase (PostgreSQL convention)
2. `SCOPE_IDENTITY()` replaced with PostgreSQL's `RETURNING` clause via writable CTEs
3. `GETDATE()` replaced with `NOW()`
4. `BEGIN TRANSACTION/COMMIT` blocks replaced with writable CTEs for atomicity
5. `DECLARE @var / SET @var` replaced with CTE-based data flow
6. Integer division in `ROUND()` addressed with `CAST(... AS NUMERIC)` where needed

## Files Modified
1. `DataAccess/ProductRepository.cs` - All SQL statements converted, SqlClient → Npgsql
2. `AdoCore.csproj` - Microsoft.Data.SqlClient → Npgsql package reference
3. `appsettings.json` - Connection strings updated to PostgreSQL format

## Artifacts Generated
1. `extracted_statements.sql` - Original MS SQL statements catalog
2. `converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sql_equivalency_validation_report.json` - Full equivalency validation report

## Statement Conversion Details

| # | Method | Original Feature | PostgreSQL Replacement |
|---|--------|-----------------|----------------------|
| 1 | GetAllProductsAsync | CTE, AVG/COUNT OVER, CASE, ROUND | Direct port with lowercase names |
| 2 | GetProductByIdAsync | CTE, LAG OVER, CASE, ROUND | Direct port with lowercase names |
| 3 | InsertProductAsync | DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE() | Writable CTE with RETURNING, NOW() |
| 4 | UpdateProductAsync | BEGIN TRANSACTION, DECLARE, GETDATE() | Writable CTE with RETURNING, NOW() |
| 5 | DeleteProductAsync | BEGIN TRANSACTION, DECLARE, GETDATE(), CASE | Writable CTE with RETURNING, NOW() |
| 6 | GetProductsByPriceRangeAsync | CTE, RANK/PERCENT_RANK OVER, BETWEEN | Direct port with lowercase names |
| 7 | GetLowStockProductsAsync | CTE, AVG/MIN/MAX OVER, CASE, ROUND | Direct port with lowercase + CAST for ROUND |
