# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention after DMS Failure | 7 |
| Validated as Equivalent by SQL Equivalency Tool | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS Tool Status

The DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) consistently failed for all 7 statements with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Schema Mapping Tool** (`dms-mcp___schema_mapping_tool`) was successful and provided the authoritative schema mappings used for manual conversion:

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

All column names were converted to lowercase per the DMS schema mapping output.

## SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR with `'uniqueID'` for all 7 statement pairs. This was a consistent tool infrastructure issue — even the simplest possible query (`SELECT Name FROM Products`) returned the same error. All statements were individually submitted to the tool as required.

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE/WHEN, ROUND, INNER JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**: `Products` → `productmanagement_dbo.products`, all columns lowercase, CTE renamed to avoid reserved name conflict

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG() Window Functions, CASE/WHEN, LEFT JOIN, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**: `Products` → `productmanagement_dbo.products`, all columns lowercase, `@ProductId` parameter preserved

### Statement 3: InsertProductAsync
- **Type**: Complex T-SQL block with DECLARE, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → 3 individual PostgreSQL statements managed by C# NpgsqlTransaction
  - All table/column names lowercase with `productmanagement_dbo` schema

### Statement 4: UpdateProductAsync
- **Type**: Complex T-SQL block with BEGIN TRANSACTION/COMMIT, DECLARE variables, SELECT into variables, UPDATE, INSERT
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → C# variables via SELECT reader
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → 4 individual PostgreSQL statements managed by C# NpgsqlTransaction

### Statement 5: DeleteProductAsync
- **Type**: Complex T-SQL block with BEGIN TRANSACTION/COMMIT, DECLARE variables, SELECT, INSERT, DELETE, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → C# variables via SELECT reader
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → 4 individual PostgreSQL statements managed by C# NpgsqlTransaction

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, CASE/WHEN, BETWEEN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**: `Products` → `productmanagement_dbo.products`, all columns lowercase

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE/WHEN, ROUND, WHERE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**: `Products` → `productmanagement_dbo.products`, all columns lowercase, added `CAST(stockquantity AS NUMERIC)` for proper division

## File-by-File Changes Summary

### sourceCode/DataAccess/ProductRepository.cs
- All 7 SQL statements replaced with PostgreSQL equivalents
- Transaction methods (Insert, Update, Delete) restructured to use C# `NpgsqlTransaction`
- `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `MapProductFromReader` column access updated to lowercase names

### sourceCode/AdoCore.csproj
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### sourceCode/appsettings.json
- Connection strings converted from SQL Server format to PostgreSQL Npgsql format
- `Server=localhost` → `Host=localhost;Port=5432`
- `Database=ProductManagement` → `Database=postgres`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed: `MultipleActiveResultSets`, `TrustServerCertificate`

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Extracted Statements Catalog | `sourceCode/extracted_statements.sql` | Complete (7 statements) |
| Converted Statements Catalog | `sourceCode/converted_statements.sql` | Complete (7 statements) |
| SQL Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | Complete (7 statement pairs) |
| Migration Report | `sourceCode/migration_report.md` | This document |

## Build Status

The application compiles successfully with `dotnet build`:
- **0 Errors**
- **10 Warnings** (pre-existing nullable reference warnings, not introduced by migration)

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS Statement Conversion Tool failed for all statements (infrastructure issue)
2. SQL Equivalency Tool returned ERROR for all statement pairs (infrastructure issue)
3. Manual conversions were applied using DMS schema mapping as the authoritative source

Recommended manual review focus areas:
- Verify `productmanagement_dbo` schema exists in target PostgreSQL database
- Verify `RETURNING productid` works correctly with `GENERATED ALWAYS AS IDENTITY` columns
- Verify `NOW()` produces expected datetime values in PostgreSQL context
- Verify transaction isolation behavior matches original SQL Server behavior
- Test all CRUD operations end-to-end against the target PostgreSQL database
