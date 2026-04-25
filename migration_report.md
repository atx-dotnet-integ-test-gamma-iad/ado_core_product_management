# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using Npgsql as the database driver.

## Migration Date
2026-04-25

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, SqlClient classes replaced with Npgsql, import updated |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.0 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL Npgsql format |

## Files Created (Artifacts)

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 7 statement pairs |
| `migration_report.md` | This report |

## SQL Statement Conversion

### Overview
- **Total SQL statements processed**: 7
- **Statements converted by DMS tool**: 0 (DMS tool failed for all statements)
- **Statements requiring manual intervention**: 7

### DMS Tool Results
The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) was called for all 7 statements. All calls failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) was used successfully to retrieve the target PostgreSQL schema mappings, which guided the manual conversion.

### Schema Mappings from DMS

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `products` (lowercase columns) |
| `dbo.ProductHistory` | `producthistory` (lowercase columns) |
| `dbo.ProductStats` | `productstats` (lowercase columns) |

### Statement Conversion Details

| # | Method | Conversion Method | Key Changes |
|---|--------|-------------------|-------------|
| 1 | `GetAllProductsAsync` | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | CTE/table/column names lowercased |
| 2 | `GetProductByIdAsync` | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | CTE/table/column names lowercased |
| 3 | `InsertProductAsync` | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | SCOPE_IDENTITY() → lastval(), GETDATE() → clock_timestamp(), DECLARE removed, BEGIN TRANSACTION → BEGIN |
| 4 | `UpdateProductAsync` | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Restructured to capture old values via subquery before update, GETDATE() → clock_timestamp() |
| 5 | `DeleteProductAsync` | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Restructured to capture old values via subquery before delete, GETDATE() → clock_timestamp() |
| 6 | `GetProductsByPriceRangeAsync` | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | CTE/table/column names lowercased |
| 7 | `GetLowStockProductsAsync` | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | CTE/table/column names lowercased, added ::numeric cast |

### SQL Syntax Conversion Rules Applied

| SQL Server | PostgreSQL | Notes |
|-----------|-----------|-------|
| `SCOPE_IDENTITY()` | `lastval()` | Returns last generated identity value |
| `GETDATE()` | `clock_timestamp()` | Per DMS schema mapping defaults |
| `BEGIN TRANSACTION` | `BEGIN` | PostgreSQL transaction syntax |
| `DECLARE @var` / `SET @var` | Subqueries | Restructured to avoid T-SQL variables |
| `ROUND(expr, 2)` | `ROUND(expr, 2)` | Compatible, added ::numeric cast where needed |
| Table/column names | Lowercase | Per DMS schema mapping |

## SQL Equivalency Validation

### Overview
- **Statements validated**: 7
- **Equivalent**: 0
- **Non-equivalent**: 0
- **Errors**: 7

### Details
All 7 statement pairs were validated through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with error message `'uniqueID'`. This appears to be an infrastructure issue with the equivalency tool rather than an issue with the SQL conversions themselves.

**Note**: All equivalency statuses come exclusively from the tool output. No agent judgment was used to determine equivalency.

## Package Dependency Changes

| Original | Replacement |
|----------|------------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.0 |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|-------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per query method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres
```

### Parameters Mapping

| SQL Server Parameter | PostgreSQL Parameter | Notes |
|---------------------|---------------------|-------|
| `Server=localhost` | `Host=localhost` | Renamed |
| `Database=ProductManagement` | `Database=postgres` | Per target DB from qtransform-generated-input.json |
| `Trusted_Connection=True` | Removed | Not applicable to PostgreSQL |
| `MultipleActiveResultSets=true` | Removed | Not applicable to PostgreSQL |
| `TrustServerCertificate=True` | Removed | Not applicable to PostgreSQL |
| N/A | `Port=5432` | PostgreSQL default port |
| N/A | `Username=postgres` | PostgreSQL authentication (placeholder) |
| N/A | `Password=postgres` | PostgreSQL authentication (placeholder) |

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure for conversion (manual conversion applied)
2. SQL Equivalency tool returning ERROR for all validation attempts

### Priority Review Items
- **Statements 3, 4, 5** (InsertProductAsync, UpdateProductAsync, DeleteProductAsync): These transaction blocks were restructured to eliminate T-SQL DECLARE variables. The operation order was modified to capture old values before updates/deletes via subqueries. Verify functional equivalence manually.
- **Statement 7** (GetLowStockProductsAsync): Added `::numeric` cast for integer division to ensure proper ROUND behavior in PostgreSQL.

## Build Status
The application compiles successfully after all changes:
- **Build result**: Success
- **Errors**: 0
- **Warnings**: 12 (pre-existing nullable reference warnings, not related to migration)

## Database Setup Scripts
The SQL Server setup scripts (`Scripts/01_InitialSetup.sql` and `Database/Scripts/01_InitialSetup.sql`) remain as SQL Server syntax. They are setup scripts (not runtime code) and would need separate PostgreSQL equivalents for database initialization.
