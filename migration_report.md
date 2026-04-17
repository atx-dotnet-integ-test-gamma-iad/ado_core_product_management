# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed (code) | 7 |
| Total SQL statements processed (scripts) | 6 |
| **Total SQL statements processed** | **13** |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 13 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 13 |

## DMS MCP Tool Results
All 13 SQL statements were passed through the DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`). All attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was successfully used to retrieve target schema mappings, which guided the manual conversions:
- `Products` → `products` (schema: `productmanagement_dbo`)
- `ProductHistory` → `producthistory` (schema: `productmanagement_dbo`)
- `ProductStats` → `productstats` (schema: `productmanagement_dbo`)
- `Categories` → `categories` (schema: `productmanagement_dbo`)
- `Suppliers` → `suppliers` (schema: `productmanagement_dbo`)

## SQL Equivalency Tool Results
All 13 statement pairs were validated through the SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`). All returned `ERROR` with the following response:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a persistent service-side issue, not related to the SQL statement quality.

## Manual Conversion Rules Applied
Since DMS statement conversion consistently failed, all conversions were performed manually with the following rules (documented as `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`):

### Schema Object Names
- All table names lowercased: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
- All column names lowercased: `ProductId` → `productid`, `StockQuantity` → `stockquantity`, etc.
- CTE aliases lowercased and suffixed where conflicting with table names

### SQL Server to PostgreSQL Syntax Conversions
| SQL Server | PostgreSQL | Notes |
|-----------|-----------|-------|
| `GETDATE()` | `clock_timestamp()` | Per DMS schema mapping |
| `SCOPE_IDENTITY()` | `RETURNING` clause | Using writable CTEs |
| `DECLARE @var` | CTEs/subqueries | PostgreSQL inline SQL doesn't support DECLARE |
| `BEGIN TRANSACTION...COMMIT` | Writable CTEs | Single-statement approach for ADO.NET |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | Per DMS schema mapping |
| `NVARCHAR(n)` | `VARCHAR(n)` | PostgreSQL uses UTF-8 by default |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` | Per DMS schema mapping |
| `BIT` | `BOOLEAN` | Native PostgreSQL type |
| `SYSTEM_USER` | `CURRENT_USER` | PostgreSQL equivalent |
| `SET NOCOUNT ON` | Removed | Not applicable in PostgreSQL |
| `GO` batch separators | Removed | Not applicable in PostgreSQL |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | PostgreSQL uses functions |
| SQL Server triggers (inserted/deleted tables) | `TG_OP`, `NEW`, `OLD` | PostgreSQL trigger function pattern |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `IF NOT EXISTS` / `DROP IF EXISTS` | PostgreSQL DDL patterns |

## File Changes Summary

### Modified Files
1. **DataAccess/ProductRepository.cs** - All 7 SQL statements converted to PostgreSQL syntax; ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); Using directive updated (Microsoft.Data.SqlClient→Npgsql); Column name references lowercased in MapProductFromReader
2. **AdoCore.csproj** - Package reference updated (Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6)
3. **appsettings.json** - Connection strings updated from SQL Server format to PostgreSQL format (Server→Host, added Username/Password, removed MultipleActiveResultSets and TrustServerCertificate)
4. **Scripts/01_InitialSetup.sql** - Converted from SQL Server DDL/DML to PostgreSQL syntax
5. **Database/Scripts/01_InitialSetup.sql** - Converted from SQL Server DDL/DML/Triggers/Stored Procedures to PostgreSQL syntax

### New Files
1. **extracted_statements.sql** - Catalog of all 7 original MS SQL statements from ProductRepository.cs
2. **converted_statements.sql** - Catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive validation report with all 13 statement pairs
4. **migration_report.md** - This file

## Statements Requiring Manual Review

All 13 statements require manual review due to:
1. DMS MCP tool conversion failures (all 13 statements)
2. SQL Equivalency tool validation errors (all 13 statements)

### Code Statements (ProductRepository.cs)
| # | Method | Complexity | Key Changes |
|---|--------|-----------|-------------|
| 1 | GetAllProductsAsync | High | CTE with window functions, lowercased identifiers |
| 2 | GetProductByIdAsync | High | CTE with LAG window functions, lowercased identifiers |
| 3 | InsertProductAsync | High | SCOPE_IDENTITY→RETURNING, GETDATE→clock_timestamp, writable CTEs |
| 4 | UpdateProductAsync | High | DECLARE eliminated with CTEs, GETDATE→clock_timestamp |
| 5 | DeleteProductAsync | High | DECLARE eliminated with CTEs, GETDATE→clock_timestamp |
| 6 | GetProductsByPriceRangeAsync | Medium | CTE with RANK/PERCENT_RANK, lowercased identifiers |
| 7 | GetLowStockProductsAsync | Medium | CTE with AVG/MIN/MAX, added CAST for integer division |

### Script Statements
| # | Source | Type | Key Changes |
|---|--------|------|-------------|
| 8 | Scripts/01_InitialSetup.sql | DDL | IDENTITY→GENERATED ALWAYS AS IDENTITY, NVARCHAR→VARCHAR |
| 9 | Scripts/01_InitialSetup.sql | SP | CREATE OR ALTER PROCEDURE→CREATE OR REPLACE FUNCTION |
| 10 | Scripts/01_InitialSetup.sql | SP | SCOPE_IDENTITY→RETURNING clause |
| 11 | Database/Scripts/01_InitialSetup.sql | DML | Lowercased identifiers in INSERT |
| 12 | Database/Scripts/01_InitialSetup.sql | DML | GETDATE→clock_timestamp, IsDiscontinued=1→TRUE |
| 13 | Database/Scripts/01_InitialSetup.sql | Trigger | Full trigger rewrite to PostgreSQL trigger function pattern |

## Build Status
**Build: SUCCESS** - The application compiles successfully after all migration changes.
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings, not related to migration)

## Recommendations
1. Run comprehensive integration tests against a PostgreSQL database
2. Verify the writable CTE pattern works correctly with Npgsql for transactional operations
3. Test the trigger function in the PostgreSQL database
4. Consider using environment variables for connection string credentials instead of hardcoded values
5. Retry DMS MCP tool conversion when the service is available for validation
