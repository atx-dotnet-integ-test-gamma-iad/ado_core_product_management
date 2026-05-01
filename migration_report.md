# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration was performed systematically, converting SQL statements, updating ADO.NET dependencies, connection strings, configuration, and SQL setup scripts.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total inline SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Manually converted (DMS failure) | 7 |
| Equivalency validation: EQUIVALENT | 0 |
| Equivalency validation: NOT_EQUIVALENT | 0 |
| Equivalency validation: ERROR | 7 |
| Total files modified | 6 |

## DMS Tool Results

The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) was attempted for all 7 SQL statements. All 7 attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

Per the transformation rules, manual conversion was applied with lowercase schema object names (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Validation Results

The SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs. All 7 validations returned ERROR with the same systemic issue:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a systemic tool availability issue, not a statement-specific problem. The detailed results are in `sql_equivalency_validation_report.json`.

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements with PostgreSQL syntax; replaced SqlClient classes with Npgsql equivalents |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |
| `README.md` | Updated documentation for PostgreSQL |
| `Database/Scripts/01_InitialSetup.sql` | Converted DDL, stored procedures, and triggers to PostgreSQL syntax |
| `Scripts/01_InitialSetup.sql` | Converted DDL and stored procedures to PostgreSQL syntax |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type:** CTE with AVG/COUNT window functions
- **Changes:** Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **SQL features preserved:** CTE, window functions, CASE, ROUND, INNER JOIN

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function
- **Changes:** Lowercase schema objects
- **SQL features preserved:** CTE, LAG window function, CASE, ROUND, LEFT JOIN

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT
- **Changes:** SCOPE_IDENTITY()→RETURNING clause; GETDATE()→NOW(); Restructured to writable CTE pattern for atomic execution
- **SQL features preserved:** INSERT with RETURNING, multi-table updates in single statement

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE/UPDATE
- **Changes:** DECLARE @var→CTE subquery pattern; GETDATE()→NOW(); Lowercase schema objects
- **SQL features preserved:** Atomic multi-table operation with old value capture

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE/DELETE
- **Changes:** DECLARE @var→CTE subquery pattern; GETDATE()→NOW(); Lowercase schema objects
- **SQL features preserved:** Atomic multi-table operation with cascade history logging

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK/PERCENT_RANK
- **Changes:** Lowercase schema objects
- **SQL features preserved:** CTE, RANK, PERCENT_RANK, BETWEEN, CASE

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX window functions
- **Changes:** Lowercase schema objects; Added CAST(stockquantity AS NUMERIC) for integer division
- **SQL features preserved:** CTE, window functions, CASE, ROUND

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL Equivalent |
|-----------------|----------------------|
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (not applicable) |
| TrustServerCertificate | `True` | Removed (not applicable) |

## SQL Script Conversion Summary

### Database/Scripts/01_InitialSetup.sql
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `[nvarchar]` → `VARCHAR`
- `[varchar]` → `VARCHAR`
- `[decimal]` → `DECIMAL`
- `[int]` → `INTEGER`
- `[bit]` → `BOOLEAN`
- `[datetime]` → `TIMESTAMP`
- `GETDATE()` → `NOW()`
- `[dbo].` → removed (uses public schema)
- `GO` batch separators → removed
- `IF EXISTS (SELECT * FROM sys.objects...)` → `DROP TABLE IF EXISTS ... CASCADE`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- SQL Server trigger syntax → PostgreSQL trigger function + trigger
- `SCOPE_IDENTITY()` → `RETURNING ... INTO`
- `SYSTEM_USER` → `CURRENT_USER`
- `DEFAULT 1`/`DEFAULT 0` for bit → `DEFAULT TRUE`/`DEFAULT FALSE`

## Build Status

All builds completed successfully with 0 errors throughout the migration process.

## Remaining Considerations

1. **Equivalency Validation:** All 7 statement pairs returned ERROR from the SQL Equivalency tool due to a systemic tool issue. Manual review of the converted statements is recommended.
2. **Transaction Handling:** Transaction blocks were restructured from SQL Server's BEGIN TRANSACTION/COMMIT pattern to PostgreSQL's writable CTE pattern for atomic multi-table operations.
3. **Integer Division:** PostgreSQL performs integer division by default, so explicit CAST to NUMERIC was added where needed (Statement 7).
4. **Connection String Security:** The current connection strings use default credentials for development. Production deployments should use proper authentication mechanisms.

## Artifacts

- `extracted_statements.sql` - Original SQL Server statements catalog
- `converted_statements.sql` - Converted PostgreSQL statements catalog
- `sql_equivalency_validation_report.json` - Detailed equivalency validation results
- `migration_report.md` - This report
