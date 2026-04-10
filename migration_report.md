# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET class references from `Microsoft.Data.SqlClient` to `Npgsql`, and updating connection strings and configuration.

**Migration Date:** 2026-04-10  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 (ADO.NET)

---

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Package reference: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.0` |
| `DataAccess/ProductRepository.cs` | SQL statements converted, class references updated |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

## Files Not Modified

| File | Reason |
|------|--------|
| `Program.cs` | No database-related code |
| `Business/ProductService.cs` | No database-related code |
| `CLI/CommandLineInterface.cs` | No database-related code |
| `CLI/InteractiveMenu.cs` | No database-related code |
| `Models/Product.cs` | No database-related code |
| `Scripts/01_InitialSetup.sql` | DDL script not used at runtime (requires separate PostgreSQL DDL migration) |
| `Database/Scripts/01_InitialSetup.sql` | Same DDL script |

---

## SQL Statement Conversion Summary

**Total Statements Processed:** 7  
**DMS Tool Conversion Attempts:** 9 (7 statements, with retries for statements 1 and 2)  
**DMS Tool Successes:** 0  
**DMS Tool Failures:** 7 (all failed with metadata model creation error)  
**Manual Conversions Applied:** 7 (with lowercase schema mapping per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### DMS Tool Error

All 7 statements were passed to the AWS DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following parameters:
- Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`

All attempts returned the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### Statement Conversion Details

| # | Method | Original (MS SQL) | Converted (PostgreSQL) | Key Changes |
|---|--------|-------------------|----------------------|-------------|
| 1 | GetAllProductsAsync | CTE with AVG/COUNT OVER, INNER JOIN | CTE with lowercase schema | Schema objects lowercased |
| 2 | GetProductByIdAsync | CTE with LAG window function | CTE renamed to producthistory_cte | CTE alias renamed to avoid table conflict |
| 3 | InsertProductAsync | Transaction with SCOPE_IDENTITY(), GETDATE() | 3 separate commands with RETURNING, NOW() | SCOPE_IDENTITY() → RETURNING productid; Transaction managed in C# |
| 4 | UpdateProductAsync | Transaction with DECLARE, GETDATE() | 4 separate commands with NOW() | Variables managed in C#; GETDATE() → NOW() |
| 5 | DeleteProductAsync | Transaction with DECLARE, GETDATE() | 4 separate commands with NOW() | Variables managed in C#; GETDATE() → NOW() |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK/PERCENT_RANK | CTE with lowercase schema | Schema objects lowercased |
| 7 | GetLowStockProductsAsync | CTE with AVG/MIN/MAX OVER | CTE with CAST for integer division | Added CAST(stockquantity AS NUMERIC) |

### SQL Equivalency Validation

**Tool Used:** `sql-equivalency___validate_sql_equivalence`  
**Total Pairs Validated:** 7  
**Equivalent:** 0  
**Not Equivalent:** 0  
**Error:** 7  

All 7 equivalency validation attempts returned an error:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a systematic tool issue unrelated to the SQL statements themselves. All results are documented in `sql_equivalency_validation_report.json`.

---

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.0 |
| `Microsoft.Extensions.Configuration` 8.0.0 | (unchanged) |
| `Microsoft.Extensions.Configuration.Json` 8.0.0 | (unchanged) |
| `Microsoft.Extensions.DependencyInjection` 8.0.0 | (unchanged) |

---

## Class Mapping

| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` (cast) | `NpgsqlTransaction` (native) |
| `ConnectionState` (System.Data) | `ConnectionState` (unchanged) |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - N/A) |
| Certificate | `TrustServerCertificate=True` | (removed - N/A) |

---

## Manual Interventions Required

1. **All SQL statements required manual conversion** due to DMS tool failure. Conversion applied lowercase schema object naming convention for PostgreSQL compatibility.

2. **Transaction management restructured** for statements 3, 4, and 5 (Insert, Update, Delete):
   - SQL Server pattern: Single SQL string with `BEGIN TRANSACTION`/`COMMIT`, `DECLARE @var`, `SCOPE_IDENTITY()`
   - PostgreSQL pattern: Multiple SQL commands managed by C# `NpgsqlTransaction` with `RETURNING`, `NOW()`

3. **Statement 2 CTE alias renamed**: `ProductHistory` → `producthistory_cte` to avoid conflict with the `producthistory` table name.

4. **Statement 7 integer division fix**: Added `CAST(stockquantity AS NUMERIC)` for PostgreSQL's strict integer division behavior.

---

## Known Issues & Items Requiring Manual Review

1. **SQL Equivalency Tool Errors**: All 7 statement pairs returned ERROR from the equivalency tool. Manual review of converted statements is recommended.

2. **Connection String Credentials**: The PostgreSQL connection strings use generic placeholder credentials (`Username=postgres;Password=postgres`). These should be updated with actual credentials in a production deployment, preferably using environment variables or a secrets manager.

3. **Database Schema Migration**: The `Scripts/01_InitialSetup.sql` file contains SQL Server DDL (CREATE TABLE, stored procedures, triggers) that needs separate PostgreSQL DDL migration. This script is not used by the application at runtime.

4. **MapProductFromReader Column Names**: The reader column access uses mixed-case names (e.g., `reader["ProductId"]`). PostgreSQL returns lowercase column names by default. If the database schema uses lowercase column names (as expected after migration), these access patterns should work correctly since PostgreSQL is case-insensitive for unquoted identifiers, but they may need adjustment if the actual column names differ.

---

## Build Status

**Final Build:** ✅ SUCCESS  
**Errors:** 0  
**Warnings:** 12 (pre-existing nullable reference warnings, not introduced by migration)

---

## Artifacts

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report with all 7 statement pairs |
| `migration_report.md` | This report |
