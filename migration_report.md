# Migration Report: SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Manual Conversion (DMS Failure) | 7 |
| Equivalency Validated (EQUIVALENT) | 0 |
| Equivalency Validated (NOT_EQUIVALENT) | 0 |
| Equivalency Validation Errors | 7 |
| Package Changes | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| Build Status | ✅ Success (0 errors) |

## DMS Tool Status

All 7 statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with:
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Schema**: `dbo`
- **Database**: `ProductManagement`

**All 7 attempts failed** with error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied with lowercase schema object names per the transformation rules (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Validation Status

All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 validations returned ERROR** with:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Note: The equivalency tool error (`'uniqueID'`) appears to be an internal tool issue, not related to the SQL conversion quality.

## Per-Statement Details

### Statement 1: GetAllProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetAllProductsAsync()` method
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR
- **Key Changes**: Schema objects lowercased (Products→products, ProductId→productid, etc.)

### Statement 2: GetProductByIdAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductByIdAsync()` method
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE with NULL check
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR
- **Key Changes**: Schema objects lowercased, CTE name changed from `ProductHistory` to `producthistory_cte` to avoid table name conflict

### Statement 3: InsertProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `InsertProductAsync()` method
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → C# managed transaction (BeginTransactionAsync/CommitAsync)
  - `DECLARE @NewProductId` → C# variable capture from RETURNING
  - Single SQL block → Multiple separate queries within transaction

### Statement 4: UpdateProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `UpdateProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` + `SELECT @var = col` → Separate SELECT query with C# variable capture
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → C# managed transaction
  - Single SQL block → Four separate queries within transaction

### Statement 5: DeleteProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `DeleteProductAsync()` method
- **Type**: Transaction block with DECLARE, SELECT, INSERT, DELETE, UPDATE with CASE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR
- **Key Changes**:
  - Same DECLARE/SELECT pattern as UpdateProductAsync
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → C# managed transaction
  - Single SQL block → Four separate queries within transaction

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductsByPriceRangeAsync()` method
- **Type**: SELECT with CTE, RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR
- **Key Changes**: Schema objects lowercased

### Statement 7: GetLowStockProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetLowStockProductsAsync()` method
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency**: ERROR
- **Key Changes**: Schema objects lowercased, added `::NUMERIC` cast for integer division in ROUND

## Package Dependency Changes

| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

Note: Npgsql 8.0.6 was chosen instead of 8.0.1 to avoid known vulnerability (NU1903, GHSA-x9vc-6hfv-hg8c).

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|------------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` (cast) | `NpgsqlTransaction` (cast) | 11 |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server connection | `Server=localhost` | `Host=localhost` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## SQL Script Changes

### Scripts/01_InitialSetup.sql
- Converted from SQL Server DDL to PostgreSQL
- `IDENTITY(1,1)` → `SERIAL`
- `NVARCHAR` → `VARCHAR`
- `DATETIME` → `TIMESTAMP`
- `GETDATE()` → `NOW()`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- Removed `GO` batch separators
- Removed SQL Server-specific `IF NOT EXISTS` patterns

### Database/Scripts/01_InitialSetup.sql
- All changes from Scripts/01_InitialSetup.sql plus:
- `BIT` → `BOOLEAN`
- `DEFAULT 1` (for BIT) → `DEFAULT TRUE`
- SQL Server trigger syntax → PostgreSQL trigger function + `CREATE TRIGGER`
- `SYSTEM_USER` → `current_user`
- `IF EXISTS ... DROP` → `DROP TABLE IF EXISTS`

## Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Extracted SQL Statements | `extracted_statements.sql` | ✅ Complete (7 statements) |
| Converted SQL Statements | `converted_statements.sql` | ✅ Complete (7 statements) |
| Equivalency Validation Report | `sql_equivalency_validation_report.json` | ✅ Complete (7 entries) |
| Migration Report | `migration_report.md` | ✅ Complete |
| Updated ProductRepository.cs | `DataAccess/ProductRepository.cs` | ✅ Complete |
| Updated Project File | `AdoCore.csproj` | ✅ Complete |
| Updated Config | `appsettings.json` | ✅ Complete |
| Updated SQL Scripts | `Scripts/01_InitialSetup.sql`, `Database/Scripts/01_InitialSetup.sql` | ✅ Complete |
| Updated README | `README.md` | ✅ Complete |
