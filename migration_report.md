# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failure
All 7 statements were passed to the DMS MCP tool (dms-mcp___statement_conversion_tool) but all failed with:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using the rule: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## SQL Equivalency Tool Results
All 7 statement pairs were passed to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) but all returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

## Conversion Rules Applied (Manual)
1. All schema object names (tables, columns, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` replaced with PostgreSQL `RETURNING` clause via writable CTEs
3. `GETDATE()` replaced with `NOW()`
4. `BEGIN TRANSACTION`/`COMMIT` blocks with `DECLARE` variables replaced with writable CTEs
5. Integer division in `ROUND()` addressed with `CAST(... AS DECIMAL)`
6. CTE named `ProductHistory` renamed to `producthistory_cte` to avoid collision with table name `producthistory`

## Static Code Changes
1. **Package**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.1`
2. **Import**: `using Microsoft.Data.SqlClient` → `using Npgsql`
3. **Classes replaced**:
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` (via AddWithValue) → `NpgsqlParameter` (via AddWithValue)
4. **Connection strings**: Updated from SQL Server format to PostgreSQL format
   - `Server=localhost` → `Host=localhost`
   - `Trusted_Connection=True` → `Username=postgres;Password=postgres`
   - Removed `MultipleActiveResultSets=true` and `TrustServerCertificate=True`

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements and ADO.NET classes
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings

## Artifacts Created
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Full equivalency validation report
4. `sourceCode/migration_report.md` - This report
