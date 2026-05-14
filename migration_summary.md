# SQL Server to PostgreSQL Migration Summary

## Migration Overview
- **Project**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Method**: Manual conversion (DMS tool unavailable)

## DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All calls failed with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback**: Manual conversion with lowercase schema mapping (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

## SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency validation tool. All returned ERROR:
- **Error**: `'uniqueID'`
- **Status**: All 7 pairs marked as ERROR per tool output

## Statements Processed

| # | Method | Source Location | Conversion Notes |
|---|--------|----------------|------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | CTE with AVG/COUNT OVER - direct lowercase mapping |
| 2 | GetProductByIdAsync | ProductRepository.cs | CTE with LAG - direct lowercase mapping |
| 3 | InsertProductAsync | ProductRepository.cs | SCOPE_IDENTITY() → RETURNING via writable CTE; GETDATE() → NOW() |
| 4 | UpdateProductAsync | ProductRepository.cs | DECLARE/SET → CTE old_values; GETDATE() → NOW(); writable CTE |
| 5 | DeleteProductAsync | ProductRepository.cs | DECLARE/SET → CTE old_values; GETDATE() → NOW(); writable CTE |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | CTE with RANK/PERCENT_RANK - direct lowercase mapping |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | CTE with AVG/MIN/MAX OVER - added CAST for numeric division |

## Key Conversion Patterns Applied
1. **Schema Objects**: All table/column names converted to lowercase
2. **GETDATE()** → **NOW()**
3. **SCOPE_IDENTITY()** → **INSERT ... RETURNING** via writable CTEs
4. **DECLARE @var / SET @var** → **CTE-based value capture**
5. **BEGIN TRANSACTION / COMMIT** → **Writable CTEs** (atomic single statement)
6. **Integer Division** → **CAST(col AS NUMERIC)** where needed

## Static Code Changes
1. **Package**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.1`
2. **Classes**: `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, `SqlDataReader` → `NpgsqlDataReader`, `SqlParameter` → `NpgsqlParameter`
3. **Namespace**: `using Microsoft.Data.SqlClient` → `using Npgsql`
4. **Connection Strings**: SQL Server format → PostgreSQL format (Host, Username, Password)

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL + ADO.NET class replacements
2. `sourceCode/AdoCore.csproj` - Package reference update
3. `sourceCode/appsettings.json` - Connection string update

## Artifacts Created
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Equivalency validation report
4. `sourceCode/migration_summary.md` - This file

## Statistics
- Total SQL statements processed: 7
- DMS conversions successful: 0
- DMS conversions failed: 7
- Manual conversions performed: 7
- Equivalency validations: 7 (all ERROR due to tool issue)
- Equivalency confirmed: 0
- Equivalency denied: 0
- Equivalency errors: 7
