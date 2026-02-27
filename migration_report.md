# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Date**: 2026-02-27
- **Application**: AdoCore - .NET ADO Product Management Application
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Framework**: .NET 9.0

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (inline) | 7 |
| Total SQL statements processed (script) | 2 |
| **Total SQL statements processed** | **9** |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 9 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 9 |

## DMS Tool Status
All 9 SQL statements were submitted to the DMS MCP tool (dms-mcp____statement_conversion_tool) with:
- Migration Project: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- Database: ProductManagement
- Schema: dbo
- Region: us-east-1

**All attempts failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry configurations were attempted (extended polling, explicit server_name), all with the same result.

## SQL Equivalency Validation Status
All 9 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).

**All validations returned ERROR** with:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a systemic issue with the tool service, not related to the statement content.

## Manual Conversion Approach
Since DMS was unavailable, all conversions were performed manually following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` convention:

### Key Conversion Rules Applied
1. **Schema Objects**: All table names, column names, aliases → lowercase
   - `Products` → `products`, `ProductId` → `productid`, `CreatedDate` → `createddate`
2. **SCOPE_IDENTITY()** → `lastval()` (with `INSERT ... RETURNING` for direct ID capture)
3. **GETDATE()** → `NOW()`
4. **DECLARE @variable / SET @variable** → Restructured as subqueries or PostgreSQL `DO $$` blocks
5. **BEGIN TRANSACTION / COMMIT** → Removed (transaction managed at application level via Npgsql)
6. **SELECT @var = col** → Subquery approach for PostgreSQL compatibility
7. **Window Functions** (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN, MAX) → Compatible, only lowercased
8. **ROUND with integer division** → Added `CAST(... AS NUMERIC)` for proper decimal behavior
9. **Data Types**: `NVARCHAR` → `VARCHAR`, `DATETIME` → `TIMESTAMP`, `DECIMAL` → `NUMERIC`, `INT IDENTITY` → `SERIAL`, `BIT` → `BOOLEAN`
10. **DEFAULT GETDATE()** → `DEFAULT NOW()`
11. **Stored Procedures** → PostgreSQL functions with `RETURNS TABLE` / `RETURNS VOID`
12. **Triggers** → PostgreSQL trigger function + trigger syntax
13. **GO statements** → Removed
14. **SET NOCOUNT ON** → Removed (not applicable)
15. **SYSTEM_USER** → `CURRENT_USER`
16. **IF EXISTS / IF NOT EXISTS (sys.objects)** → `DROP ... IF EXISTS` / `CREATE TABLE IF NOT EXISTS`

## Detailed Statement Conversion Log

### Inline SQL Statements (ProductRepository.cs)

| # | Method | Type | Key Changes |
|---|--------|------|-------------|
| 1 | GetAllProductsAsync | SELECT with CTE | Lowercased schema objects |
| 2 | GetProductByIdAsync | SELECT with CTE + LAG | Lowercased schema objects |
| 3 | InsertProductAsync | Transaction block | SCOPE_IDENTITY→lastval(), GETDATE→NOW(), restructured |
| 4 | UpdateProductAsync | Transaction block | DECLARE→subqueries, GETDATE→NOW(), restructured |
| 5 | DeleteProductAsync | Transaction block | DECLARE→subqueries, GETDATE→NOW(), restructured |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE + RANK | Lowercased schema objects |
| 7 | GetLowStockProductsAsync | SELECT with CTE + AVG/MIN/MAX | Lowercased, added CAST for ROUND |

### Script File Statements

| # | Source | Type | Key Changes |
|---|--------|------|-------------|
| 8 | Database/Scripts/01_InitialSetup.sql | CREATE TABLE DDL | IDENTITY→SERIAL, NVARCHAR→VARCHAR, DATETIME→TIMESTAMP, BIT→BOOLEAN |
| 9 | Database/Scripts/01_InitialSetup.sql | CREATE PROCEDURE | Converted to CREATE OR REPLACE FUNCTION with plpgsql |

## File Changes Summary

### Modified Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements with PostgreSQL equivalents; replaced SqlClient with Npgsql classes |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | SQL Server connection strings → PostgreSQL format |
| `README.md` | Updated for PostgreSQL (prerequisites, setup, configuration) |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (DDL, functions, triggers, data) |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (DDL, functions, data) |

### New Files Created
| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all extracted MS SQL statements |
| `converted_statements.sql` | Catalog of all converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | SQL equivalency validation results |
| `dms_conversion_log.md` | Detailed DMS tool interaction log |
| `migration_report.md` | This comprehensive migration report |

## ADO.NET Class Replacements
| Original (SQL Server) | Replacement (PostgreSQL) |
|-----------------------|-------------------------|
| `Microsoft.Data.SqlClient` (using) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (via AddWithValue) |

## Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| SSL | `TrustServerCertificate=True` | Removed |

## Build Status
- **Final build**: ✅ **SUCCESS** (0 errors, warnings are pre-existing nullable reference warnings)
- **Vulnerable packages**: ✅ None (Npgsql upgraded to 8.0.6 to fix GHSA-x9vc-6hfv-hg8c)

## Statements Requiring Manual Review
All 9 statements require manual review as:
1. DMS tool was unable to convert (systemic failure)
2. SQL Equivalency tool was unable to validate (systemic failure)

**Recommendation**: Run integration tests against a PostgreSQL database to validate all converted statements produce correct results.

## Artifacts
- `extracted_statements.sql` - Complete catalog of original MS SQL statements
- `converted_statements.sql` - Complete catalog of converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report (9 statements)
- `dms_conversion_log.md` - Detailed DMS tool interaction log
- `migration_report.md` - This report
