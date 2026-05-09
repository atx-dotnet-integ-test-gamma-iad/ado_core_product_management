# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Source Database**: Microsoft SQL Server (via Microsoft.Data.SqlClient 5.1.4)
- **Target Database**: PostgreSQL (via Npgsql 8.0.1)
- **Source File**: sourceCode/DataAccess/ProductRepository.cs
- **Total SQL Statements**: 7

## DMS Tool Results
- **Tool Status**: FAILED for all 7 statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method Used**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## SQL Equivalency Tool Results
- **Tool Status**: ERROR for all 7 statements
- **Error**: `'uniqueID'`
- **All statement pairs marked as**: ERROR (per transformation instructions)

## Statement Conversion Details

| # | Method | Source Location | SQL Server Feature | PostgreSQL Equivalent |
|---|--------|----------------|-------------------|---------------------|
| 1 | GetAllProductsAsync | Line ~40 | CTE with window functions | Direct translation (lowercase) |
| 2 | GetProductByIdAsync | Line ~78 | CTE with LAG() | Direct translation (lowercase) |
| 3 | InsertProductAsync | Line ~107 | SCOPE_IDENTITY(), GETDATE(), explicit transaction | RETURNING clause with CTE, NOW() |
| 4 | UpdateProductAsync | Line ~137 | DECLARE/SET variables, GETDATE(), explicit transaction | DO $$ block with PL/pgSQL, NOW() |
| 5 | DeleteProductAsync | Line ~175 | DECLARE/SET variables, GETDATE(), explicit transaction | DO $$ block with PL/pgSQL, NOW() |
| 6 | GetProductsByPriceRangeAsync | Line ~210 | CTE with RANK(), PERCENT_RANK() | Direct translation (lowercase) |
| 7 | GetLowStockProductsAsync | Line ~240 | CTE with AVG/MIN/MAX, ROUND with integer division | Direct translation (lowercase) + ::numeric cast |

## Key Conversion Rules Applied
1. **All schema object names converted to lowercase** (tables, columns, aliases, CTEs)
2. **SCOPE_IDENTITY()** → `RETURNING productid` via CTE
3. **GETDATE()** → `NOW()`
4. **DECLARE @var / SET @var** → PL/pgSQL `DO $$ DECLARE ... BEGIN ... END $$`
5. **BEGIN TRANSACTION / COMMIT** → Either CTE (for insert) or DO $$ block (for update/delete)
6. **Integer division** → Added `::numeric` cast where needed (Statement 7)
7. **NVARCHAR(MAX)** → `TEXT`
8. **NVARCHAR(n)** → `VARCHAR(n)`
9. **INT IDENTITY(1,1)** → `SERIAL`
10. **DATETIME** → `TIMESTAMP`

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
- `Server=localhost` → `Host=localhost`
- `Database=ProductManagement` → `Database=productmanagement`
- `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Username=postgres;Password=postgres`

### Column Name References in Reader (ProductRepository.cs - MapProductFromReader)
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, reader column names
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings

## Artifacts Created
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Equivalency validation report
4. `sourceCode/migration_report.md` - This report
