# Migration Report: MS SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|---|---|
| **Migration Date** | 2026-04-27 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 ADO.NET |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Build Status** | SUCCESS (0 errors) |

## SQL Statement Processing Summary

| Category | Count |
|---|---|
| **Total SQL statements processed** | 17 |
| **Code-level SQL statements (ProductRepository.cs)** | 7 |
| **Script-level SQL statements (Setup scripts)** | 10 |
| **Statements successfully converted by DMS** | 0 |
| **Statements requiring manual intervention** | 17 |
| **Statements validated as equivalent** | 0 |
| **Statements validated as non-equivalent** | 0 |
| **Statements with equivalency validation errors** | 17 |

## DMS Tool Status

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for **every** SQL statement. All attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Migration Project**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`

**DMS Schema Mapping Tool**: Successfully retrieved schema mappings for all 3 tables (Products, ProductHistory, ProductStats), which were used to guide manual conversions.

## SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was attempted for **every** statement pair. All attempts returned ERROR:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation definition, all statements are marked as ERROR (agent judgment was NOT used to determine equivalency).

## Manual Conversion Approach

Since DMS statement conversion failed, all conversions were performed manually using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach, guided by:

1. **DMS Schema Mapping Tool output** (successfully retrieved):
   - `dbo.Products` → `productmanagement_dbo.products` (all columns lowercase)
   - `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
   - `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)

2. **Key SQL Syntax Conversions**:
   | MS SQL Server | PostgreSQL | Notes |
   |---|---|---|
   | `GETDATE()` | `clock_timestamp()` | Per DMS target DDL |
   | `SCOPE_IDENTITY()` | `RETURNING productid` | Pattern change |
   | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | Per DMS target DDL |
   | `NVARCHAR(n)` | `VARCHAR(n)` | Per DMS target DDL |
   | `DECIMAL(p,s)` | `NUMERIC(p,s)` | Per DMS target DDL |
   | `DATETIME` | `TIMESTAMP WITHOUT TIME ZONE` | Per DMS target DDL |
   | `BIT` | `NUMERIC(1,0)` | Per DMS target DDL |
   | `[dbo].[TableName]` | `tablename` (lowercase) | Per DMS schema mapping |
   | `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | PostgreSQL function syntax |
   | `SYSTEM_USER` | `CURRENT_USER` | PostgreSQL equivalent |
   | `GO` separators | Removed | Not needed in PostgreSQL |
   | SQL Server triggers | PostgreSQL trigger functions | Different syntax model |

## Files Modified

| File | Changes |
|---|---|
| `sourceCode/DataAccess/ProductRepository.cs` | Replaced 7 SQL statements, updated all ADO.NET types (SqlConnection→NpgsqlConnection, etc.), restructured transaction blocks |
| `sourceCode/AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| `sourceCode/appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |
| `sourceCode/Scripts/01_InitialSetup.sql` | Converted entire script to PostgreSQL syntax |
| `sourceCode/Database/Scripts/01_InitialSetup.sql` | Converted entire script to PostgreSQL syntax (tables, triggers, stored procedures, indexes, data) |

## Artifacts Created

| File | Description |
|---|---|
| `sourceCode/extracted_statements.sql` | Catalog of all 7 original MS SQL statements from code |
| `sourceCode/converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements for code |
| `sourceCode/sql_equivalency_validation_report.json` | Comprehensive JSON report with all 17 statement pairs |
| `sourceCode/dms_conversion_log.md` | Detailed log of all DMS tool attempts and manual conversions |
| `sourceCode/migration_report.md` | This report |

## Code Changes Detail

### ADO.NET Type Replacements
- `SqlConnection` → `NpgsqlConnection` (field, constructor, method return types)
- `SqlCommand` → `NpgsqlCommand` (15 usages)
- `SqlDataReader` → `NpgsqlDataReader` (MapProductFromReader parameter)
- `Microsoft.Data.SqlClient` → `Npgsql` (using directive)
- Transaction handling: SQL Server inline transactions → Npgsql application-level transactions

### Connection String Changes
- `Server=localhost` → `Host=localhost`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- `MultipleActiveResultSets=true` → Removed (not applicable)
- `TrustServerCertificate=True` → Removed (not applicable)
- Added `Port=5432`

### SQL Statement Restructuring
- **Insert operation**: Single inline transaction block → 3 separate SQL commands with `RETURNING` clause, managed by `BeginTransactionAsync()`
- **Update operation**: Single inline transaction block → 4 separate SQL commands, variables captured via `ExecuteReaderAsync()`, managed by `BeginTransactionAsync()`
- **Delete operation**: Single inline transaction block → 4 separate SQL commands, managed by `BeginTransactionAsync()`

## Known Issues and Warnings

1. **DMS Tool Unavailability**: The DMS statement conversion tool consistently failed with metadata model creation errors. All conversions were performed manually using schema mapping information from the DMS schema_mapping_tool.

2. **SQL Equivalency Tool Unavailability**: The SQL equivalency validation tool consistently returned ERROR for all statement pairs. Equivalency could not be verified through the tool.

3. **Build Warnings**: 10 nullable reference warnings exist (all pre-existing from original code, not introduced by migration).

4. **Column Name Case Sensitivity**: PostgreSQL column names are now all lowercase. The `MapProductFromReader` method was updated to use lowercase column names (`productid`, `name`, etc.). Applications or queries that reference column names by their original casing may need updates.

5. **Integer Division**: Added explicit `CAST(stockquantity AS NUMERIC)` in GetLowStockProductsAsync to prevent PostgreSQL integer division (which truncates to integer, unlike SQL Server's implicit decimal promotion).

## Validation Checklist

- [x] All SQL Server packages replaced with PostgreSQL equivalents (Npgsql 8.0.6)
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- [x] All 7 code SQL statements processed through DMS tool (all failed, documented)
- [x] All 17 SQL statement pairs validated through SQL Equivalency tool (all returned ERROR, documented)
- [x] Comprehensive equivalency validation report generated (sql_equivalency_validation_report.json)
- [x] Connection strings updated to PostgreSQL format
- [x] Transaction handling updated to use PostgreSQL pattern
- [x] Application compiles without errors (0 errors, 10 pre-existing warnings)
- [x] Database setup scripts converted to PostgreSQL syntax
- [x] All artifacts (catalogs, reports, logs) created and complete
