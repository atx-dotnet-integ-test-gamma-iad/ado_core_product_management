# Migration Report: SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Migration Type** | Microsoft SQL Server → PostgreSQL |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Source Database** | ProductManagement (SQL Server 2019) |
| **Target Database** | postgres (PostgreSQL 13) |
| **Total SQL Statements Processed** | 7 |
| **Statements Converted by DMS Tool** | 0 |
| **Statements Manually Converted** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Errors** | 7 |

## DMS Tool Status

The DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 statements but failed consistently with timeout errors:

- **Error Type**: Metadata model creation/conversion timeout
- **Error Message**: "Metadata model creation did not complete after 15 attempts" / "Metadata model conversion did not complete after 15 attempts"
- **Attempts**: 3 separate attempts were made with varying poll settings (15 default, 25 with 15s intervals, 30 with 15s intervals)
- **Simple Query Test**: Even `SELECT GETDATE()` failed, confirming a systemic issue with the DMS service

### DMS Schema Mapping Tool (Successful)

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was successfully used to retrieve the target PostgreSQL schema mappings. These mappings were used to guide the manual conversion:

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

All column names in the target schema are lowercase (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`).

## SQL Equivalency Tool Status

The SQL Equivalency MCP Tool (`sql-equivalency___validate_sql_equivalence`) was invoked for all 7 statement pairs. All returned an ERROR:

- **Error**: `'uniqueID'`
- **Status**: ERROR for all 7 statements
- **Note**: Per the transformation definition, these are marked as ERROR (not using agent judgment for equivalency)

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; Updated using directive, ADO.NET class references, column name references |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

## Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive validation report with all 7 statement pairs |
| `migration_report.md` | This report |

## Dependency Changes

| Original Package | Version | Replacement Package | Version |
|------------------|---------|---------------------|---------|
| `Microsoft.Data.SqlClient` | 5.1.4 | `Npgsql` | 8.0.6 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | (removed - not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | (removed - not applicable) |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Complexity**: Complex CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND, ORDER BY with CASE
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`, CTE alias renamed to `productstats_cte`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Statement 2: GetProductByIdAsync
- **Complexity**: CTE with LAG window functions, LEFT JOIN, CASE with NULL handling, ROUND
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`, CTE alias renamed to `producthistory_cte`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Statement 3: InsertProductAsync
- **Complexity**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), multiple table operations, GETDATE()
- **Key Changes**: Converted from DECLARE/SCOPE_IDENTITY()/BEGIN TRANSACTION to writable CTE with RETURNING clause; GETDATE() → clock_timestamp()
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Statement 4: UpdateProductAsync
- **Complexity**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history, GETDATE()
- **Key Changes**: Converted from DECLARE/BEGIN TRANSACTION to writable CTE; GETDATE() → clock_timestamp()
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Statement 5: DeleteProductAsync
- **Complexity**: Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE
- **Key Changes**: Converted from DECLARE/BEGIN TRANSACTION to writable CTE; GETDATE() → clock_timestamp()
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Statement 6: GetProductsByPriceRangeAsync
- **Complexity**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Statement 7: GetLowStockProductsAsync
- **Complexity**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`, added `::NUMERIC` cast for integer division in ROUND
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (Npgsql) | Occurrences |
|------------------------|----------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Build Status

- **Final Build**: ✅ **Succeeded** (0 errors, 10 warnings)
- **Warnings**: All pre-existing nullable reference warnings (CS8601, CS8603, CS8618, CS8625, CS8600) - not introduced by migration

## Statements Requiring Manual Review

All 7 statements were manually converted (DMS tool failed) and the SQL Equivalency tool returned ERROR for all pairs. **Manual review of all converted SQL statements is recommended** to verify functional correctness against the target PostgreSQL database.

## Artifacts

1. **`extracted_statements.sql`** - Complete catalog of all 7 original MS SQL statements ✅
2. **`converted_statements.sql`** - Complete catalog of all 7 converted PostgreSQL statements ✅
3. **`sql_equivalency_validation_report.json`** - Comprehensive validation report with all 7 statement pairs ✅
4. **`migration_report.md`** - This report ✅
