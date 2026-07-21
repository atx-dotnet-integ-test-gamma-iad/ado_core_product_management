# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with:
- **Error**: AccessDeniedException - User is not authorized to perform dms:StartMetadataModelCreation
- **Reason**: The execution role does not have the required IAM permissions for DMS operations

## Manual Conversion Approach
Due to DMS failure, all statements were manually converted applying:
- Lowercase schema object names (tables, columns, CTEs, aliases) for PostgreSQL compatibility
- `SCOPE_IDENTITY()` → `RETURNING productid`
- `GETDATE()` → `NOW()`
- `DECLARE @variable` + `SET @variable` → C# ADO.NET variables with separate queries
- SQL Server inline `BEGIN TRANSACTION`/`COMMIT` → Npgsql `BeginTransactionAsync()`/`CommitAsync()`
- Integer division fix: `CAST(stockquantity AS NUMERIC)` for proper decimal division

## SQL Equivalency Validation Status
All 7 statement pairs were submitted to the SQL Equivalency MCP tool. All returned ERROR with:
- **Error**: `'uniqueID'`
- **Assessment**: Systemic tool configuration issue preventing validation

## Files Modified
1. `DataAccess/ProductRepository.cs` - All SQL statements converted, all ADO.NET types migrated
2. `AdoCore.csproj` - Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.3
3. `appsettings.json` - Connection strings updated to PostgreSQL format

## Files Created
1. `extracted_statements.sql` - Catalog of all original MS SQL statements
2. `converted_statements.sql` - Catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report

## Statement Conversion Details

| # | Method | Source | SQL Server Feature | PostgreSQL Equivalent |
|---|--------|--------|-------------------|---------------------|
| 1 | GetAllProductsAsync | SELECT with CTE, OVER() | Direct equivalent (lowercase) |
| 2 | GetProductByIdAsync | SELECT with LAG() OVER | Direct equivalent (lowercase) |
| 3 | InsertProductAsync | SCOPE_IDENTITY(), GETDATE(), inline transaction | RETURNING, NOW(), ADO.NET transaction |
| 4 | UpdateProductAsync | DECLARE @var, GETDATE(), inline transaction | Separate SELECT, NOW(), ADO.NET transaction |
| 5 | DeleteProductAsync | DECLARE @var, GETDATE(), inline transaction | Separate SELECT, NOW(), ADO.NET transaction |
| 6 | GetProductsByPriceRangeAsync | RANK(), PERCENT_RANK(), BETWEEN | Direct equivalent (lowercase) |
| 7 | GetLowStockProductsAsync | AVG/MIN/MAX OVER(), integer division | CAST AS NUMERIC for division (lowercase) |

## Static Code Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Server=localhost` | `Host=localhost` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | (removed - not needed for PostgreSQL) |
| `TrustServerCertificate=True` | (removed - not needed for PostgreSQL) |
