# Migration Report: MS SQL Server to PostgreSQL
## Application: AdoCore (.NET ADO Application)
## Date: 2026-05-05

---

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

---

## DMS Tool Results

All 7 SQL statements were passed to the DMS MCP tool (dms-mcp___statement_conversion_tool) with:
- migration_project_identifier: NXKVMFZHAZFJFF6HU2YPUQHSI4
- schema_name: dbo

**Result**: All 7 failed with `AccessDeniedException`:
> User is not authorized to perform dms:StartMetadataModelCreation on resource: arn:aws:dms:us-east-1:812756961751:migration-project:* because no identity-based policy allows the dms:StartMetadataModelCreation action

**Fallback Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names converted to lowercase for PostgreSQL compatibility
- SQL Server functions replaced with PostgreSQL equivalents (GETDATE()→NOW(), SCOPE_IDENTITY()→RETURNING)
- Transaction blocks restructured for PostgreSQL/Npgsql compatibility

---

## SQL Equivalency Validation Results

All 7 statement pairs were passed to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).

**Result**: All 7 returned ERROR with: `'uniqueID'`

This appears to be an internal tool error, not related to statement quality. Per transformation rules, these are marked as ERROR in the report.

---

## Statements Requiring Manual Review

All 7 statements were manually converted due to DMS access failure:

1. **GetAllProductsAsync** - CTE with window functions (AVG OVER, COUNT OVER, CASE, ROUND)
2. **GetProductByIdAsync** - CTE with LAG window function
3. **InsertProductAsync** - Transaction with SCOPE_IDENTITY() → INSERT...RETURNING
4. **UpdateProductAsync** - Transaction with DECLARE/SELECT INTO variables
5. **DeleteProductAsync** - Transaction with conditional CASE in UPDATE
6. **GetProductsByPriceRangeAsync** - CTE with RANK()/PERCENT_RANK()
7. **GetLowStockProductsAsync** - CTE with AVG/MIN/MAX window functions

---

## Files Modified

### Source Code
- `DataAccess/ProductRepository.cs` - All SQL statements replaced, ADO.NET classes replaced
- `AdoCore.csproj` - Package reference updated (Microsoft.Data.SqlClient → Npgsql)
- `appsettings.json` - Connection strings converted to PostgreSQL format

### Database Scripts
- `Database/Scripts/01_InitialSetup.sql` - Full PostgreSQL conversion
- `Scripts/01_InitialSetup.sql` - Full PostgreSQL conversion

### Transformation Artifacts
- `extracted_statements.sql` - All 7 original MS SQL statements
- `converted_statements.sql` - All 7 converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Complete equivalency validation report

---

## Key Conversions Applied

### Package Dependencies
| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.0 |

### ADO.NET Classes
| Original | Replacement |
|----------|-------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlTransaction | NpgsqlTransaction |

### Connection String
| Parameter | Original | Converted |
|-----------|----------|-----------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=postgres |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed) |
| TrustServerCertificate | True | (removed) |

### SQL Syntax Conversions
| MS SQL | PostgreSQL |
|--------|-----------|
| GETDATE() | NOW() |
| SCOPE_IDENTITY() | INSERT...RETURNING |
| IDENTITY(1,1) | SERIAL |
| nvarchar | VARCHAR |
| datetime | TIMESTAMP |
| bit | BOOLEAN |
| SYSTEM_USER | current_user |
| GO | (removed) |
| IF NOT EXISTS (SELECT..sys..) | CREATE TABLE IF NOT EXISTS / DO $$ block |
| CREATE OR ALTER PROCEDURE | CREATE OR REPLACE FUNCTION |
| CREATE TRIGGER...AS BEGIN...END | CREATE FUNCTION + CREATE TRIGGER |

---

## Build Status

**Final Build: SUCCESS**

The application compiles without errors after all migrations are applied.
