# SQL Server to PostgreSQL Migration Report

## Migration Summary
- **Source Database**: SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13
- **Migration Tool**: AWS DMS (attempted) + Manual Conversion
- **DMS Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## DMS Tool Status
- **Status**: FAILED for all statements
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **All 7 SQL statements were submitted to DMS but all failed with the same error**

## SQL Statement Processing Summary
| # | Method | Source | Statement Type | DMS Status | Manual Conversion |
|---|--------|--------|----------------|------------|-------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | SELECT with CTE + Window Functions | FAILED | YES - Lowercase schema |
| 2 | GetProductByIdAsync | ProductRepository.cs | SELECT with CTE + LAG Window Function | FAILED | YES - Lowercase schema |
| 3 | InsertProductAsync | ProductRepository.cs | Transaction: INSERT + SCOPE_IDENTITY + INSERT + UPDATE | FAILED | YES - DO block + RETURNING + NOW() |
| 4 | UpdateProductAsync | ProductRepository.cs | Transaction: SELECT INTO vars + UPDATE + INSERT + UPDATE | FAILED | YES - DO block + SELECT INTO + NOW() |
| 5 | DeleteProductAsync | ProductRepository.cs | Transaction: SELECT INTO vars + INSERT + DELETE + UPDATE | FAILED | YES - DO block + SELECT INTO + NOW() |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | SELECT with CTE + RANK/PERCENT_RANK | FAILED | YES - Lowercase schema |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | SELECT with CTE + AVG/MIN/MAX Window Functions | FAILED | YES - Lowercase schema + ::numeric cast |

## Conversion Rules Applied (Manual - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
1. All schema object names converted to lowercase (tables, columns, aliases)
2. `SCOPE_IDENTITY()` → `RETURNING productid INTO variable` + `currval(pg_get_serial_sequence(...))`
3. `GETDATE()` → `NOW()`
4. `DECLARE @var` / `SET @var` → PostgreSQL `DO $$ DECLARE ... BEGIN ... END $$` block
5. `BEGIN TRANSACTION / COMMIT` → Handled within `DO $$` block (implicit transaction)
6. `SELECT @var = col` → `SELECT col INTO var`
7. Integer division fix: `stockquantity::numeric / avgstock` for proper decimal division

## SQL Equivalency Validation Summary
- **Tool Used**: sql-equivalency___validate_sql_equivalence
- **Total Statements Validated**: 7
- **Equivalent**: 0
- **Not Equivalent**: 0
- **Error**: 7 (all returned ERROR with "'uniqueID'" error)
- **Note**: The SQL Equivalency tool returned errors for all statement pairs. Per transformation instructions, these are marked as ERROR status.

## Static Code Changes

### Package Dependencies
- **Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Added**: `Npgsql` Version 8.0.0

### Namespace/Import Changes
- `using Microsoft.Data.SqlClient` → `using Npgsql`

### Class Replacements
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Changes
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### Parameter Syntax
- Parameters kept using `@ParameterName` syntax (supported by Npgsql)
- `command.Parameters.AddWithValue` retained (supported by Npgsql)

### Column Name References in Reader
- All column name references in `reader["ColumnName"]` converted to lowercase to match PostgreSQL schema

## Files Modified
1. `DataAccess/ProductRepository.cs` - Main database access file (all SQL + ADO.NET classes)
2. `AdoCore.csproj` - Package reference update
3. `appsettings.json` - Connection string format update

## Artifacts Generated
1. `extracted_statements.sql` - All original MS SQL statements extracted from code
2. `converted_statements.sql` - All converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This file
