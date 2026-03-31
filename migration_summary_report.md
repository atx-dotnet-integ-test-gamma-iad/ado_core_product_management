# Migration Summary Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-03-31
- **Migration Method**: Manual conversion with lowercase schema (DMS tool unavailable)

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 10.0.2 |
| `appsettings.json` | Connection strings converted to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full DDL/DML/SP/Trigger conversion to PostgreSQL |
| `Scripts/01_InitialSetup.sql` | Full DDL/SP conversion to PostgreSQL |

## New Artifacts Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report (9 statements) |
| `dms_conversion_log.txt` | Detailed DMS tool output log |
| `migration_summary_report.md` | This report |

## SQL Statement Processing Summary

### DMS Tool Results
- **Total statements processed through DMS**: 9 (7 from ProductRepository.cs + 2 from setup scripts)
- **Successfully converted by DMS**: 0
- **DMS failures requiring manual conversion**: 9
- **DMS failure reason**: Metadata model creation/conversion timeout (service unavailable)
- **Manual conversion method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### SQL Equivalency Tool Results
- **Total statement pairs validated**: 9
- **EQUIVALENT**: 0
- **NOT_EQUIVALENT**: 0
- **ERROR**: 9 (all returned error: "'uniqueID'" - tool service issue)

### Statement-by-Statement Summary

| # | Source Method | Key Conversions | Equivalency |
|---|-------------|-----------------|-------------|
| 1 | GetAllProductsAsync | CTE + window functions - lowercased schema | ERROR |
| 2 | GetProductByIdAsync | CTE + LAG - lowercased schema | ERROR |
| 3 | InsertProductAsync | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), transaction → writable CTE | ERROR |
| 4 | UpdateProductAsync | DECLARE → writable CTE with subqueries, GETDATE() → NOW() | ERROR |
| 5 | DeleteProductAsync | DECLARE → writable CTE with subqueries, GETDATE() → NOW() | ERROR |
| 6 | GetProductsByPriceRangeAsync | RANK/PERCENT_RANK preserved, lowercased | ERROR |
| 7 | GetLowStockProductsAsync | AVG/MIN/MAX window functions, CAST for integer division | ERROR |
| 8 | DDL - CREATE TABLE | IDENTITY → SERIAL, nvarchar → VARCHAR, bit → BOOLEAN, datetime → TIMESTAMP | ERROR |
| 9 | DML - UPDATE Stats | GETDATE() → NOW(), IsDiscontinued = 1 → isdiscontinued = TRUE | ERROR |

## Package Dependency Changes

| Original | Replacement | Notes |
|----------|------------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 10.0.2 | Plan specified 8.0.1 but had CVE GHSA-x9vc-6hfv-hg8c; upgraded to 10.0.2 |

## ADO.NET Class Replacements

| Original | Replacement | Count |
|----------|------------|-------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, constructor, return type) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (N/A) |
| TLS | `TrustServerCertificate=True` | Removed |
| Timeouts | (defaults) | `Timeout=30;Command Timeout=30` |

## Database Script Conversions

### DDL Conversions
- `[int] IDENTITY(1,1)` → `SERIAL`
- `[nvarchar](n)` → `VARCHAR(n)`
- `[bit]` → `BOOLEAN`
- `[datetime]` → `TIMESTAMP`
- `[dbo].[TableName]` → `tablename` (lowercase)
- `GETDATE()` → `NOW()`
- `DEFAULT 1` / `DEFAULT 0` for bit → `DEFAULT TRUE` / `DEFAULT FALSE`
- `GO` batch separators → Removed
- `USE DatabaseName` → Removed
- `IF NOT EXISTS (SELECT * FROM sys.objects...)` → `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS`

### Stored Procedure → Function Conversions
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION ... RETURNS ... AS $$ ... $$ LANGUAGE plpgsql`
- `SET NOCOUNT ON` → Removed
- `SCOPE_IDENTITY()` → `RETURNING ... INTO`
- `EXEC sp_InsertProduct` → `PERFORM sp_insertproduct()`

### Trigger Conversions
- SQL Server `AFTER INSERT, UPDATE, DELETE` trigger → PostgreSQL trigger function + trigger
- `inserted`/`deleted` pseudo-tables → `NEW`/`OLD` variables with `TG_OP` check
- `SYSTEM_USER` → `current_user`

## Build Verification
- **Build Status**: ✅ SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, not migration-related)
- **Vulnerable Packages**: 0 (verified with `dotnet list --vulnerable`)

## Items Requiring Manual Review

1. **SQL Equivalency Validation**: All 9 statement pairs returned ERROR from the equivalency tool (consistent 'uniqueID' error). Manual review of converted statements is recommended to verify logical equivalence.

2. **DMS Tool Failures**: The DMS MCP tool was unavailable for all conversion attempts. All conversions were done manually with lowercase schema mapping. If DMS becomes available, re-running conversions is recommended.

3. **Connection String Credentials**: The PostgreSQL connection strings use placeholder credentials (`postgres/postgres`). Production deployment should use environment variables or a secrets manager.

4. **Writable CTEs**: The transaction blocks (Insert/Update/Delete) were converted to PostgreSQL writable CTEs instead of DO $$ blocks to maintain ADO.NET parameter binding compatibility. These should be tested against an actual PostgreSQL database to verify correct execution order.

5. **Integer Division**: Statement 7 (GetLowStockProductsAsync) added an explicit `CAST(stockquantity AS DECIMAL)` to prevent integer division truncation, which may produce slightly different results than the original SQL Server behavior.
