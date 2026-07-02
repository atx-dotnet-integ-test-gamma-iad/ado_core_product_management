# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0
- **Statements requiring manual intervention (DMS failure)**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Status
All 7 statements were submitted to the DMS MCP tool. All failed with:
- **Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}

## SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool. All returned:
- **Status**: ERROR
- **Error**: 'uniqueID'

## Manual Conversion Rules Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
Since DMS failed for all statements, manual conversion was applied with:
1. All schema object names converted to lowercase (tables, columns, aliases)
2. SCOPE_IDENTITY() → RETURNING clause + currval()
3. GETDATE() → NOW()
4. DECIMAL(18,2) → NUMERIC(18,2)
5. BEGIN TRANSACTION/COMMIT → DO $$ BEGIN...END $$ blocks for procedural statements
6. Integer division fix: added ::NUMERIC cast for StockPercentageOfAverage calculation

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements converted, SqlClient → Npgsql
2. `sourceCode/AdoCore.csproj` - Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.3
3. `sourceCode/appsettings.json` - Connection strings updated to PostgreSQL format

## Files Created
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Detailed equivalency report

## Statements Requiring Manual Review
All 7 statements require manual review due to:
- DMS tool failure (unable to verify automated conversion)
- SQL Equivalency tool errors (unable to validate equivalency)

### Statement List
1. GetAllProductsAsync - CTE with window functions (AVG OVER, COUNT OVER)
2. GetProductByIdAsync - CTE with LAG window function
3. InsertProductAsync - Transaction with RETURNING clause (was SCOPE_IDENTITY)
4. UpdateProductAsync - Transaction with variable declarations
5. DeleteProductAsync - Transaction with CASE expression
6. GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
7. GetLowStockProductsAsync - CTE with AVG/MIN/MAX OVER
