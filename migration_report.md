# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-06 |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Application Framework** | .NET 9.0, ADO.NET |
| **Original Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 18 |
| Statements from ProductRepository.cs | 7 |
| Statements from SQL setup scripts | 11 |
| DMS Tool conversion successes | 0 |
| DMS Tool conversion failures | 18 |
| Manual conversions applied | 18 |
| Equivalency validations performed | 18 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 18 |

## DMS Tool Status

The AWS DMS MCP tool (dms-mcp___statement_conversion_tool) was consistently unavailable throughout the migration. All attempts failed at the metadata model creation or conversion stage with timeout errors.

### DMS Failure Details
- **Error Type**: Metadata model creation/conversion timeout
- **Error Message**: "Metadata model creation/conversion did not complete after N attempts"
- **Attempts Made**: 4 separate attempts with different configurations
- **Configurations Tried**:
  - Default (15 poll attempts, 10s interval)
  - Extended (30 poll attempts, 15s interval) - timed out at 300s
  - Medium (25 poll attempts, 8s interval)
  - Default with simple SQL statement

### Fallback Applied
Per the transformation definition, when DMS fails, manual conversion with lowercase schema object names was applied. Conversion method documented as: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR for all 18 statement pairs with the error: `'uniqueID'`. This appears to be a systematic tool issue unrelated to the SQL statements themselves.

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR." All statements are marked as ERROR.

## Files Modified

### Source Code Changes

| File | Change Type | Description |
|------|------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | Replaced all SQL statements, ADO.NET types, and using directive |
| `AdoCore.csproj` | Modified | Replaced Microsoft.Data.SqlClient with Npgsql 8.0.6 |
| `appsettings.json` | Modified | Updated connection strings from SQL Server to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted full setup script to PostgreSQL |
| `Scripts/01_InitialSetup.sql` | Modified | Converted simple setup script to PostgreSQL |

### New Files Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements from ProductRepository.cs |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `dms_conversion_log.md` | Detailed DMS tool attempt log |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 18 statement pairs |
| `migration_report.md` | This migration report |

## Key Conversions Applied

### SQL Syntax Conversions
| SQL Server | PostgreSQL | Applied In |
|-----------|-----------|------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` / `lastval()` | ProductRepository.cs, Scripts |
| `GETDATE()` | `NOW()` | All SQL statements |
| `BEGIN TRANSACTION / COMMIT` | Managed via `NpgsqlTransaction` in C# | ProductRepository.cs |
| `DECLARE @var TYPE; SET @var =` | Separate SELECT queries in C# | ProductRepository.cs |
| `IDENTITY(1,1)` | `SERIAL` | Setup scripts |
| `NVARCHAR(N)` | `VARCHAR(N)` | Setup scripts |
| `BIT` | `BOOLEAN` | Setup scripts |
| `DATETIME` | `TIMESTAMP` | Setup scripts |
| `DEFAULT 1` (BIT) | `DEFAULT TRUE` | Setup scripts |
| `DEFAULT 0` (BIT) | `DEFAULT FALSE` | Setup scripts |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql` | Setup scripts |
| `SYSTEM_USER` | `CURRENT_USER` | Trigger function |
| `GO` statements | Removed | Setup scripts |
| T-SQL trigger syntax | PostgreSQL trigger + function | Setup scripts |
| Integer division in `ROUND()` | `CAST(... AS NUMERIC)` | ProductRepository.cs |

### ADO.NET Type Conversions
| SQL Server Type | PostgreSQL Type |
|----------------|-----------------|
| `Microsoft.Data.SqlClient` (using) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Conversions
| SQL Server Parameter | PostgreSQL Equivalent |
|---------------------|----------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed |

## Build Status

**Final build: SUCCESS** (0 errors, 10 warnings - all nullable reference warnings from original code)

## Transaction Handling Changes

The original SQL Server code used embedded `BEGIN TRANSACTION / COMMIT` blocks within single SQL command strings. For PostgreSQL via Npgsql, the transaction handling was restructured:

1. **InsertProductAsync**: Split into 3 separate `NpgsqlCommand` executions within an `NpgsqlTransaction`:
   - INSERT with RETURNING for new product ID
   - INSERT into producthistory
   - UPDATE productstats

2. **UpdateProductAsync**: Split into 4 separate `NpgsqlCommand` executions within an `NpgsqlTransaction`:
   - SELECT to capture old values
   - UPDATE products
   - INSERT into producthistory
   - UPDATE productstats

3. **DeleteProductAsync**: Split into 4 separate `NpgsqlCommand` executions within an `NpgsqlTransaction`:
   - SELECT to capture old values
   - INSERT into producthistory
   - DELETE from products
   - UPDATE productstats

## Manual Interventions

All 18 SQL statements required manual intervention due to DMS tool unavailability. Each was manually converted applying:
- Lowercase schema object names for PostgreSQL compatibility
- Documented with reason: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## Security Notes

- Npgsql 8.0.6 chosen over 8.0.1 due to known high severity vulnerability (GHSA-x9vc-6hfv-hg8c) in 8.0.1
- Connection string credentials are placeholder values; production credentials should be managed via environment variables or secure configuration
