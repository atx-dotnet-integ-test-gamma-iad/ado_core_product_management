# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention (DMS failure)**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failure Details
All 7 statements failed DMS conversion with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

## SQL Equivalency Tool Error Details
All 7 statement pairs returned ERROR from the equivalency tool:
- **Error**: `'uniqueID'`
- **Note**: This appears to be an internal tool error, not a statement-level issue

## Manual Conversion Approach (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
Since DMS failed, all conversions were done manually with the following rules:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` replaced with PostgreSQL `RETURNING` clause
3. `GETDATE()` replaced with `NOW()`
4. `DECLARE @var` / `BEGIN TRANSACTION` / `COMMIT` blocks replaced with writable CTEs
5. `CAST(x AS DECIMAL)` replaced with `CAST(x AS NUMERIC)` where needed
6. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) preserved as-is (standard SQL)

## Files Modified
1. `DataAccess/ProductRepository.cs` - All SQL statements converted, ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader)
2. `AdoCore.csproj` - Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.1
3. `appsettings.json` - Connection strings updated to PostgreSQL format

## Files Created
1. `extracted_statements.sql` - Catalog of all original MS SQL statements
2. `converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This file

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE + Window Functions)
- **Source**: CTE with AVG() OVER(), COUNT() OVER(), CASE, ROUND, JOIN
- **Conversion**: Direct lowercase mapping; all SQL constructs are standard SQL compatible with PostgreSQL

### Statement 2: GetProductByIdAsync (SELECT with CTE + LAG Window Function)
- **Source**: CTE with LAG() OVER(), CASE, ROUND, LEFT JOIN
- **Conversion**: Direct lowercase mapping; LAG() is standard SQL

### Statement 3: InsertProductAsync (Transaction with SCOPE_IDENTITY, GETDATE)
- **Source**: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), INSERT, UPDATE, COMMIT, SELECT
- **Conversion**: Writable CTE with RETURNING clause replaces SCOPE_IDENTITY(); NOW() replaces GETDATE()

### Statement 4: UpdateProductAsync (Transaction with DECLARE, GETDATE)
- **Source**: BEGIN TRANSACTION, DECLARE variables, SELECT INTO vars, UPDATE, INSERT, UPDATE, COMMIT
- **Conversion**: Writable CTE captures old values; NOW() replaces GETDATE()

### Statement 5: DeleteProductAsync (Transaction with DECLARE, GETDATE, CASE)
- **Source**: BEGIN TRANSACTION, DECLARE variables, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE, COMMIT
- **Conversion**: Writable CTE captures old values; NOW() replaces GETDATE()

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE + RANK, PERCENT_RANK)
- **Source**: CTE with RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE
- **Conversion**: Direct lowercase mapping; all constructs are standard SQL

### Statement 7: GetLowStockProductsAsync (SELECT with CTE + AVG/MIN/MAX OVER)
- **Source**: CTE with AVG/MIN/MAX OVER(), CASE, ROUND with integer division
- **Conversion**: Lowercase mapping + CAST(stockquantity AS NUMERIC) to avoid integer division
