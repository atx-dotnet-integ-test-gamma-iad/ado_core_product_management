# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

## DMS Tool Usage Summary

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements. Every attempt failed with the same error:

```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
```

Multiple retry strategies were attempted:
- Default settings (15 poll attempts, 10s interval)
- Increased settings (30 poll attempts, 15s interval) - timed out after 300s
- Simplified test statement - same metadata model creation failure

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was successfully used to retrieve the target schema information for all 3 tables, confirming the migration project ARN and DMS service were available. The schema mappings were used to guide manual conversion.

### DMS Schema Mappings Retrieved

| Source Table | Target Table | Target Schema |
|-------------|-------------|---------------|
| dbo.Products | products | productmanagement_dbo |
| dbo.ProductHistory | producthistory | productmanagement_dbo |
| dbo.ProductStats | productstats | productmanagement_dbo |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Failure Reason**: Metadata model creation timeout
- **Changes**: Table/column names lowercased per DMS schema mapping
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 2: GetProductByIdAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Failure Reason**: Metadata model creation timeout
- **Changes**: Table/column names lowercased; LAG window functions compatible in PostgreSQL
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 3: InsertProductAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Failure Reason**: Metadata model creation timeout
- **Changes**: SCOPE_IDENTITY() → RETURNING clause with writable CTEs; GETDATE() → clock_timestamp(); DECLARE/SET → writable CTEs; BEGIN TRANSACTION/COMMIT → removed (app layer)
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 4: UpdateProductAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Failure Reason**: Metadata model creation timeout
- **Changes**: DECLARE/SET → writable CTEs with old_values CTE; GETDATE() → clock_timestamp(); BEGIN TRANSACTION/COMMIT → removed (app layer)
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 5: DeleteProductAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Failure Reason**: Metadata model creation timeout
- **Changes**: DECLARE/SET → writable CTEs; GETDATE() → clock_timestamp(); CASE expression preserved; BEGIN TRANSACTION/COMMIT → removed (app layer)
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Failure Reason**: Metadata model creation timeout
- **Changes**: Table/column names lowercased; RANK() and PERCENT_RANK() compatible in PostgreSQL
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

### Statement 7: GetLowStockProductsAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Failure Reason**: Metadata model creation timeout
- **Changes**: Table/column names lowercased; Added ::numeric cast for integer division in ROUND(); AVG/MIN/MAX OVER compatible
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

## SQL Equivalency Tool Results

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs. Every call returned an ERROR status with `'uniqueID'` as the error message. This appears to be a systemic issue with the tool, not related to the quality of the conversions.

Per the transformation definition requirements, all 7 statements are marked as ERROR in the equivalency report. No agent judgment was used to determine equivalency.

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced `SqlConnection`→`NpgsqlConnection`, `SqlCommand`→`NpgsqlCommand`, `SqlDataReader`→`NpgsqlDataReader`; updated `using Microsoft.Data.SqlClient`→`using Npgsql`; updated column name references to lowercase |
| `appsettings.json` | Converted SQL Server connection strings to PostgreSQL format (`Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`) |

## Files Unchanged

| File | Reason |
|------|--------|
| `Program.cs` | No SQL Server references |
| `Business/ProductService.cs` | No SQL Server references |
| `Models/Product.cs` | No SQL Server references |
| `CLI/CommandLineInterface.cs` | No SQL Server references |
| `CLI/InteractiveMenu.cs` | No SQL Server references |
| `Scripts/01_InitialSetup.sql` | Database setup script - requires separate database-level migration |
| `Database/Scripts/01_InitialSetup.sql` | Database setup script - requires separate database-level migration |

## SQL Scripts Status

The SQL setup scripts (`Scripts/01_InitialSetup.sql` and `Database/Scripts/01_InitialSetup.sql`) contain SQL Server-specific DDL, stored procedures, triggers, and sample data. These are database setup scripts that should be converted as part of the database migration process (separate from the application code migration). They were not modified as part of this application-level migration since:
1. They are not executed by the application at runtime
2. The DMS migration project handles schema conversion at the database level
3. Converting them would require a separate database migration workflow

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Project root | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Detailed equivalency report with all 7 statement pairs |

## Build Status

**Final build: SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Key Conversion Patterns Applied

| SQL Server Pattern | PostgreSQL Equivalent |
|-------------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` with writable CTE |
| `GETDATE()` | `clock_timestamp()` |
| `DECLARE @var; SET @var = ...` | Writable CTEs (`WITH old_values AS (...)`) |
| `BEGIN TRANSACTION; ... COMMIT;` | Removed (managed by application-level transaction) |
| Table/column names (PascalCase) | Lowercase (per DMS schema mapping) |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `Server=localhost;...` | `Host=localhost;Port=5432;...` |
