# Migration Report: SQL Server to PostgreSQL

## Overview
- **Date**: 2026-04-24
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Application Framework**: .NET 9.0 ADO.NET (C#)
- **Migration Tool**: AWS DMS MCP Tool (attempted), Manual Conversion (applied)

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (inline code) | 7 |
| Total SQL statements processed (scripts) | 5 |
| **Total SQL statements processed** | **12** |
| DMS conversion successes | 0 |
| DMS conversion failures | 12 |
| Manual conversions applied | 12 |
| Equivalency validations attempted | 12 |
| Equivalency status: EQUIVALENT | 0 |
| Equivalency status: NOT_EQUIVALENT | 0 |
| Equivalency status: ERROR | 12 |

---

## DMS Tool Status

All 12 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`). All calls failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`  
**Region**: `us-east-1`  
**Schema**: `dbo`

Multiple retry attempts were made with varying configurations (different poll intervals, explicit database_name/server_name parameters). The error persisted across all attempts, indicating an infrastructure-level issue with the DMS metadata model creation service.

---

## SQL Equivalency Validation Status

All 12 SQL statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All calls returned ERROR:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This error is independent from DMS and appears to be a tool infrastructure issue. Per transformation rules, all statements are marked as ERROR (never using agent judgment for equivalency).

Full report: `sql_equivalency_validation_report.json`

---

## Files Modified

### Source Code Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements, replaced ADO.NET classes with Npgsql equivalents |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

### SQL Script Files
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (IDENTITY→GENERATED, GETDATE→NOW, procedures→functions) |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion including tables, indexes, triggers, procedures, and sample data |

### Generated Artifacts
| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements from ProductRepository.cs |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report (12 statement pairs) |
| `migration_report.md` | This report |

---

## Detailed Changes

### A. Package Dependency Changes

| Before | After | Reason |
|--------|-------|--------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` | PostgreSQL driver replacement. Version 8.0.6 chosen over 8.0.0 to avoid known vulnerability GHSA-x9vc-6hfv-hg8c |

Other packages preserved unchanged:
- `Microsoft.Extensions.Configuration 8.0.0`
- `Microsoft.Extensions.Configuration.Json 8.0.0`
- `Microsoft.Extensions.DependencyInjection 8.0.0`

### B. Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (N/A) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (N/A) |

### C. ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|------------------|-------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### D. SQL Statement Conversions (Inline Code)

| # | Method | Key Changes |
|---|--------|-------------|
| 1 | GetAllProductsAsync | Lowercase schema objects, CTE preserved |
| 2 | GetProductByIdAsync | Lowercase schema objects, LAG window function preserved |
| 3 | InsertProductAsync | `SCOPE_IDENTITY()` → `RETURNING`, `GETDATE()` → `NOW()`, restructured as CTE with RETURNING |
| 4 | UpdateProductAsync | `GETDATE()` → `NOW()`, DECLARE/variable pattern → CTE with old_values |
| 5 | DeleteProductAsync | `GETDATE()` → `NOW()`, DECLARE/variable pattern → CTE with old_values |
| 6 | GetProductsByPriceRangeAsync | Lowercase schema objects, RANK/PERCENT_RANK preserved |
| 7 | GetLowStockProductsAsync | Lowercase schema objects, integer division fix (`* 1.0`) |

### E. SQL Script Conversions

| Conversion | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Identity columns | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| Date function | `GETDATE()` | `NOW()` |
| Boolean type | `[bit] NOT NULL DEFAULT 1` | `BOOLEAN NOT NULL DEFAULT TRUE` |
| Schema prefix | `[dbo].[tablename]` | `tablename` (lowercase) |
| Stored procedures | `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| Triggers | T-SQL trigger on `inserted`/`deleted` | PL/pgSQL trigger function with `TG_OP`/`NEW`/`OLD` |
| GO statement | `GO` | Removed |
| IF EXISTS checks | `IF EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS` |
| System user | `SYSTEM_USER` | `current_user` |
| Column brackets | `[ColumnName]` | `columnname` (lowercase, no brackets) |

---

## Manual Interventions Required

All 12 SQL statements required manual conversion due to DMS tool failure. The conversion methodology applied:
- **DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA**: Applied lowercase naming for all schema objects
- Key SQL Server → PostgreSQL syntax transformations applied manually
- All conversions documented with DMS error output

---

## Build Status
- **Final build**: ✅ SUCCESS (0 errors)
- **Pre-existing warnings**: Nullable reference warnings (unchanged from original code)

---

## Statements Requiring Manual Review

All 12 statements should be reviewed manually since:
1. DMS tool was unavailable for automated conversion verification
2. SQL Equivalency tool was unavailable for automated equivalency verification
3. Transaction block conversions (statements 3, 4, 5) use PostgreSQL CTE patterns which differ structurally from the original T-SQL DECLARE/variable approach while maintaining equivalent functionality
