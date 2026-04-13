# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET class references, and modifying connection configurations.

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS Tool | 0 |
| Requiring Manual Intervention | 7 |
| Validated as Equivalent (by tool) | 0 |
| Validated as Non-Equivalent (by tool) | 0 |
| With Equivalency Validation Errors | 7 |

## DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) with the following configuration:
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1

**Result**: All 7 conversions failed with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

As per the transformation definition, all statements were manually converted applying lowercase schema object names with the conversion method documented as `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Validation Status
All 7 statement pairs were submitted to the SQL Equivalency validation tool (`sql-equivalency___validate_sql_equivalence`).

**Result**: All 7 validations returned ERROR status:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

**Note**: Per the transformation definition, equivalency status comes exclusively from the tool output and is never substituted with agent judgment.

## Schema Mapping (from DMS Schema Mapping Tool)
The DMS Schema Mapping tool successfully returned the following mappings:

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

Column name mappings (all converted to lowercase):
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, Window Functions, CASE, ROUND, JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency Status**: ERROR (tool returned error)

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG Window Function, CASE, ROUND, LEFT JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency Status**: ERROR (tool returned error)

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `currval(pg_get_serial_sequence('products', 'productid'))`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Removed `DECLARE @NewProductId INT` and `SET @NewProductId`
- **Equivalency Status**: ERROR (tool returned error)

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - Removed `DECLARE @OldPrice`, `DECLARE @OldStock`
  - Replaced variable assignments with subqueries
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Reordered operations: history INSERT and stats UPDATE before product UPDATE to capture old values
- **Equivalency Status**: ERROR (tool returned error)

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - Removed `DECLARE @OldPrice`, `DECLARE @OldStock`
  - Used `INSERT...SELECT` to capture old values before deletion
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Used subquery from producthistory to get old price for stats update
- **Equivalency Status**: ERROR (tool returned error)

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK/PERCENT_RANK Window Functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency Status**: ERROR (tool returned error)

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - Table/column names lowercased
  - Added `CAST(stockquantity AS NUMERIC)` to prevent integer division in ROUND calculation
- **Equivalency Status**: ERROR (tool returned error)

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.9` |
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced all SqlClient types with Npgsql types; updated column name references to lowercase |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

## Files NOT Needing Changes

| File | Reason |
|------|--------|
| `Program.cs` | No SQL Server-specific code |
| `Business/ProductService.cs` | No SQL Server-specific code |
| `Models/Product.cs` | No SQL Server-specific code |
| `CLI/CommandLineInterface.cs` | No SQL Server-specific code |
| `CLI/InteractiveMenu.cs` | No SQL Server-specific code |

## Static Code Changes

### Package References
- **Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Added**: `Npgsql` Version 8.0.9 (upgraded from initially planned 8.0.1 to address high-severity vulnerability GHSA-x9vc-6hfv-hg8c)

### Using Directives
- **Removed**: `using Microsoft.Data.SqlClient;`
- **Added**: `using Npgsql;`

### ADO.NET Class Replacements
| Original | Replacement | Occurrences |
|----------|-------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, instantiation) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server endpoint | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not supported) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

## Transformation Artifacts
1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Complete equivalency report with all 7 statement pairs
4. **migration_report.md** - This report

## Build Status
The project compiles successfully with `dotnet build` (0 errors, warnings are pre-existing nullability warnings).
