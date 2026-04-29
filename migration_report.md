# Migration Report: MS SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-29 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Total SQL Statements Processed** | 7 |
| **DMS Successful Conversions** | 0 |
| **DMS Failed Conversions** | 7 |
| **Manual Conversions Required** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Errors** | 7 |

## DMS Tool Status

The AWS Database Migration Service (DMS) MCP tool was used for all 7 SQL statement conversions. All attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

Multiple retry attempts with increased poll intervals (up to 50 attempts at 20-second intervals) did not resolve the issue. As per the transformation definition, manual conversions were applied using lowercase schema object names for PostgreSQL compatibility (conversion method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Validation

All 7 statement pairs were validated using the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with error: `'uniqueID'`.

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR."

**Note**: The SQL Equivalency tool errors are independent of the DMS tool failures - the equivalency tool was called for every statement pair regardless of how the PostgreSQL statement was obtained.

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function, CASE, ROUND, LEFT JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @NewProductId INT` → Removed
  - `SCOPE_IDENTITY()` → `currval(pg_get_serial_sequence('products', 'productid'))`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO vars, UPDATE, INSERT
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → Eliminated via INSERT...SELECT subquery pattern
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → Eliminated via INSERT...SELECT subquery pattern
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - CASE expression in UPDATE preserved (PostgreSQL-compatible)
  - All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - All table/column names lowercased
  - Added `CAST(stockquantity AS DECIMAL)` for integer division handling
- **Equivalency Status**: ERROR

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `AdoCore.csproj` | Package Reference | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | SQL + Code | 7 SQL statements converted + all ADO.NET classes replaced |
| `appsettings.json` | Configuration | SQL Server connection strings → PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | SQL Script | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | SQL Script | Converted to PostgreSQL syntax |

## Package Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

## Class Replacements

| SQL Server Class | Npgsql Replacement |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| SSL | `TrustServerCertificate=True` | Removed |

## Column Name Mapping in Reader

All column name references in `MapProductFromReader` were lowercased:
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

## Build Status

The application compiles successfully after all migrations:
- **Build Result**: Succeeded
- **Errors**: 0
- **Warnings**: 10 (pre-existing nullable reference warnings, not related to migration)

## Statements Requiring Manual Review

All 7 statements require manual review as:
1. DMS tool was unavailable (metadata model creation error)
2. SQL Equivalency tool returned errors for all statements
3. Manual conversions were applied based on standard MS SQL → PostgreSQL conversion rules

Specific areas for review:
- **Transaction blocks (Statements 3, 4, 5)**: Restructured to remove DECLARE/@variable syntax, using subqueries and `currval()` instead
- **Integer division (Statement 7)**: Added explicit CAST to DECIMAL to prevent PostgreSQL integer truncation
- **Connection strings**: Placeholder credentials used for development; production credentials should be configured via environment variables or secure configuration

## Artifacts

1. **extracted_statements.sql** - 7 original MS SQL statements
2. **converted_statements.sql** - 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Equivalency validation report (all 7 pairs)
4. **migration_report.md** - This report
5. **dms_conversion_log.md** - Detailed DMS conversion attempt log
