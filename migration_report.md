# Microsoft SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## Migration Date
2026-04-05

## Source and Target
- **Source Database**: Microsoft SQL Server (ProductManagement)
- **Target Database**: PostgreSQL
- **Application Framework**: .NET 9.0 with ADO.NET
- **Source Package**: Microsoft.Data.SqlClient 5.1.4
- **Target Package**: Npgsql 8.0.6

---

## DMS MCP Tool Status

### Statement Conversion Tool (dms-mcp___statement_conversion_tool)
**Status: FAILED for all 7 statements**

The DMS statement conversion tool experienced a systemic infrastructure failure, preventing conversion of any SQL statements. Multiple attempts were made:

1. **Attempt 1**: GetAllProductsAsync SQL with default settings → Error: "Metadata model conversion failed: did not complete after 15 attempts"
2. **Attempt 2**: GetAllProductsAsync SQL with max_poll_attempts=30, poll_interval_seconds=15 → Timed out after 300 seconds
3. **Attempt 3**: Simple `SELECT ProductId, Name, Price FROM Products WHERE ProductId = @ProductId` with max_poll_attempts=25 → Error: "Metadata model creation failed: did not complete after 25 attempts"
4. **Attempt 4**: Simplest possible `SELECT SCOPE_IDENTITY()` → Error: "Metadata model creation failed: did not complete after 15 attempts"

### Schema Mapping Tool (dms-mcp___schema_mapping_tool)
**Status: SUCCEEDED for all 3 tables**

Schema mappings successfully retrieved and used for manual conversion:
| Source Table | Target Table | Target Schema |
|-------------|-------------|---------------|
| Products | products | productmanagement_dbo |
| ProductHistory | producthistory | productmanagement_dbo |
| ProductStats | productstats | productmanagement_dbo |

---

## SQL Equivalency Tool Status

### Equivalency Validation Tool (sql-equivalency___validate_sql_equivalence)
**Status: SYSTEMIC ERROR for all 7 statement pairs**

The SQL Equivalency tool returned the same error `'uniqueID'` for all 7 statement pairs. An additional 8th test with the simplest possible SQL (`SELECT ProductId, Name FROM Products` vs `SELECT productid, name FROM products`) also returned the same error, confirming this is a systemic tool infrastructure issue, not a statement-specific problem.

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR."

---

## File Changes Summary

### 1. AdoCore.csproj - Package Dependency Update
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`
- Other packages unchanged: Microsoft.Extensions.Configuration 8.0.0, Configuration.Json 8.0.0, DependencyInjection 8.0.0

### 2. DataAccess/ProductRepository.cs - SQL Statements + ADO.NET Classes
#### SQL Statement Changes
All 7 SQL statements converted to PostgreSQL syntax with lowercase schema naming.

#### ADO.NET Class Replacements
| Original | Replacement |
|----------|------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### 3. appsettings.json - Connection Strings
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation applied
- **Environment**: "Development" (unchanged)

---

## Detailed SQL Statement Conversion Report

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetAllProductsAsync()`
- **SQL Type**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **DMS Status**: FAILED (Metadata model creation timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)
- **Key Changes**:
  - Table/column names → lowercase (Products→products, ProductId→productid, etc.)
  - CTE renamed from `ProductStats` to `productstats_cte` (avoid table name clash)

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductByIdAsync(int productId)`
- **SQL Type**: CTE with LAG window function, LEFT JOIN, ROUND, CASE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - Table/column names → lowercase
  - CTE renamed from `ProductHistory` to `producthistory_cte` (avoid table name clash)

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `InsertProductAsync(Product product)`
- **SQL Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - SCOPE_IDENTITY() → INSERT...RETURNING via writable CTE
  - GETDATE() → clock_timestamp()
  - BEGIN TRANSACTION/COMMIT → Single writable CTE statement (atomic)
  - DECLARE @var → Eliminated via writable CTE pattern

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `UpdateProductAsync(Product product)`
- **SQL Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - DECLARE @OldPrice/@OldStock → old_values CTE
  - GETDATE() → clock_timestamp()
  - T-SQL variable assignment → CTE SELECT for old values
  - Transaction → Writable CTE (single atomic statement)

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `DeleteProductAsync(int productId)`
- **SQL Type**: Transaction block with DECLARE, SELECT INTO, DELETE, INSERT, UPDATE, CASE, GETDATE()
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - Same pattern as Statement 4 (old_values CTE, writable CTEs)
  - CASE expression preserved in UPDATE
  - GETDATE() → clock_timestamp()

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **SQL Type**: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - Table/column names → lowercase
  - All SQL constructs PostgreSQL-compatible (no syntax changes needed)

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **SQL Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - Table/column names → lowercase
  - Added CAST(stockquantity AS NUMERIC) for integer division in ROUND

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Complete catalog of all 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency report with all 7 pairs |
| dms_failure_summary.md | sourceCode/ | Detailed DMS failure documentation |
| migration_report.md | sourceCode/ | This report |

---

## Build Status

**Final Build: SUCCEEDED**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings, not introduced by migration)

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS statement conversion tool failure (systemic infrastructure issue)
2. SQL Equivalency validation tool failure (systemic 'uniqueID' error)

The manual conversions were applied following these rules:
- Lowercase schema object names (per DMS schema_mapping_tool results)
- Standard SQL Server → PostgreSQL function mappings (SCOPE_IDENTITY → RETURNING, GETDATE → clock_timestamp)
- T-SQL transaction blocks → PostgreSQL writable CTEs for Npgsql parameter compatibility
- Integer division → CAST to NUMERIC for proper decimal results in ROUND

---

## Recommendations for Post-Migration

1. **Test all 7 SQL statements** against a live PostgreSQL database to verify correctness
2. **Validate writable CTE behavior** for INSERT/UPDATE/DELETE operations (statements 3, 4, 5)
3. **Update connection string credentials** with actual PostgreSQL credentials for production
4. **Re-run SQL Equivalency validation** when the tool is operational to confirm conversions
5. **Test transaction handling** in the ExecuteInTransactionAsync method with NpgsqlConnection
