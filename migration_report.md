# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-30 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Target Framework** | .NET 9.0 |

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failure)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`). All failed with:
- **Error**: `AccessDeniedException` - IAM role lacks `dms:StartMetadataModelCreation` permission
- **Migration Project**: `NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Manual Conversion Applied**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with error `'uniqueID'`. This appears to be a tool infrastructure issue, not a statement-level problem.

## File Changes Summary

### 1. AdoCore.csproj
- **Change**: Package reference update
- **Before**: `Microsoft.Data.SqlClient` Version `5.1.4`
- **After**: `Npgsql` Version `8.0.6`

### 2. DataAccess/ProductRepository.cs
- **Import Change**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Class Replacements**:
  - `SqlConnection` → `NpgsqlConnection` (3 occurrences)
  - `SqlCommand` → `NpgsqlCommand` (15 occurrences)
  - `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
  - `SqlTransaction` → `NpgsqlTransaction` (11 occurrences)
- **SQL Statement Changes** (7 statements converted):
  - All table/column names converted to lowercase
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE`/`SET` variable patterns → Separate SQL statements with C# managed transactions
  - Transaction blocks restructured from single batch to individual statements with `BeginTransactionAsync`/`CommitAsync`/`RollbackAsync`

### 3. appsettings.json
- **Connection String Changes**:
  - `Server=localhost` → `Host=localhost`
  - Removed: `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
  - Added: `Username=postgres;Password=postgres`

### 4. Database/Scripts/01_InitialSetup.sql
- **DDL Changes**:
  - Removed `GO` statements
  - Removed `[dbo].` schema prefixes and bracket quoting
  - `IDENTITY(1,1)` → `serial`
  - `nvarchar` → `varchar`
  - `datetime` → `timestamp`
  - `bit` → `boolean`
  - `GETDATE()` → `NOW()`
  - SQL Server `IF NOT EXISTS (SELECT * FROM sys.objects...)` → `DROP TABLE IF EXISTS`
  - SQL Server `CREATE TRIGGER...AS BEGIN...END` → PostgreSQL `CREATE FUNCTION...RETURNS TRIGGER` + `CREATE TRIGGER`
  - `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
  - `SYSTEM_USER` → `current_user`

### 5. Scripts/01_InitialSetup.sql
- Same type of changes as Database/Scripts/01_InitialSetup.sql

### 6. README.md
- Updated all references from SQL Server to PostgreSQL
- Updated connection string examples
- Updated prerequisite software list
- Updated troubleshooting section

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
| Field | Value |
|-------|-------|
| **Source Method** | `GetAllProductsAsync()` |
| **Complexity** | Hard (CTE, window functions, CASE, ROUND, JOIN) |
| **DMS Status** | Failed (AccessDeniedException) |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR |
| **Changes** | All schema objects lowercased |

### Statement 2: GetProductByIdAsync
| Field | Value |
|-------|-------|
| **Source Method** | `GetProductByIdAsync(int productId)` |
| **Complexity** | Hard (CTE, LAG window function, LEFT JOIN, CASE, ROUND) |
| **DMS Status** | Failed (AccessDeniedException) |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR |
| **Changes** | All schema objects lowercased |

### Statement 3: InsertProductAsync
| Field | Value |
|-------|-------|
| **Source Method** | `InsertProductAsync(Product product)` |
| **Complexity** | Medium (INSERT, SCOPE_IDENTITY, transaction block) |
| **DMS Status** | Failed (AccessDeniedException) |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR |
| **Changes** | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), restructured to multi-statement C# transaction |

### Statement 4: UpdateProductAsync
| Field | Value |
|-------|-------|
| **Source Method** | `UpdateProductAsync(Product product)` |
| **Complexity** | Medium (UPDATE, DECLARE, SELECT INTO, transaction block) |
| **DMS Status** | Failed (AccessDeniedException) |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR |
| **Changes** | GETDATE() → NOW(), DECLARE/SET → separate SELECT, restructured to multi-statement C# transaction |

### Statement 5: DeleteProductAsync
| Field | Value |
|-------|-------|
| **Source Method** | `DeleteProductAsync(int productId)` |
| **Complexity** | Medium (DELETE, DECLARE, CASE, transaction block) |
| **DMS Status** | Failed (AccessDeniedException) |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR |
| **Changes** | GETDATE() → NOW(), DECLARE/SET → separate SELECT, restructured to multi-statement C# transaction |

### Statement 6: GetProductsByPriceRangeAsync
| Field | Value |
|-------|-------|
| **Source Method** | `GetProductsByPriceRangeAsync(decimal, decimal)` |
| **Complexity** | Hard (CTE, RANK, PERCENT_RANK, BETWEEN, CASE) |
| **DMS Status** | Failed (AccessDeniedException) |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR |
| **Changes** | All schema objects lowercased |

### Statement 7: GetLowStockProductsAsync
| Field | Value |
|-------|-------|
| **Source Method** | `GetLowStockProductsAsync(int threshold)` |
| **Complexity** | Hard (CTE, AVG/MIN/MAX window functions, CASE, ROUND) |
| **DMS Status** | Failed (AccessDeniedException) |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR |
| **Changes** | All schema objects lowercased, added CAST for integer division |

## Artifacts Produced

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements with source locations |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive JSON report with all 7 statement pairs and tool output |
| `dms_failure_summary.md` | Detailed DMS failure log with timestamps for all 7 submissions |
| `migration_report.md` | This report |

## Build Status
- **Final Build**: ✅ **SUCCEEDED** (0 errors, warnings only)
- **Framework**: .NET 9.0
- **Package Restore**: ✅ Npgsql 8.0.6 resolved from NuGet

## Recommendations for Manual Review
1. All 7 SQL equivalency validations returned ERROR from the tool - manual verification of SQL logic equivalence is recommended
2. The DMS tool was unavailable due to IAM permissions - once permissions are fixed, re-running DMS conversion could validate the manual conversions
3. Transaction restructuring (Statements 3, 4, 5) changed from single-batch SQL to multi-statement C# managed transactions - verify behavior under concurrent access
4. Connection string credentials in appsettings.json use placeholder values - update for production deployment
