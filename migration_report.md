# SQL Server to PostgreSQL Migration Report

## Summary
This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using ADO.NET (Npgsql).

**Migration Date:** 2026-04-30  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent (SQL Equivalency tool) | 0 |
| Equivalency validation errors | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the AWS DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All 7 failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
**DMS Migration Project ARN:** `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

### Manual Conversion Applied
Since DMS was unavailable, all 7 statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:
- All schema object names (tables, columns, views) converted to lowercase
- Schema mapping from DMS schema_mapping_tool was used as reference:
  - `dbo.Products` → `products` (target: `productmanagement_dbo.products`)
  - `dbo.ProductHistory` → `producthistory` (target: `productmanagement_dbo.producthistory`)
  - `dbo.ProductStats` → `productstats` (target: `productmanagement_dbo.productstats`)

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All 7 returned ERROR:
```json
{
  "equivalence_status": "ERROR",
  "error": "'uniqueID'"
}
```
This appears to be a service-side error unrelated to the statement content, as even trivial SELECT statements returned the same error.

---

## Statements Requiring Manual Review

All 7 statements require manual review due to both DMS conversion failure and SQL Equivalency tool errors:

### Statement 1: GetAllProductsAsync
- **Type:** CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Key Changes:** Table/column names lowercased, CTE renamed to `productstats_cte` to avoid conflict with table name
- **Risk:** Low - standard SQL syntax compatible with both databases

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function, LEFT JOIN, CASE, ROUND
- **Key Changes:** Table/column names lowercased, CTE renamed to `producthistory_cte`
- **Risk:** Low - LAG and standard SQL syntax are PostgreSQL compatible

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Key Changes:** `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `clock_timestamp()`, transaction handling moved to C# code (BeginTransactionAsync/CommitAsync), single SQL split into 3 separate commands
- **Risk:** Medium - structural change from single SQL to multiple commands with C# transaction

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT INTO, UPDATE, INSERT history, UPDATE stats
- **Key Changes:** `DECLARE`/`SELECT INTO` variables moved to C# code using `ExecuteReaderAsync`, `GETDATE()` → `clock_timestamp()`, single SQL split into 4 separate commands
- **Risk:** Medium - structural change from single SQL to multiple commands with C# transaction

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT INTO, INSERT history, DELETE, UPDATE stats with CASE
- **Key Changes:** Similar to Statement 4 - variables handled in C#, `GETDATE()` → `clock_timestamp()`, single SQL split into 4 separate commands
- **Risk:** Medium - structural change from single SQL to multiple commands with C# transaction

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK and PERCENT_RANK window functions, BETWEEN, CASE
- **Key Changes:** Table/column names lowercased
- **Risk:** Low - RANK/PERCENT_RANK are standard SQL functions

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes:** Table/column names lowercased, added `::numeric` cast for integer division in ROUND
- **Risk:** Low - standard SQL syntax, explicit cast needed for PostgreSQL integer division behavior

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced `using Microsoft.Data.SqlClient` with `using Npgsql`; replaced `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, `SqlDataReader` → `NpgsqlDataReader`; restructured transaction methods (Insert/Update/Delete) to use C# transactions with multiple commands; updated column name references to lowercase in MapProductFromReader |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.9` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

---

## Dependency Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.9 |

**Note:** Npgsql 8.0.9 was used instead of 8.0.0 to address a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c).

Unchanged dependencies:
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

---

## Connection String Changes

### DevConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`

### ProdConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | Removed (replaced with Username/Password) |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Port=5432` (added) |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

---

## Build Status
**Final Build:** ✅ Success (0 errors, 0 warnings related to migration)

Pre-existing warnings (not related to migration):
- CS8601/CS8618/CS8600/CS8603/CS8625: Nullable reference type warnings (existed before migration)

---

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency validation report for all 7 statement pairs |
| `migration_report.md` | `sourceCode/` | This report |

---

## Recommendations

1. **Manual Equivalency Review:** Since the SQL Equivalency tool was unavailable (returned errors for all statements), manual review of all 7 statement pairs is strongly recommended before deploying to production.

2. **Integration Testing:** Execute all 7 database operations against a PostgreSQL test database to verify:
   - SELECT operations return correct results
   - INSERT operations correctly create records and return IDs
   - UPDATE operations correctly modify records and log history
   - DELETE operations correctly remove records and update statistics
   - Transaction atomicity is maintained

3. **Connection String Security:** Replace the generic placeholder credentials (`postgres/postgres`) with actual production credentials stored in environment variables or a secrets manager.

4. **Schema Validation:** Verify that the PostgreSQL target schema matches the expected lowercase naming convention used in the converted SQL statements.
