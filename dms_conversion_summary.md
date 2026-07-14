# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0
- **Statements requiring manual intervention**: 7 (all due to DMS metadata model creation failure)
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7 (all returned ERROR with "'uniqueID'" error)

## DMS Tool Failure Details
All 7 statements failed with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **Resolution**: Manual conversion applied with lowercase schema object names per transformation rules (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

## SQL Equivalency Tool Results
All 7 statement pairs returned ERROR from the sql-equivalency tool:
- **Error**: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
- **Note**: Per transformation rules, these are marked as ERROR status (not agent-determined)

## Key Conversion Changes Applied
1. **Schema objects**: All table names, column names, aliases converted to lowercase
2. **SCOPE_IDENTITY()** -> `RETURNING productid` clause
3. **GETDATE()** -> `NOW()`
4. **BEGIN TRANSACTION / COMMIT** -> Managed via NpgsqlTransaction in C# (not inline SQL)
5. **DECLARE @var / SET @var** -> Separate queries with C# variables
6. **Integer division** -> Added `::numeric` cast where needed (StockQuantity/AvgStock)
7. **SqlConnection** -> `NpgsqlConnection`
8. **SqlCommand** -> `NpgsqlCommand`
9. **SqlDataReader** -> `NpgsqlDataReader`
10. **SqlParameter** -> `NpgsqlParameter`
11. **Microsoft.Data.SqlClient** -> `Npgsql` (package reference)
12. **Connection string**: SQL Server format -> PostgreSQL format (Host, Username, Password)

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL and ADO.NET code converted
2. `sourceCode/AdoCore.csproj` - Package reference updated
3. `sourceCode/appsettings.json` - Connection strings updated to PostgreSQL format

## Artifacts Generated
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Full equivalency validation report
4. `sourceCode/dms_conversion_summary.md` - This file

## Statements Requiring Manual Review
All 7 statements require manual review due to:
1. DMS tool failure (metadata model creation timeout)
2. SQL Equivalency tool returning ERROR for all pairs

| # | Method | Original T-SQL Features | PostgreSQL Conversion |
|---|--------|------------------------|----------------------|
| 1 | GetAllProductsAsync | CTE, AVG/COUNT OVER(), ROUND | Lowercase schema objects |
| 2 | GetProductByIdAsync | CTE, LAG() OVER(), LEFT JOIN | Lowercase schema objects |
| 3 | InsertProductAsync | SCOPE_IDENTITY(), GETDATE(), Transaction | RETURNING, NOW(), NpgsqlTransaction |
| 4 | UpdateProductAsync | DECLARE, GETDATE(), Transaction | Separate queries, NOW(), NpgsqlTransaction |
| 5 | DeleteProductAsync | DECLARE, GETDATE(), CASE, Transaction | Separate queries, NOW(), NpgsqlTransaction |
| 6 | GetProductsByPriceRangeAsync | CTE, RANK(), PERCENT_RANK(), BETWEEN | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | CTE, AVG/MIN/MAX OVER(), ROUND | ::numeric cast, lowercase |
