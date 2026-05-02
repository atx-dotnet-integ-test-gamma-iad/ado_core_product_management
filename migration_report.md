# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore - .NET ADO.NET Product Management Application
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-05-02
- **Framework**: .NET 9.0 with ADO.NET

---

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed (inline code) | 7 |
| Total SQL statements processed (scripts) | 2 |
| **Total SQL statements processed** | **9** |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 9 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 9 |

---

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was called for **every** SQL statement as required. All calls failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

Per the transformation definition, manual conversion was applied using lowercase schema object names (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for **every** statement pair as required. All calls returned ERROR:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation definition, all statements are marked as ERROR (not substituted with agent judgment).

---

## Files Modified

### 1. sourceCode/DataAccess/ProductRepository.cs
**Changes:**
- Replaced `using Microsoft.Data.SqlClient` with `using Npgsql`
- Replaced `SqlConnection` → `NpgsqlConnection` (3 occurrences)
- Replaced `SqlCommand` → `NpgsqlCommand` (7 occurrences)
- Replaced `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
- Replaced all 7 SQL statements with PostgreSQL equivalents:

| # | Method | Key Conversions |
|---|--------|----------------|
| 1 | GetAllProductsAsync | Lowercase schema objects |
| 2 | GetProductByIdAsync | Lowercase schema objects, LAG() preserved |
| 3 | InsertProductAsync | SCOPE_IDENTITY()→RETURNING, GETDATE()→NOW(), DECLARE/Transaction→writable CTE |
| 4 | UpdateProductAsync | DECLARE variables→writable CTE, GETDATE()→NOW() |
| 5 | DeleteProductAsync | DECLARE variables→writable CTE, GETDATE()→NOW() |
| 6 | GetProductsByPriceRangeAsync | Lowercase schema objects, RANK()/PERCENT_RANK() preserved |
| 7 | GetLowStockProductsAsync | Lowercase schema objects, added ::numeric cast for integer division |

### 2. sourceCode/AdoCore.csproj
**Changes:**
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 3. sourceCode/appsettings.json
**Changes:**
- DevConnection: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
  → `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`
- ProdConnection: Same transformation

### 4. sourceCode/Database/Scripts/01_InitialSetup.sql
**Changes:**
- `IDENTITY(1,1)` → `serial`
- `[datetime]` → `timestamp`
- `[nvarchar](N)` → `varchar(N)`
- `[bit]` → `boolean`
- `GETDATE()` → `NOW()`
- `SYSTEM_USER` → `current_user`
- SQL Server IF EXISTS/IF NOT EXISTS patterns → PostgreSQL DROP IF EXISTS/CREATE IF NOT EXISTS
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION ... RETURNS TABLE/void ... LANGUAGE plpgsql`
- SQL Server triggers → PostgreSQL trigger function + trigger
- `GO` batch separators removed
- All schema objects converted to lowercase

### 5. sourceCode/Scripts/01_InitialSetup.sql
**Changes:**
- Same type conversions as above
- `IF NOT EXISTS (SELECT * FROM sys.objects ...)` → `CREATE TABLE IF NOT EXISTS`
- `EXEC sp_InsertProduct` → `PERFORM sp_insertproduct()`
- Wrapped conditional insert in DO $$ ... END $$

---

## Transformation Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Extracted Statements | sourceCode/extracted_statements.sql | All 7 original MS SQL statements from ProductRepository.cs |
| Converted Statements | sourceCode/converted_statements.sql | All 7 converted PostgreSQL statements |
| Equivalency Report | sourceCode/sql_equivalency_validation_report.json | Comprehensive validation report for all 9 statement pairs |
| Migration Report | sourceCode/migration_report.md | This file |

---

## Build Status

- **dotnet build**: ✅ **Succeeded** (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **No remaining SQL Server references**: ✅ Verified

---

## Key Conversion Patterns Applied

| SQL Server | PostgreSQL |
|-----------|-----------|
| `SCOPE_IDENTITY()` | `INSERT ... RETURNING productid` (writable CTE) |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | Writable CTE / function variables |
| `BEGIN TRANSACTION / COMMIT` | Writable CTE (transactions managed by app code via `BeginTransactionAsync()`) |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `IDENTITY(1,1)` | `serial` |
| `[datetime]` | `timestamp` |
| `[nvarchar](N)` | `varchar(N)` |
| `[bit]` | `boolean` |
| `SYSTEM_USER` | `current_user` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| SQL Server triggers | PostgreSQL trigger function + trigger |
| `Server=` | `Host=` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |

---

## Notes and Recommendations

1. **DMS Tool**: All DMS conversions failed with metadata model creation error. Manual conversions were applied using lowercase schema conventions.
2. **SQL Equivalency**: All equivalency checks returned ERROR. Manual review of conversions is recommended.
3. **Npgsql Version**: Used 8.0.6 (patched security vulnerability GHSA-x9vc-6hfv-hg8c present in 8.0.0).
4. **Connection Strings**: Updated to PostgreSQL format with placeholder credentials. Production credentials should be configured via environment variables or secure configuration.
5. **Window Functions**: PostgreSQL natively supports all window functions used (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN/MAX OVER).
6. **Writable CTEs**: Used PostgreSQL writable CTEs to replace SQL Server's DECLARE/SCOPE_IDENTITY patterns in transactional operations.
