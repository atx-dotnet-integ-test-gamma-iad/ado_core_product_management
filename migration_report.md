# Migration Report: MS SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| Migration Date | 2026-04-13 |
| Source Database | Microsoft SQL Server 2019 |
| Target Database | PostgreSQL 13 |
| Application Framework | .NET 9.0, ADO.NET |
| Total SQL Statements Processed | 7 |
| DMS Tool Successfully Converted | 0 |
| Manual Conversions Required | 7 |
| Equivalency Validated (Equivalent) | 0 |
| Equivalency Validated (Non-Equivalent) | 0 |
| Equivalency Validation Errors | 7 |
| Build Status | **SUCCESS** (0 errors, 10 warnings) |

## DMS MCP Tool Results

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) as required. All 7 attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

Per the transformation rules, manual conversion was performed with lowercase schema object names (conversion method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Tool Results

All 7 SQL statement pairs were passed through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 validations returned ERROR with:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation rules, all equivalency statuses were marked as ERROR based on the tool's output (agent judgment was NOT used).

## Detailed SQL Statement Conversions

### Statement 1: GetAllProductsAsync (SELECT with CTE, Window Functions)
- **Source**: CTE with `AVG(Price) OVER()`, `COUNT(*) OVER()`, `INNER JOIN`, `CASE`, `ROUND`, `ORDER BY`
- **Target**: Same logic, lowercase schema objects (`products`, `productid`, `price`, `avgprice`, etc.)
- **Key Changes**: No MS SQL-specific functions used; only casing changes applied
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync (SELECT with CTE, LAG Window Function)
- **Source**: CTE with `LAG(Price) OVER (ORDER BY ModifiedDate)`, `LEFT JOIN`, `CASE`, `ROUND`, parameterized `@ProductId`
- **Target**: Same logic, lowercase schema objects
- **Key Changes**: No MS SQL-specific functions; only casing changes
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync (Transaction Block with INSERT)
- **Source**: `DECLARE @NewProductId INT`, `BEGIN TRANSACTION`, `SCOPE_IDENTITY()`, `GETDATE()`, `COMMIT`
- **Target**: `INSERT...RETURNING productid`, `currval(pg_get_serial_sequence())`, `NOW()`, `BEGIN/COMMIT`
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @var / SET @var` pattern → Separate commands in C# transaction
  - `BEGIN TRANSACTION` → `BEGIN`
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR
- **C# Code Change**: Restructured from single SQL block to multiple commands within `BeginTransactionAsync()`

### Statement 4: UpdateProductAsync (Transaction Block with UPDATE)
- **Source**: `BEGIN TRANSACTION`, `DECLARE @OldPrice`, `SELECT INTO variables`, `UPDATE`, `INSERT INTO ProductHistory`, `GETDATE()`
- **Target**: Separate `SELECT`, `UPDATE`, `INSERT`, `UPDATE` commands with `NOW()`
- **Key Changes**:
  - `DECLARE @var / SELECT @var = col` → Separate SELECT command with DataReader
  - `GETDATE()` → `NOW()`
  - All schema objects lowercase
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR
- **C# Code Change**: Restructured to separate commands within C# transaction

### Statement 5: DeleteProductAsync (Transaction Block with DELETE)
- **Source**: `BEGIN TRANSACTION`, `DECLARE @OldPrice/@OldStock`, `SELECT INTO vars`, `INSERT INTO ProductHistory`, `DELETE FROM Products`, `CASE`, `GETDATE()`
- **Target**: Separate commands with `NOW()`, lowercase objects
- **Key Changes**:
  - `DECLARE @var / SELECT @var = col` → Separate SELECT command
  - `GETDATE()` → `NOW()`
  - All schema objects lowercase
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR
- **C# Code Change**: Restructured to separate commands within C# transaction

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE, RANK/PERCENT_RANK)
- **Source**: CTE with `RANK() OVER`, `PERCENT_RANK() OVER`, `BETWEEN`, `CASE`, `ORDER BY`
- **Target**: Same logic, lowercase schema objects
- **Key Changes**: No MS SQL-specific functions; only casing changes
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync (SELECT with CTE, AVG/MIN/MAX)
- **Source**: CTE with `AVG(StockQuantity) OVER()`, `MIN(StockQuantity) OVER()`, `MAX(StockQuantity) OVER()`, `CASE`, `ROUND`
- **Target**: Same logic with `stockquantity::numeric` cast for `ROUND` compatibility
- **Key Changes**: 
  - `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock` (explicit numeric cast for ROUND)
  - All schema objects lowercase
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

## Code Changes Summary

### Package Dependencies (AdoCore.csproj)
| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.9 |
| `Microsoft.Extensions.Configuration` v8.0.0 | No change |
| `Microsoft.Extensions.Configuration.Json` v8.0.0 | No change |
| `Microsoft.Extensions.DependencyInjection` v8.0.0 | No change |

Note: Npgsql upgraded from plan-specified v8.0.1 to v8.0.9 to resolve known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

### ADO.NET Class Replacements (ProductRepository.cs)
| MS SQL Server | PostgreSQL (Npgsql) |
|---------------|---------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### Connection String Changes (appsettings.json)
| Before | After |
|--------|-------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (PostgreSQL N/A) |
| `TrustServerCertificate=True` | Removed (PostgreSQL N/A) |

### SQL Setup Scripts
Both `Scripts/01_InitialSetup.sql` and `Database/Scripts/01_InitialSetup.sql` were converted:

| MS SQL Server | PostgreSQL |
|---------------|------------|
| `IDENTITY(1,1)` | `SERIAL` |
| `GETDATE()` | `NOW()` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `GO` | Removed |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SYSTEM_USER` | `current_user` |
| SQL Server trigger syntax | PostgreSQL trigger function + `CREATE TRIGGER` |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP IF EXISTS` / `CREATE TABLE IF NOT EXISTS` |

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Extracted SQL Statements | `sourceCode/extracted_statements.sql` | ✅ Complete (7 statements) |
| Converted SQL Statements | `sourceCode/converted_statements.sql` | ✅ Complete (7 statements) |
| SQL Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | ✅ Complete (7 pairs) |
| Migration Report | `sourceCode/migration_report.md` | ✅ Complete |

## Exit Criteria Verification

| Criterion | Status |
|-----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ Done |
| All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql | ✅ Done |
| ALL SQL statements processed through DMS MCP tool | ✅ Done (all 7 attempted, all failed) |
| Comprehensive catalog of all SQL statements | ✅ Done |
| ALL statement pairs validated through SQL Equivalency tool | ✅ Done (all 7 attempted, all returned ERROR) |
| Comprehensive equivalency report generated | ✅ Done |
| No agent judgment used for equivalency | ✅ Confirmed |
| DMS failures documented with manual conversions | ✅ Done |
| Connection strings updated to PostgreSQL format | ✅ Done |
| Transaction handling updated | ✅ Done |
| Application compiles without errors | ✅ Done (0 errors, 10 warnings) |

## Statements Requiring Manual Review

All 7 SQL statements require manual review due to:
1. DMS tool failure - manual conversion was applied
2. SQL Equivalency tool error - equivalency could not be automatically validated

**Recommended manual review actions:**
- Verify each converted PostgreSQL statement produces equivalent results when run against a PostgreSQL database
- Test transaction blocks (Insert, Update, Delete) end-to-end with actual data
- Verify window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) return same results
- Validate the `INSERT...RETURNING` pattern works correctly with the Npgsql ExecuteScalarAsync() call
