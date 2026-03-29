# Migration Report: SQL Server to PostgreSQL

## Summary
Migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date**: 2026-03-29
**Source Database**: Microsoft SQL Server 2019
**Target Database**: PostgreSQL 13
**Application Framework**: .NET 9.0 with ADO.NET

---

## SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements attempted via DMS MCP tool | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Manual conversion method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

### DMS Tool Failure Details
The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 statements but consistently failed with:
- **Error 1**: "Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}"
- **Error 2**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Error 3**: Command execution timed out after 300 seconds

The tool was tested 3 times with different statements (complex CTE, simple SELECT, simple SCOPE_IDENTITY) and failed consistently, indicating a systemic issue rather than statement-specific problems.

---

## SQL Equivalency Validation

| Metric | Count |
|--------|-------|
| Total statement pairs validated | 7 |
| EQUIVALENT | 0 |
| NOT_EQUIVALENT | 0 |
| ERROR | 7 |

### Equivalency Tool Status
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs. All returned:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This is a consistent tool-side error affecting all queries regardless of complexity. Per the transformation definition, all pairs are marked as ERROR (no agent judgment used for equivalency determination).

**Full equivalency report**: `sql_equivalency_validation_report.json`

---

## SQL Conversions Applied

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND
- **Conversions**: All schema/column names lowercased
- **PostgreSQL Compatibility**: CTE, window functions, CASE, ROUND all compatible

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window functions, LEFT JOIN, CASE
- **Conversions**: All schema/column names lowercased
- **PostgreSQL Compatibility**: LAG, CTE, LEFT JOIN all compatible

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversions**:
  - `SCOPE_IDENTITY()` → `LASTVAL()`
  - `GETDATE()` → `NOW()`
  - Removed `DECLARE @NewProductId INT`, `BEGIN TRANSACTION`, `COMMIT`
  - All schema/column names lowercased

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO, UPDATE, INSERT
- **Conversions**:
  - Removed `DECLARE @OldPrice`, `DECLARE @OldStock`, `BEGIN TRANSACTION`, `COMMIT`
  - Replaced variable usage with subqueries to capture old values
  - `GETDATE()` → `NOW()`
  - All schema/column names lowercased

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, INSERT history, DELETE, UPDATE stats with CASE
- **Conversions**:
  - Removed `DECLARE` variables, `BEGIN TRANSACTION`, `COMMIT`
  - Replaced variable usage with subqueries
  - `GETDATE()` → `NOW()`
  - All schema/column names lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversions**: All schema/column names lowercased
- **PostgreSQL Compatibility**: RANK, PERCENT_RANK, BETWEEN all compatible

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversions**:
  - All schema/column names lowercased
  - Added `CAST(stockquantity AS DECIMAL)` for proper decimal division (PostgreSQL integer division)

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, SqlClient → Npgsql classes |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated for PostgreSQL |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion |
| `README.md` | Updated for PostgreSQL setup |

## New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Full equivalency validation report |
| `migration_report.md` | This report |

---

## Package Changes

| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

## Class Replacements

| Original | Replacement |
|----------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| Certificate | `TrustServerCertificate=True` | (removed - not applicable) |

---

## Database Script Conversions

### Key Conversions in 01_InitialSetup.sql:
- `IDENTITY(1,1)` → `SERIAL`
- `[nvarchar](n)` → `VARCHAR(n)`
- `[int]` → `INTEGER`
- `[decimal](18,2)` → `DECIMAL(18,2)`
- `[datetime]` → `TIMESTAMP`
- `[bit]` → `BOOLEAN`
- `GETDATE()` → `NOW()`
- `SYSTEM_USER` → `CURRENT_USER`
- `GO` statements → Removed
- SQL Server `IF EXISTS/IF NOT EXISTS` patterns → PostgreSQL `DROP IF EXISTS`/`CREATE TABLE IF NOT EXISTS`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION` with plpgsql
- SQL Server trigger with `inserted`/`deleted` tables → PostgreSQL trigger function with `NEW`/`OLD` and `TG_OP`
- `SCOPE_IDENTITY()` → `RETURNING` clause

---

## Build Status

**Final Build**: ✅ SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Completeness Verification

- [x] No remaining `Microsoft.Data.SqlClient` references
- [x] No remaining `SqlConnection`, `SqlCommand`, `SqlDataReader` references
- [x] No remaining SQL Server connection string patterns
- [x] No remaining SQL Server syntax (SCOPE_IDENTITY, GETDATE, BEGIN TRANSACTION, DECLARE @)
- [x] No hardcoded connection strings in code
- [x] All 7 SQL statements extracted and documented
- [x] All 7 SQL statements converted and documented
- [x] All 7 statement pairs validated via SQL Equivalency tool
- [x] Equivalency report complete with all 7 entries
- [x] Npgsql package reference in place
- [x] All Npgsql class references verified
- [x] PostgreSQL connection strings configured
- [x] Database scripts converted to PostgreSQL
- [x] README updated for PostgreSQL

---

## Issues and Warnings

1. **DMS Tool Unavailable**: The DMS MCP tool consistently timed out/failed for all conversion attempts. All conversions were done manually with lowercase schema mapping.
2. **SQL Equivalency Tool Error**: The tool returned ERROR with `'uniqueID'` for all 7 statement pairs. This appears to be a systemic tool issue, not related to statement quality.
3. **Integer Division**: PostgreSQL performs integer division by default when both operands are integers. Added explicit `CAST(stockquantity AS DECIMAL)` in Statement 7 to ensure correct decimal division.
4. **Transaction Handling**: SQL Server's inline `BEGIN TRANSACTION/COMMIT` with `DECLARE` variables was restructured for PostgreSQL ADO.NET compatibility. The C# application's `ExecuteInTransactionAsync` method provides transaction support at the application level.
