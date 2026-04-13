# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-13 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 ADO.NET |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **DMS Conversion Successful** | 0 |
| **DMS Conversion Failed** | 7 |
| **Manual Conversion Applied** | 7 |
| **Equivalency Validated as EQUIVALENT** | 0 |
| **Equivalency Validated as NOT_EQUIVALENT** | 0 |
| **Equivalency Validation ERROR** | 7 |

### DMS Tool Failure Details
All 7 SQL statements were passed to the DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`). All conversions failed with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Multiple retry attempts** were made with varying parameters (poll intervals, explicit database/server names)

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) worked successfully and provided the schema mappings used for manual conversion.

### SQL Equivalency Tool Results
All 7 statement pairs were validated through the SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR with `'uniqueID'` - this appears to be a tool-level infrastructure issue, not a statement-level problem.

### Manual Conversion Method
Since DMS failed, all statements were manually converted using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:
- All schema object names (tables, columns, aliases) converted to lowercase
- Schema mappings from DMS Schema Mapping Tool applied
- SQL Server specific functions replaced with PostgreSQL equivalents

## SQL Statements Detail

### Statement 1: GetAllProductsAsync
- **Method**: `ProductRepository.GetAllProductsAsync()`
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency**: ERROR (tool returned 'uniqueID')

### Statement 2: GetProductByIdAsync
- **Method**: `ProductRepository.GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency**: ERROR (tool returned 'uniqueID')

### Statement 3: InsertProductAsync
- **Method**: `ProductRepository.InsertProductAsync(Product product)`
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid`
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @var / SET @var` → Separate C# SQL commands with transaction
  - Single SQL block → Multiple SQL commands managed by C# NpgsqlTransaction
- **Equivalency**: ERROR (tool returned 'uniqueID')

### Statement 4: UpdateProductAsync
- **Method**: `ProductRepository.UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @var` → C# variables populated from SELECT query
  - `GETDATE()` → `clock_timestamp()`
  - Single SQL block → Multiple SQL commands with NpgsqlTransaction
- **Equivalency**: ERROR (tool returned 'uniqueID')

### Statement 5: DeleteProductAsync
- **Method**: `ProductRepository.DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO, DELETE, INSERT, UPDATE with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @var` → C# variables populated from SELECT query
  - `GETDATE()` → `clock_timestamp()`
  - Single SQL block → Multiple SQL commands with NpgsqlTransaction
- **Equivalency**: ERROR (tool returned 'uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `ProductRepository.GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK, PERCENT_RANK Window Functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency**: ERROR (tool returned 'uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Method**: `ProductRepository.GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: 
  - Table/column names lowercased
  - Added `CAST(stockquantity AS NUMERIC)` for integer division in ROUND
- **Equivalency**: ERROR (tool returned 'uniqueID')

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader, SqlTransaction→NpgsqlTransaction); using statement updated; MapProductFromReader column names lowercased |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server format (Server=, Trusted_Connection=) to PostgreSQL format (Host=, Username=, Password=) |

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.6 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *(removed - not applicable)* |
| TLS | `TrustServerCertificate=True` | *(removed - not applicable)* |

## Schema Mapping (from DMS Schema Mapping Tool)

| SQL Server | PostgreSQL |
|-----------|------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |
| All column names | Lowercase equivalents |

## Build Status
- **Final Build**: ✅ SUCCESS (0 errors)
- **Warnings**: 10 pre-existing nullable reference warnings (unchanged from original)

## Artifacts Generated
1. `extracted_statements.sql` - All 7 original MS SQL statements with source annotations
2. `converted_statements.sql` - All 7 converted PostgreSQL statements with conversion method annotations
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency report for all 7 statement pairs
4. `migration_report.md` - This report
5. `dms_conversion_summary.md` - Detailed DMS failure documentation

## Statements Requiring Manual Review
All 7 statements should be reviewed as they were manually converted due to DMS tool failure and could not be validated for equivalency due to the SQL Equivalency tool returning errors. The conversions follow standard SQL Server to PostgreSQL patterns and should be functionally equivalent.
