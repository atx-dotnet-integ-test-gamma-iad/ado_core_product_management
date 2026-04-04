# Migration Report: Microsoft SQL Server to PostgreSQL

## Project Information
- **Project Type**: .NET 9.0 Console Application (AdoCore)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Source Package**: Microsoft.Data.SqlClient 5.1.4
- **Target Package**: Npgsql 8.0.6
- **Migration Date**: 2026-04-04

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS Tool | 0 |
| Manually Converted (DMS Failure) | 7 |
| Validated as EQUIVALENT | 0 |
| Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validation ERROR | 7 |

## Tool Status

### DMS Statement Conversion Tool
- **Status**: FAILED (all attempts)
- **Error**: Metadata model creation/conversion timeout
- **Attempts**: 4 attempts with different statements and polling parameters
- **Fallback**: Manual conversion using DMS Schema Mapping Tool results with lowercase schema object naming
- **Reason Code**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### DMS Schema Mapping Tool
- **Status**: SUCCESS
- **Used for**: Obtaining accurate table/column name mappings between SQL Server and PostgreSQL
- **Tables Mapped**: Products → products, ProductHistory → producthistory, ProductStats → productstats
- **Target Schema**: productmanagement_dbo

### SQL Equivalency Tool
- **Status**: ERROR (persistent internal error)
- **Error**: `'uniqueID'` - returned for all 7 statement pairs
- **Note**: Per transformation rules, all statements marked as ERROR since tool determination is required

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient → Npgsql 8.0.6 |
| `DataAccess/ProductRepository.cs` | SQL statements, imports (using Npgsql), ADO.NET classes (NpgsqlConnection, NpgsqlCommand, NpgsqlDataReader, NpgsqlTransaction) |
| `appsettings.json` | Connection strings converted to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Database setup script converted to PostgreSQL |
| `Database/Scripts/01_InitialSetup.sql` | Comprehensive database setup script converted to PostgreSQL |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG() OVER(), COUNT() OVER(), CASE, ROUND, INNER JOIN
- **Key Changes**: CTE name `ProductStats` → `productstats_cte` (avoid table name conflict), all identifiers lowercased
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool internal error)

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG() OVER(), parameterized query, LEFT JOIN
- **Key Changes**: CTE name `ProductHistory` → `producthistory_cte` (avoid table name conflict), LAG window function preserved
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool internal error)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `clock_timestamp()`
  - Single SQL string → multiple commands with C# transaction management
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool internal error)

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE, GETDATE()
- **Key Changes**:
  - `GETDATE()` → `clock_timestamp()`
  - DECLARE/SELECT pattern → separate query with C# variable capture
  - Single SQL string → multiple commands with C# transaction management
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool internal error)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, DELETE, CASE expression, GETDATE()
- **Key Changes**:
  - `GETDATE()` → `clock_timestamp()`
  - DECLARE/SELECT pattern → separate query with C# variable capture
  - CASE expression preserved (PostgreSQL compatible)
  - Single SQL string → multiple commands with C# transaction management
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool internal error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE
- **Key Changes**: All identifiers lowercased, window functions preserved (same syntax)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool internal error)

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE, ROUND
- **Key Changes**: All identifiers lowercased, added `::NUMERIC` cast for integer division in ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool internal error)

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. **DMS conversion failure** - All statements were manually converted due to DMS tool timeouts
2. **Equivalency validation failure** - All equivalency validations returned ERROR due to tool internal error

**Recommendation**: Run end-to-end testing against a PostgreSQL 13 instance to validate functional equivalency of all 7 statements.

## Schema Mapping Reference (from DMS Schema Mapping Tool)

| SQL Server | PostgreSQL |
|-----------|-----------|
| `[dbo].[Products]` | `products` |
| `[dbo].[ProductHistory]` | `producthistory` |
| `[dbo].[ProductStats]` | `productstats` |
| `ProductId` (int IDENTITY) | `productid` (INTEGER GENERATED ALWAYS AS IDENTITY) |
| `datetime DEFAULT GETDATE()` | `TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp()` |
| `decimal(18,2)` | `NUMERIC(18,2)` |
| `nvarchar(N)` | `VARCHAR(N)` |
| `bit` | `BOOLEAN` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |

## Connection String Mapping

| SQL Server | PostgreSQL |
|-----------|-----------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | (removed - not applicable) |
| `TrustServerCertificate=True` | (removed - not applicable) |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency report for all 7 statements |
| `extracted_statements.sql` | Project root | Catalog of all 7 original SQL Server statements |
| `converted_statements.sql` | Project root | Catalog of all 7 converted PostgreSQL statements |
| `dms_conversion_log.txt` | Project root | Detailed DMS tool interaction log |
| `migration_report.md` | Project root | This report |

## Build Status
- **Final Build**: ✅ **SUCCEEDED** (0 errors, 10 warnings - all pre-existing nullable warnings)
- **No remaining SQL Server references** in C# or csproj files
- **No remaining SQL Server syntax** (SCOPE_IDENTITY, GETDATE) in C# files
