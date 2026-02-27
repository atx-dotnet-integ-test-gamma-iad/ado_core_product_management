# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Category | Count |
|----------|-------|
| **Total SQL Statements Processed** | 20 |
| **Application Code Statements** | 7 |
| **Database Script Statements** | 13 |
| **Successfully Converted by DMS** | 0 |
| **Manually Converted (DMS Failure)** | 20 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 20 |

## DMS Tool Status

**All DMS conversion attempts failed** with the same error across all statements:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Total DMS Attempts**: 9 (7 application statements + 2 script statements)
- **All attempts returned error status**

Due to DMS failure, all conversions were performed manually following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach as specified in the transformation rules.

## SQL Equivalency Tool Status

**All equivalency validation attempts returned ERROR** with the same error:
- **Error**: `'uniqueID'`
- **Total Validation Attempts**: 19 (7 application + 12 script statement pairs)
- **All returned `equivalence_status: ERROR`**

This appears to be a systematic tool-side issue, not related to the quality of the conversions.

## Application Code Changes

### ProductRepository.cs (7 SQL Statements)

| # | Method | Key Conversions |
|---|--------|----------------|
| 1 | GetAllProductsAsync | CTE with window functions - lowercase schema objects |
| 2 | GetProductByIdAsync | LAG window function, parameterized query - lowercase schema |
| 3 | InsertProductAsync | SCOPE_IDENTITY() → INSERT...RETURNING via CTE, GETDATE() → NOW() |
| 4 | UpdateProductAsync | DECLARE/SET → CTE with old_values, GETDATE() → NOW() |
| 5 | DeleteProductAsync | Transaction block → CTE with data-modifying statements |
| 6 | GetProductsByPriceRangeAsync | RANK()/PERCENT_RANK() - lowercase schema |
| 7 | GetLowStockProductsAsync | AVG/MIN/MAX window functions, ::NUMERIC cast for integer division |

### ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|--------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (not used in codebase) |

### Package Dependencies

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |

Note: Npgsql 8.0.6 used instead of 8.0.1 due to known high severity vulnerability (GHSA-x9vc-6hfv-hg8c) in 8.0.1.

### Connection Strings

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

## Database Script Changes

### Scripts/01_InitialSetup.sql (Simple Script)
- CREATE TABLE with IF NOT EXISTS → PostgreSQL CREATE TABLE IF NOT EXISTS
- IDENTITY(1,1) → SERIAL
- nvarchar → VARCHAR
- datetime → TIMESTAMP
- GETDATE() → NOW()
- 5 Stored Procedures → 5 PostgreSQL Functions (plpgsql)
- SCOPE_IDENTITY() → RETURNING clause
- GO statements removed
- Sample data INSERT via function calls → PERFORM calls in DO block

### Database/Scripts/01_InitialSetup.sql (Comprehensive Script)
- 5 CREATE TABLE statements converted (Categories, Suppliers, Products, ProductHistory, ProductStats)
- bit → BOOLEAN (0/1 → FALSE/TRUE)
- 5 CREATE INDEX statements converted (lowercase names)
- Sample data INSERTs converted (lowercase columns)
- UPDATE ProductStats with subqueries converted
- Trigger: AFTER INSERT/UPDATE/DELETE → PostgreSQL trigger function + trigger
  - `inserted`/`deleted` → `NEW`/`OLD` with `TG_OP`
  - `SYSTEM_USER` → `current_user`
- 5 Stored Procedures → 5 PostgreSQL Functions
- All IF EXISTS/IF NOT EXISTS patterns → PostgreSQL equivalents
- All GO statements removed

## SQL Type Mappings Applied

| SQL Server Type | PostgreSQL Type |
|----------------|-----------------|
| `int IDENTITY(1,1)` | `SERIAL` |
| `nvarchar(n)` | `VARCHAR(n)` |
| `varchar(n)` | `VARCHAR(n)` |
| `decimal(p,s)` | `NUMERIC(p,s)` |
| `datetime` | `TIMESTAMP` |
| `bit` | `BOOLEAN` |

## Function/Syntax Mappings Applied

| SQL Server | PostgreSQL |
|-----------|------------|
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` |
| `SYSTEM_USER` | `current_user` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SET NOCOUNT ON` | Removed (not applicable) |
| `GO` | Removed (not applicable) |
| `BEGIN TRANSACTION/COMMIT` | PostgreSQL CTE with data-modifying statements |

## Build Status

- **Final build**: ✅ **SUCCESS** (0 errors)
- Warnings: Pre-existing nullable reference warnings only (CS8601, CS8618, etc.)

## Artifacts

| Artifact | Location |
|----------|----------|
| Original SQL Statements Catalog | `sourceCode/extracted_statements.sql` |
| Converted SQL Statements Catalog | `sourceCode/converted_statements.sql` |
| SQL Equivalency Validation Report | `sourceCode/sql_equivalency_validation_report.json` |
| DMS Failure Summary | `sourceCode/dms_failure_summary.md` |
| Migration Report | `sourceCode/migration_report.md` |

## Statements Requiring Manual Review

**All 20 statements require manual review** because:
1. DMS tool was unavailable (metadata model creation failed for all attempts)
2. SQL Equivalency tool returned errors for all validation attempts
3. Manual conversion was applied following lowercase schema naming conventions

### Priority Review Items:
1. **Transaction blocks (Statements 3, 4, 5)**: These were restructured from T-SQL DECLARE/SET patterns to PostgreSQL CTEs with data-modifying statements. The semantic behavior should be verified with integration tests.
2. **Trigger conversion (Statement 18)**: The trigger was converted from T-SQL `inserted`/`deleted` pseudo-tables to PostgreSQL `NEW`/`OLD` record variables. Row-level vs. statement-level behavior should be verified.
3. **Integer division in ROUND (Statement 7)**: Added `::NUMERIC` cast for integer division to prevent truncation.

## Conclusion

The migration has been completed with all code changes applied:
- All SQL statements converted to PostgreSQL syntax
- All ADO.NET classes replaced with Npgsql equivalents
- All connection strings updated to PostgreSQL format
- All database scripts converted to PostgreSQL syntax
- Application builds successfully with 0 errors

Both the DMS conversion tool and SQL Equivalency validation tool experienced systematic errors during this migration. All conversions were performed manually following established SQL Server → PostgreSQL migration patterns with lowercase schema naming conventions as required by the transformation rules.
