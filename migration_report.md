# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

### Migration Date: 2026-02-28

---

## 1. SQL Statement Processing Summary

### ProductRepository.cs Inline SQL Statements

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

### DMS Tool Status
- **Status**: All 7 statements failed with the same error
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback**: All statements manually converted with lowercase schema object names per `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol

### SQL Equivalency Tool Status
- **Status**: All 7 statement pairs returned ERROR
- **Error**: `'uniqueID'`
- **Note**: Equivalency statuses are exclusively from the sql-equivalency___validate_sql_equivalence tool. No agent judgment was used.

---

## 2. Detailed Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion**: CTE renamed from `ProductStats` to `productstats_cte` to avoid table name conflict; all schema objects lowercased
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Functions, LEFT JOIN, CASE with NULL handling
- **Conversion**: CTE renamed from `ProductHistory` to `producthistory_cte` to avoid table name conflict; all schema objects lowercased
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), multiple table operations
- **Conversion**: Restructured as writable CTE using `INSERT...RETURNING productid`; `SCOPE_IDENTITY()` replaced with `RETURNING`; `GETDATE()` replaced with `NOW()`; explicit transaction replaced with CTE atomicity
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT history, UPDATE stats
- **Conversion**: Restructured as writable CTE with `old_values` subquery; `DECLARE`/`SET` replaced with CTE-based value capture; `GETDATE()` replaced with `NOW()`
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO variables, INSERT history, DELETE, UPDATE stats with CASE
- **Conversion**: Restructured as writable CTE with `old_values` subquery; `DECLARE`/`SET` replaced with CTE-based value capture; `GETDATE()` replaced with `NOW()`
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK() and PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Conversion**: All schema objects lowercased; PostgreSQL-compatible syntax maintained
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER Window Functions, CASE, ROUND
- **Conversion**: All schema objects lowercased; added `CAST(stockquantity AS DECIMAL)` for integer division handling
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

---

## 3. SQL Setup Scripts Conversion

### Scripts/01_InitialSetup.sql (Simple Version)
- Converted `IDENTITY(1,1)` to `SERIAL`
- Converted `GETDATE()` to `NOW()`
- Converted `NVARCHAR` to `VARCHAR`
- Removed `[dbo].` schema prefixes, applied lowercase
- Removed `GO` batch separators
- Converted `CREATE OR ALTER PROCEDURE` to `CREATE OR REPLACE FUNCTION`
- Converted `SCOPE_IDENTITY()` to `RETURNING productid`
- Removed `SET NOCOUNT ON`
- Converted `IF NOT EXISTS (SELECT * FROM sys.databases...)` to `CREATE TABLE IF NOT EXISTS`
- Converted `EXEC sp_InsertProduct` to `PERFORM sp_insertproduct`

### Database/Scripts/01_InitialSetup.sql (Comprehensive Version)
- All conversions from simple version plus:
- Converted `[bit]` to `BOOLEAN`
- Converted `DEFAULT 1` (bit) to `DEFAULT TRUE`, `DEFAULT 0` to `DEFAULT FALSE`
- Converted `SYSTEM_USER` to `CURRENT_USER`
- Converted trigger syntax from MS SQL (`AFTER INSERT, UPDATE, DELETE` with `inserted`/`deleted` tables) to PostgreSQL (`AFTER INSERT OR UPDATE OR DELETE` with `TG_OP`, `NEW`/`OLD` records, trigger function)
- Converted `IF EXISTS (SELECT * FROM sys.objects...)` to `DROP TABLE IF EXISTS`
- Removed `USE DatabaseName` statement
- Added foreign key constraints with lowercase names

---

## 4. File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | All 7 SQL statements converted to PostgreSQL; SqlClient -> Npgsql class replacements |
| `AdoCore.csproj` | Modified | Microsoft.Data.SqlClient 5.1.4 -> Npgsql 8.0.1 |
| `appsettings.json` | Modified | Connection strings converted to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted from SQL Server to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted from SQL Server to PostgreSQL syntax |
| `extracted_statements.sql` | New | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | New | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | New | Comprehensive equivalency validation report |
| `migration_report.md` | New | This migration summary report |

---

## 5. ADO.NET Class Replacements

| Original (SqlClient) | Replacement (Npgsql) | Occurrences |
|----------------------|---------------------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 4 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

---

## 6. Connection String Conversion

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

---

## 7. Key Conversion Patterns Applied

| MS SQL Server | PostgreSQL | Context |
|---------------|-----------|---------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | Insert with identity retrieval |
| `GETDATE()` | `NOW()` | Current timestamp |
| `DECLARE @var TYPE; SET @var = ...` | Writable CTE with subquery | Variable capture for old values |
| `BEGIN TRANSACTION; ... COMMIT;` | Writable CTE (atomic) | Transaction blocks in inline SQL |
| `IDENTITY(1,1)` | `SERIAL` | Auto-increment columns |
| `NVARCHAR(n)` | `VARCHAR(n)` | Unicode string types |
| `[dbo].[TableName]` | `tablename` | Schema-qualified names |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Stored procedures |
| `[bit]` | `BOOLEAN` | Boolean type |
| `SYSTEM_USER` | `CURRENT_USER` | Current user |
| `GO` | Removed | Batch separators |
| `SET NOCOUNT ON` | Removed | Not applicable |

---

## 8. Statements Requiring Manual Review

All 7 inline SQL statements from ProductRepository.cs require manual review because:
1. DMS conversion tool was unavailable (metadata model creation failure)
2. SQL Equivalency validation tool returned errors for all pairs
3. Manual conversion was applied per `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol

**Detailed statement-level data is available in**: `sql_equivalency_validation_report.json`

---

## 9. Build Status

- **Final Build**: SUCCESS (0 errors, 10 warnings - all pre-existing nullability warnings)
- **Package**: Npgsql 8.0.1 (compatible with .NET 9.0)
- **Framework**: .NET 9.0

---

## 10. Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| Original SQL Catalog | `extracted_statements.sql` | All 7 original MS SQL statements |
| Converted SQL Catalog | `converted_statements.sql` | All 7 converted PostgreSQL statements |
| Equivalency Report | `sql_equivalency_validation_report.json` | Full equivalency validation results |
| Migration Report | `migration_report.md` | This comprehensive summary |
