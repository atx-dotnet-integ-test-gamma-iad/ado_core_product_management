# Migration Report: MS SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 44 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 44 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation error | 44 |

## DMS Tool Status
**Status: FAILED for all statements**

The AWS DMS MCP Statement Conversion Tool was attempted for all 44 SQL statements. Every attempt failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

9 distinct DMS API calls were made to confirm the persistent failure across different statement types (SELECT, INSERT, UPDATE, DELETE, CREATE TABLE, transaction blocks).

## SQL Equivalency Tool Status
**Status: ERROR for all statement pairs**

The SQL Equivalency Validation Tool was invoked for all 44 statement pairs. Every invocation returned:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a service-side issue unrelated to the SQL content. Per the transformation guidelines, all equivalency statuses are marked as ERROR (no agent judgment was applied).

## Conversion Methodology
Since DMS failed for all statements, manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol:

### Key Conversion Rules Applied
| MS SQL Server | PostgreSQL |
|---------------|-----------|
| `IDENTITY(1,1)` | `serial` |
| `nvarchar(n)` | `varchar(n)` |
| `datetime` | `timestamp` |
| `bit` | `boolean` |
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `SYSTEM_USER` | `CURRENT_USER` |
| `[dbo].[TableName]` | `tablename` (lowercase) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql` |
| `BEGIN TRANSACTION/COMMIT` (T-SQL) | C# managed transactions |
| `DECLARE @Var / SET @Var` | `DO $$ DECLARE v_var ... END $$` or C# variables |
| `IF EXISTS (sys.objects)` | `DROP TABLE IF EXISTS` |
| T-SQL triggers (`inserted`/`deleted`) | PostgreSQL trigger functions (`NEW`/`OLD`, `TG_OP`) |
| `GO` batch separators | Removed |
| `DEFAULT 1` (bit) | `DEFAULT true` (boolean) |
| `DEFAULT 0` (bit) | `DEFAULT false` (boolean) |
| `IsDiscontinued = 1` | `isdiscontinued = true` |

## Files Modified

### Source Code Files
1. **DataAccess/ProductRepository.cs**
   - Replaced 7 inline MS SQL statements with PostgreSQL equivalents
   - Replaced `using Microsoft.Data.SqlClient` → `using Npgsql`
   - Replaced `SqlConnection` → `NpgsqlConnection` (3 occurrences)
   - Replaced `SqlCommand` → `NpgsqlCommand` (15 occurrences)
   - Replaced `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
   - Replaced `SqlTransaction` → `NpgsqlTransaction` (3 occurrences)
   - Restructured transaction blocks (Insert, Update, Delete) from single T-SQL batch to C# managed transactions
   - Updated `MapProductFromReader` to use lowercase column names

2. **AdoCore.csproj**
   - Replaced `Microsoft.Data.SqlClient` (5.1.4) → `Npgsql` (8.0.6)

3. **appsettings.json**
   - Converted connection strings from SQL Server to PostgreSQL format
   - `Server=` → `Host=`
   - Added `Port=5432`
   - Removed SQL Server-specific parameters
   - Added PostgreSQL authentication parameters

### SQL Script Files
4. **Scripts/01_InitialSetup.sql**
   - Converted from T-SQL to PostgreSQL syntax
   - Removed `GO` batch separators
   - Converted `CREATE OR ALTER PROCEDURE` to `CREATE OR REPLACE FUNCTION`
   - Replaced `SCOPE_IDENTITY()` with `RETURNING`
   - Replaced data types and functions

5. **Database/Scripts/01_InitialSetup.sql**
   - Full conversion of extended schema (Categories, Suppliers, Products, ProductHistory, ProductStats)
   - Converted trigger from T-SQL to PostgreSQL trigger function
   - Converted all stored procedures to PostgreSQL functions
   - Converted all DDL, indexes, and DML statements

### Migration Artifacts
6. **extracted_statements.sql** - Catalog of all 44 original MS SQL statements
7. **converted_statements.sql** - Catalog of all 44 converted PostgreSQL statements
8. **sql_equivalency_validation_report.json** - Detailed equivalency report for all 44 statement pairs
9. **migration_report.md** - This report

## Build Status
**Build: SUCCESS** (0 Errors, 10 Warnings)

All warnings are pre-existing nullable reference warnings, not introduced by the migration.

## Statement-Level Details
For detailed statement-level conversion and equivalency information, see: `sql_equivalency_validation_report.json`

## Manual Review Recommendations
1. All 44 statement equivalency validations returned ERROR due to tool unavailability - manual SQL review is recommended
2. Connection string credentials in appsettings.json are placeholder values - replace with actual PostgreSQL credentials
3. The `RETURNING` clause for `INSERT` in PostgreSQL is a structural change from T-SQL `SCOPE_IDENTITY()` - verify behavior matches expectations
4. Integer division in PostgreSQL may behave differently - `CAST(stockquantity AS DECIMAL)` was added for the `GetLowStockProductsAsync` query
5. Transaction handling was restructured from single T-SQL batch to C# managed transactions - verify atomicity is preserved
