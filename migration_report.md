# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the ADO.NET Core application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET data access classes, modifying connection strings, and updating database scripts and documentation.

## Migration Overview

| Metric | Value |
|--------|-------|
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Total SQL Statements** | 7 |
| **Files Modified** | 6 |
| **Build Status** | ✅ Succeeded (0 errors) |

## SQL Statement Conversion

### DMS Tool Conversion Results

All 7 SQL statements were submitted to the AWS DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`). All attempts failed with the same error:

> **Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) was successfully used to obtain target schema mappings for:
- `Products` → `products` (schema: `productmanagement_dbo`)
- `ProductHistory` → `producthistory` (schema: `productmanagement_dbo`)
- `ProductStats` → `productstats` (schema: `productmanagement_dbo`)

### Manual Conversion Results

All 7 statements were manually converted using DMS schema mappings with lowercase schema object names.

| # | Method | Conversion Method | Key Changes |
|---|--------|-------------------|-------------|
| 1 | GetAllProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Table/column names lowercased, CTE renamed to avoid conflict |
| 2 | GetProductByIdAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Table/column names lowercased, CTE renamed |
| 3 | InsertProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | SCOPE_IDENTITY() → RETURNING clause, GETDATE() → clock_timestamp(), DECLARE/transaction → writable CTE |
| 4 | UpdateProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | DECLARE @var → CTE subquery, GETDATE() → clock_timestamp(), writable CTE pattern |
| 5 | DeleteProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | DECLARE @var → CTE subquery, GETDATE() → clock_timestamp(), writable CTE pattern |
| 6 | GetProductsByPriceRangeAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Table/column names lowercased |
| 7 | GetLowStockProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Table/column names lowercased, integer division cast to NUMERIC |

### SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR due to a systemic tool issue:

> **Error:** 'uniqueID'

| Metric | Count |
|--------|-------|
| Statements Processed | 7 |
| EQUIVALENT | 0 |
| NOT_EQUIVALENT | 0 |
| ERROR | 7 |

**Note:** The ERROR status is due to a systemic issue with the equivalency tool (consistent `'uniqueID'` error on all queries including trivial ones), not due to issues with the converted SQL statements.

## Files Modified

### 1. `DataAccess/ProductRepository.cs`
- **Imports:** `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Connection:** `SqlConnection` → `NpgsqlConnection`
- **Commands:** `SqlCommand` → `NpgsqlCommand` (7 instances)
- **Reader:** `SqlDataReader` → `NpgsqlDataReader`
- **SQL Statements:** All 7 replaced with PostgreSQL equivalents
- **Column References:** Updated to lowercase in `MapProductFromReader`

### 2. `AdoCore.csproj`
- **Removed:** `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added:** `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 3. `appsettings.json`
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection:** Same pattern applied

### 4. `Scripts/01_InitialSetup.sql`
- Converted to PostgreSQL syntax (GENERATED ALWAYS AS IDENTITY, VARCHAR, plpgsql functions)

### 5. `Database/Scripts/01_InitialSetup.sql`
- Full conversion including tables, indexes, triggers, stored procedures, and sample data

### 6. `README.md`
- Updated all references from SQL Server to PostgreSQL

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Original 7 MS SQL statements with metadata |
| converted_statements.sql | sourceCode/ | Converted 7 PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Complete equivalency report for all 7 pairs |
| migration_report.md | sourceCode/ | This report |

## Key Conversion Patterns Applied

| SQL Server | PostgreSQL | Applied In |
|-----------|-----------|-----------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (writable CTE) | InsertProductAsync |
| `GETDATE()` | `clock_timestamp()` | Insert, Update, Delete |
| `DECLARE @var TYPE` | CTE-based subqueries | Update, Delete |
| `BEGIN TRANSACTION / COMMIT` | Removed (managed by ADO.NET) | Insert, Update, Delete |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | Schema scripts |
| `NVARCHAR(n)` | `VARCHAR(n)` | Schema scripts |
| `BIT` | `BOOLEAN` | Schema scripts |
| `SqlConnection` | `NpgsqlConnection` | ProductRepository.cs |
| `SqlCommand` | `NpgsqlCommand` | ProductRepository.cs |
| `SqlDataReader` | `NpgsqlDataReader` | ProductRepository.cs |

## Statements Requiring Post-Migration Review

All 7 statements should be functionally tested against a live PostgreSQL database, especially:

1. **InsertProductAsync** - Uses writable CTE with RETURNING clause, which is a PostgreSQL-specific pattern
2. **UpdateProductAsync** - Uses writable CTE for multi-table operations in a single statement
3. **DeleteProductAsync** - Uses writable CTE for multi-table operations with CASE expression

## Build Verification

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All warnings are pre-existing nullable reference warnings, not related to the migration.
