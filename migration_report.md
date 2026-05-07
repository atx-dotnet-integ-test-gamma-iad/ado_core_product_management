# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using Npgsql as the ADO.NET data provider.

## SQL Statement Conversion Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

## DMS Tool Results

All 7 statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

As per the transformation guidelines, manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:
- All schema object names (tables, columns, views) converted to lowercase
- SQL Server-specific functions replaced with PostgreSQL equivalents

## SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a system-level error in the equivalency validation tool, not a reflection of the conversion quality.

## Key Conversions Applied

| MS SQL Server | PostgreSQL | Notes |
|---------------|-----------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | Uses RETURNING clause to get inserted ID |
| `GETDATE()` | `NOW()` | PostgreSQL current timestamp function |
| `DECLARE @var` / `SET @var` | C# variables + separate queries | Transaction blocks refactored to multi-command |
| `BEGIN TRANSACTION` / `COMMIT` | ADO.NET `BeginTransactionAsync()` | Transaction management at application level |
| `ROUND(int / int, 2)` | `ROUND(int::numeric / int, 2)` | Explicit cast for integer division |
| PascalCase schema objects | lowercase schema objects | PostgreSQL convention |

## Files Modified During Migration

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced, transaction handling refactored |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

## Package Changes

| Action | Package | Version |
|--------|---------|---------|
| Removed | `Microsoft.Data.SqlClient` | 5.1.4 |
| Added | `Npgsql` | 8.0.6 |

Note: Npgsql 8.0.6 was selected instead of 8.0.0 to address a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

## Build Status

Final build: **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference type warnings)

## Transformation Artifacts

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report |
| `migration_report.md` | This document |

## SQL Statements Processed

1. **GetAllProductsAsync** - CTE with AVG/COUNT window functions, CASE, ROUND
2. **GetProductByIdAsync** - CTE with LAG window function, LEFT JOIN, CASE with NULL handling
3. **InsertProductAsync** - Transaction with INSERT/RETURNING, INSERT history, UPDATE stats
4. **UpdateProductAsync** - Transaction with SELECT old values, UPDATE, INSERT history, UPDATE stats
5. **DeleteProductAsync** - Transaction with SELECT old values, INSERT history, DELETE, UPDATE stats with CASE
6. **GetProductsByPriceRangeAsync** - CTE with RANK/PERCENT_RANK, BETWEEN, CASE
7. **GetLowStockProductsAsync** - CTE with AVG/MIN/MAX window functions, CASE, ROUND with numeric cast
