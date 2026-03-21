# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-21 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9 (ADO.NET) |
| **Total SQL Statements Processed** | 7 |
| **DMS Tool Successful Conversions** | 0 |
| **Manual Conversions (DMS Failure)** | 7 |
| **Equivalency: Equivalent** | 0 |
| **Equivalency: Non-Equivalent** | 0 |
| **Equivalency: Error** | 7 |

## DMS Conversion Details

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements. All attempts failed with:
- **Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **Root Cause**: The DMS metadata model conversion step consistently timed out
- **Mitigation**: All statements were manually converted using lowercase schema mapping rules based on DMS Schema Mapping Tool output

### DMS Schema Mapping Tool (Successful)

The DMS Schema Mapping Tool was successfully used to obtain target schema mappings:

| Source (SQL Server) | Target (PostgreSQL) | Schema |
|---------------------|---------------------|--------|
| `dbo.Products` | `productmanagement_dbo.products` | All columns lowercase |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` | All columns lowercase |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` | All columns lowercase |

## SQL Equivalency Validation

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs. All calls returned:
- **Status**: ERROR
- **Error**: `'uniqueID'`
- **Root Cause**: Service-level issue (confirmed with trivial `SELECT 1` test)
- **Note**: This error is independent of the SQL statements themselves; the tool was unavailable during the migration window

## Package Changes

| Component | Before | After |
|-----------|--------|-------|
| **NuGet Package** | `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |
| **Using Directive** | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL Class | Occurrences |
|-----------------|------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per query method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *(removed - not applicable)* |
| Certificate | `TrustServerCertificate=True` | *(removed - not applicable)* |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG OVER, COUNT OVER)
- **Key Changes**: All identifiers lowercase, CTE renamed to `productstats_cte`, quoted column aliases for reader compatibility
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, parameterized query
- **Key Changes**: All identifiers lowercase, CTE renamed to `producthistory_cte`, quoted column aliases
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @NewProductId INT` → removed (use `lastval()` directly)
  - `BEGIN TRANSACTION` → `BEGIN`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → restructured as subqueries
  - `GETDATE()` → `clock_timestamp()`
  - History INSERT moved before UPDATE to capture old values
  - `BEGIN TRANSACTION` → `BEGIN`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, DELETE
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → restructured as subqueries
  - `GETDATE()` → `clock_timestamp()`
  - History INSERT uses subquery to capture values before DELETE
  - `BEGIN TRANSACTION` → `BEGIN`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK(), PERCENT_RANK() window functions
- **Key Changes**: All identifiers lowercase, CTE name lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX OVER() window functions
- **Key Changes**: All identifiers lowercase, added `CAST(stockquantity AS NUMERIC)` for integer division fix
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, using directive updated, ADO.NET classes replaced |
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient → Npgsql |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

## Artifacts Generated

| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This report |

## Build Status

**Final Build: ✅ SUCCESS**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings, no new warnings introduced)
- No security vulnerability warnings (Npgsql 8.0.6 used instead of 8.0.1 to resolve NU1903)

## Items Requiring Manual Review

1. **SQL Equivalency Validation**: All 7 statement pairs returned ERROR from the equivalency tool due to a service-level issue. Manual review of SQL equivalency is recommended.
2. **Transaction Block Restructuring**: Statements 3, 4, and 5 were significantly restructured to avoid SQL Server's `DECLARE`/`SET` pattern. The PostgreSQL versions use subqueries and `lastval()` instead. Functional testing is recommended.
3. **Integer Division**: Statement 7 (`GetLowStockProductsAsync`) required `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in PostgreSQL.
4. **Connection Credentials**: The connection strings use placeholder credentials (`postgres`/`postgres`). These should be replaced with actual credentials or environment variables for production deployment.
