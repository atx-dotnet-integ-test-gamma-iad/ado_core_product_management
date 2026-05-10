# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Application Framework**: .NET 9.0 / ADO.NET
- **Migration Method**: Manual conversion due to DMS tool failure

## DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool for conversion.
All 7 statements FAILED with the following error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules.

## SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency MCP tool for validation.
All 7 validations returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

## Statements Processed

| # | Method | Location | Description | DMS Status | Equivalency Status |
|---|--------|----------|-------------|------------|-------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs:39 | CTE with window functions, CASE, ROUND | FAILED | ERROR |
| 2 | GetProductByIdAsync | ProductRepository.cs:79 | CTE with LAG() window function | FAILED | ERROR |
| 3 | InsertProductAsync | ProductRepository.cs:112 | Transaction with SCOPE_IDENTITY(), GETDATE() | FAILED | ERROR |
| 4 | UpdateProductAsync | ProductRepository.cs:141 | Transaction with DECLARE, UPDATE, INSERT | FAILED | ERROR |
| 5 | DeleteProductAsync | ProductRepository.cs:178 | Transaction with DECLARE, DELETE, CASE | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs:214 | CTE with RANK(), PERCENT_RANK() | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | ProductRepository.cs:244 | CTE with AVG/MIN/MAX OVER(), CASE | FAILED | ERROR |

## Key SQL Conversions Applied

| SQL Server Feature | PostgreSQL Equivalent |
|-------------------|---------------------|
| SCOPE_IDENTITY() | RETURNING clause |
| GETDATE() | NOW() |
| DECLARE @var / SET @var | Application-level variables via NpgsqlDataReader |
| BEGIN TRANSACTION/COMMIT (inline SQL) | NpgsqlTransaction (application-managed) |
| Integer division in ROUND() | ::numeric cast for proper decimal division |
| Schema object names (PascalCase) | Lowercase identifiers |

## Code Changes Applied

### Package References (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` v5.1.4
- **Added**: `Npgsql` v8.0.1

### Namespace Changes (ProductRepository.cs)
- **Removed**: `using Microsoft.Data.SqlClient;`
- **Added**: `using Npgsql;`

### Class Replacements (ProductRepository.cs)
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter` (via AddWithValue)

### Connection String (appsettings.json)
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Transaction Handling Changes
- Inline `BEGIN TRANSACTION`/`COMMIT` blocks in SQL strings were replaced with application-managed `NpgsqlTransaction` objects
- `DECLARE @var` patterns were replaced with application-level variable management using separate SELECT queries
- This maintains atomicity while using PostgreSQL-compatible patterns

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - Main data access code
2. `sourceCode/AdoCore.csproj` - Package references
3. `sourceCode/appsettings.json` - Connection strings

## Artifacts Created
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Equivalency validation report
4. `sourceCode/migration_report.md` - This report
