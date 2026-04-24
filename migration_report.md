# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

This report documents the complete migration of the AdoCore .NET application from
Microsoft SQL Server to PostgreSQL, including all SQL statement conversions,
ADO.NET class replacements, dependency changes, and configuration updates.

## Migration Date
2026-04-24

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | SQL statements converted, ADO.NET classes replaced |
| `AdoCore.csproj` | Modified | Package reference changed from Microsoft.Data.SqlClient to Npgsql |
| `appsettings.json` | Modified | Connection strings converted from SQL Server to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted from SQL Server to PostgreSQL DDL/DML syntax |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted from SQL Server to PostgreSQL DDL/DML syntax |
| `extracted_statements.sql` | Created | Catalog of all original SQL statements |
| `converted_statements.sql` | Created | Catalog of all converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Created | Comprehensive equivalency validation report |

## SQL Statement Conversion Summary

### Inline SQL Statements (ProductRepository.cs)

| # | Method | Conversion Method | Key Changes |
|---|--------|-------------------|-------------|
| 1 | GetAllProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Lowercase schema objects |
| 2 | GetProductByIdAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Lowercase schema objects |
| 3 | InsertProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | SCOPE_IDENTITY() -> lastval(), GETDATE() -> NOW(), DECLARE/SET removed |
| 4 | UpdateProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | GETDATE() -> NOW(), DECLARE/SET -> separate SELECT query |
| 5 | DeleteProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | GETDATE() -> NOW(), DECLARE/SET -> separate SELECT query |
| 6 | GetProductsByPriceRangeAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | Lowercase, added ::numeric cast |

### Script SQL Statements

| Script | Key Conversions |
|--------|-----------------|
| Scripts/01_InitialSetup.sql | IDENTITY -> GENERATED ALWAYS AS IDENTITY, nvarchar -> varchar, GETDATE() -> NOW(), CREATE OR ALTER PROCEDURE -> CREATE OR REPLACE FUNCTION, IF NOT EXISTS pattern -> PostgreSQL DO block, GO removed |
| Database/Scripts/01_InitialSetup.sql | All above plus: bit -> boolean, SQL Server trigger -> PostgreSQL trigger function + trigger, SYSTEM_USER -> current_user, complex DROP IF EXISTS patterns simplified |

## DMS Tool Results

- **Total DMS calls made**: 9 (7 inline + 2 script statements)
- **Successfully converted by DMS**: 0
- **Failed DMS conversions**: 9
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **All failures required manual conversion** with lowercase schema mapping (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

## SQL Equivalency Validation Results

- **Total statement pairs validated**: 7 (inline statements)
- **Equivalent**: 0
- **Not Equivalent**: 0
- **Errors**: 7
- **Equivalency Tool Error**: `'uniqueID'`
- **Note**: The SQL Equivalency tool consistently returned ERROR for all statement pairs. All equivalency statuses are as reported by the tool, not by agent judgment.

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) | Count |
|-----------------------|--------------------------|-------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 9 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Package Dependency Changes

| Original | New |
|----------|-----|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |

**Note**: Npgsql 8.0.6 was used instead of 8.0.1 to avoid a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | (removed - not supported) |
| TrustServerCertificate | `TrustServerCertificate=True` | (removed - not applicable) |

## SQL Syntax Conversion Details

### Key Conversions Applied

1. **Schema Object Names**: All converted to lowercase for PostgreSQL compatibility
   - `Products` -> `products`
   - `ProductHistory` -> `producthistory`
   - `ProductStats` -> `productstats`
   - All column names lowercased

2. **Functions**:
   - `SCOPE_IDENTITY()` -> `lastval()`
   - `GETDATE()` -> `NOW()`
   - `SYSTEM_USER` -> `current_user`

3. **Data Types**:
   - `NVARCHAR(n)` -> `VARCHAR(n)`
   - `DATETIME` -> `TIMESTAMP`
   - `BIT` -> `BOOLEAN`
   - `INT IDENTITY(1,1)` -> `INT GENERATED ALWAYS AS IDENTITY`

4. **Transaction Handling**:
   - SQL Server inline DECLARE/SET pattern -> C# separate SELECT + multi-statement SQL
   - `BEGIN TRANSACTION`/`COMMIT` -> Handled via Npgsql ADO.NET BeginTransactionAsync

5. **Stored Procedures**:
   - `CREATE OR ALTER PROCEDURE` -> `CREATE OR REPLACE FUNCTION ... RETURNS ... LANGUAGE plpgsql`

6. **Triggers**:
   - SQL Server trigger with `inserted`/`deleted` tables -> PostgreSQL trigger function with `NEW`/`OLD` records and `TG_OP`

7. **SQL Server Specific**:
   - `GO` statement separator -> Removed
   - `[dbo].[table]` bracket notation -> Plain table names
   - `SET NOCOUNT ON` -> Removed (not needed in PostgreSQL)
   - `IF NOT EXISTS (SELECT * FROM sys.objects ...)` -> `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS`

## Build Status

- **Final Build**: ✅ SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference type warnings, not related to migration)

## Items Requiring Manual Review

1. **DMS Tool Availability**: All 9 DMS conversion attempts failed. If DMS becomes available, it is recommended to re-run conversions to verify manual conversions.

2. **SQL Equivalency Validation**: All 7 equivalency validation attempts returned ERROR. Manual review of converted SQL statements is recommended.

3. **Transaction Atomicity**: The UpdateProductAsync and DeleteProductAsync methods now use a separate SELECT query to read old values before the main transaction. Ensure the application's connection pooling and isolation level maintain consistency.

4. **Integer Division**: The `GetLowStockProductsAsync` method uses `::numeric` cast for the division `(stockquantity::numeric / avgstock)` to avoid PostgreSQL integer division truncation.

5. **Connection String Credentials**: The placeholder credentials (`Username=postgres;Password=postgres`) in appsettings.json should be replaced with actual PostgreSQL credentials for the target environment.

## Artifacts Generated

1. `extracted_statements.sql` - Complete catalog of all 7 original MS SQL statements
2. `converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report with all 7 statement pairs
4. `migration_report.md` - This report
