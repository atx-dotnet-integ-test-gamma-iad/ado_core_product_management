# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0
- **Statements requiring manual intervention (DMS failure)**: 7
- **DMS Failure Reason**: Database connectivity issues (could not connect to source at 172.31.83.165:1433)

## Equivalency Validation Results
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0  
- **Statements with equivalency validation errors**: 7
- **Equivalency Tool Error**: "'uniqueID'" (tool-side error for all 7 statements)

## Conversion Details

All 7 statements were passed through the DMS MCP tool as required. All failed due to database connectivity issues.
Manual conversion was performed using lowercase schema object naming convention per the transformation definition rules.

### Key Conversions Applied:
1. `SCOPE_IDENTITY()` → `lastval()`
2. `GETDATE()` → `NOW()`
3. `BEGIN TRANSACTION` / `COMMIT` → `BEGIN` / `COMMIT`
4. All schema object names (tables, columns, aliases) converted to lowercase
5. T-SQL variable declarations (`DECLARE @var`) replaced with PostgreSQL-compatible patterns using subqueries
6. Integer division casting added where needed (`::numeric`)

## Static Code Changes
1. **Package**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.3`
2. **Classes replaced**:
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` → `NpgsqlParameter`
3. **Imports**: `using Microsoft.Data.SqlClient` → `using Npgsql`
4. **Connection strings**: Updated from SQL Server format to PostgreSQL format
   - `Server=` → `Host=`
   - `Trusted_Connection=True` → `Username=postgres;Password=postgres`
   - Removed `MultipleActiveResultSets` and `TrustServerCertificate` (SQL Server specific)

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, imports
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings

## Artifacts Generated
1. `extracted_statements.sql` - Original MS SQL statements catalog
2. `converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency report
4. `migration_report.md` - This file
