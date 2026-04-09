# Migration Report: MS SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Scope

### SQL Statements Processed
- **Total inline SQL statements**: 7 (from DataAccess/ProductRepository.cs)
- **SQL script files converted**: 2 (Scripts/01_InitialSetup.sql, Database/Scripts/01_InitialSetup.sql)

### DMS Conversion Results
- **Statements attempted via DMS MCP tool**: 7/7
- **Statements successfully converted by DMS**: 0/7
- **Statements requiring manual intervention**: 7/7
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Schema Mapping**: Successfully retrieved for all tables (Products, ProductHistory, ProductStats, Categories, Suppliers)
- **Conversion method applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (used DMS schema mappings for name resolution)

### SQL Equivalency Validation Results
- **Statements validated**: 7/7
- **Equivalent**: 0
- **Non-equivalent**: 0
- **Errors**: 7 (all returned ERROR with `'uniqueID'` - service-level issue)
- **Tool used**: sql-equivalency___validate_sql_equivalence
- **Note**: The SQL Equivalency tool consistently returned ERROR for all pairs due to a service-level `'uniqueID'` error, not related to the quality of the conversions.

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG, COUNT), INNER JOIN, CASE, ROUND
- **Key Changes**: Lowercase table/column names
- **Equivalency**: ERROR (tool service issue)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Functions, LEFT JOIN, CASE
- **Key Changes**: Lowercase table/column names
- **Equivalency**: ERROR (tool service issue)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**: SCOPE_IDENTITY() → RETURNING clause, GETDATE() → clock_timestamp(), DECLARE/SET → C# variables, monolithic T-SQL transaction → individual SQL commands with C# BeginTransaction/Commit
- **Equivalency**: ERROR (tool service issue)

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT
- **Key Changes**: DECLARE @var → C# variable via SELECT, GETDATE() → clock_timestamp(), monolithic T-SQL transaction → individual SQL commands with C# BeginTransaction/Commit
- **Equivalency**: ERROR (tool service issue)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE
- **Key Changes**: Same restructuring as Statement 4
- **Equivalency**: ERROR (tool service issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Key Changes**: Lowercase table/column names
- **Equivalency**: ERROR (tool service issue)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Key Changes**: Lowercase table/column names, added ::NUMERIC cast for integer division
- **Equivalency**: ERROR (tool service issue)

## Files Modified

| File | Changes |
|------|---------|
| AdoCore.csproj | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| DataAccess/ProductRepository.cs | Replaced all SQL statements with PostgreSQL equivalents; replaced SqlConnection/SqlCommand/SqlDataReader with Npgsql equivalents; restructured transaction blocks |
| appsettings.json | Converted connection strings from SQL Server to PostgreSQL format |
| Scripts/01_InitialSetup.sql | Converted DDL, stored procedures to PostgreSQL functions |
| Database/Scripts/01_InitialSetup.sql | Full conversion of DDL, indexes, triggers, stored functions, sample data |

## Static Code Changes

### Package References
- **Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Added**: `Npgsql` Version 8.0.6

### ADO.NET Class Replacements
| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|----------------------|------------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Removed | `MultipleActiveResultSets=true` | N/A |
| Removed | `TrustServerCertificate=True` | N/A |

### SQL Syntax Changes
| SQL Server | PostgreSQL |
|-----------|------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `GETDATE()` | `clock_timestamp()` |
| `DECLARE @var` | C# variables via separate SELECT |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `nvarchar(n)` | `VARCHAR(n)` |
| `[dbo].[TableName]` | `tablename` (lowercase) |
| `CREATE PROCEDURE` | `CREATE FUNCTION ... LANGUAGE plpgsql` |
| `CREATE TRIGGER ON table AFTER` | `CREATE TRIGGER ... FOR EACH ROW EXECUTE FUNCTION` |
| `GO` | `;` (semicolons) |

## Migration Artifacts
1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency report with all 7 pairs
4. **migration_report.md** - This file

## Build Verification
- **Final build status**: ✅ Build succeeded
- **Errors**: 0
- **Vulnerability warnings**: 0 (resolved by upgrading Npgsql from 8.0.0 to 8.0.6)

## Issues and Resolutions

### DMS Tool Failure
- **Issue**: DMS MCP statement_conversion_tool failed for all 7 statements with "Metadata model creation failed: RECEIVED"
- **Resolution**: Used manual conversion with lowercase schema mapping (per DMS schema_mapping_tool output)
- **Schema mappings applied**: Products→products, ProductHistory→producthistory, ProductStats→productstats, all columns lowercase

### SQL Equivalency Tool Error
- **Issue**: SQL equivalency tool returned ERROR ('uniqueID') for all 7 statement pairs
- **Resolution**: Documented as ERROR per protocol; appears to be a service-level issue, not statement-specific

### Transaction Block Restructuring
- **Issue**: PostgreSQL doesn't support T-SQL's DECLARE/SET/BEGIN TRANSACTION inline pattern
- **Resolution**: Restructured transaction blocks to use individual SQL commands with C# ADO.NET transaction handling (BeginTransaction/Commit/Rollback)

### Npgsql Vulnerability
- **Issue**: Npgsql 8.0.0 has known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)
- **Resolution**: Upgraded to Npgsql 8.0.6 which resolves the vulnerability
