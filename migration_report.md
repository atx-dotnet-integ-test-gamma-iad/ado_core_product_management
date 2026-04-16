# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Project**: AdoCore - Product Management Application
- **Migration Date**: 2026-04-16
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Framework**: .NET 9.0, ADO.NET

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Conversion Successes | 0 |
| DMS Conversion Failures | 7 |
| Manual Conversions (DMS Failure) | 7 |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validation ERRORS | 7 |
| Total Files Modified | 5 |

## DMS Tool Results

The DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) failed for all 7 statements with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was successfully used to obtain schema mappings for all referenced tables:

| Source Table | Target Table | Target Schema |
|-------------|-------------|---------------|
| Products | products | productmanagement_dbo |
| ProductHistory | producthistory | productmanagement_dbo |
| ProductStats | productstats | productmanagement_dbo |

All column names were mapped to lowercase by DMS schema mapping.

## SQL Equivalency Validation Results

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR for all 7 statement pairs with the error: `'uniqueID'`.

Per the transformation rules, all statements are marked with `equivalency_status: "ERROR"` as reported by the tool. Agent judgment was NOT used to determine equivalency.

## Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE alias renamed to `productstats_cte` (avoid conflict with table name), all identifiers lowercased
- **Equivalency**: ERROR (tool error)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function, parameterized (@ProductId)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE alias renamed to `producthistory_cte`, all identifiers lowercased
- **Equivalency**: ERROR (tool error)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: 
  - Single SQL block → 3 separate commands in C# transaction
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId` → C# variable assignment from `ExecuteScalarAsync()`
- **Equivalency**: ERROR (tool error)

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - Single SQL block → 4 separate commands in C# transaction
  - `DECLARE @OldPrice` / `@OldStock` → C# variables populated via `ExecuteReaderAsync()`
  - `GETDATE()` → `NOW()`
- **Equivalency**: ERROR (tool error)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - Single SQL block → 4 separate commands in C# transaction
  - `DECLARE @OldPrice` / `@OldStock` → C# variables populated via `ExecuteReaderAsync()`
  - `GETDATE()` → `NOW()`
  - CASE expression in UPDATE preserved (PostgreSQL compatible)
- **Equivalency**: ERROR (tool error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All identifiers lowercased, window functions preserved (PostgreSQL compatible)
- **Equivalency**: ERROR (tool error)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER window functions, CASE, ROUND, parameterized
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All identifiers lowercased, added `::NUMERIC` cast for integer division in ROUND
- **Equivalency**: ERROR (tool error)

## Modified Files

### 1. DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 replaced with PostgreSQL equivalents
- **ADO.NET Classes**:
  - `using Microsoft.Data.SqlClient` → `using Npgsql`
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
- **Transaction Handling**: InsertProductAsync, UpdateProductAsync, DeleteProductAsync restructured to use C# `BeginTransactionAsync/CommitAsync/RollbackAsync` with separate `NpgsqlCommand` instances
- **Column References**: Updated to lowercase in `MapProductFromReader`

### 2. AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`
  - Note: Version 8.0.6 used instead of 8.0.1 to address security vulnerability GHSA-x9vc-6hfv-hg8c

### 3. appsettings.json
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;...` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same conversion applied

### 4. Scripts/01_InitialSetup.sql
- Complete PostgreSQL rewrite with:
  - `CREATE TABLE IF NOT EXISTS` patterns
  - `GENERATED ALWAYS AS IDENTITY` for auto-increment
  - `VARCHAR` instead of `NVARCHAR`
  - `NOW()` instead of `GETDATE()`
  - `CREATE OR REPLACE FUNCTION` instead of `CREATE OR ALTER PROCEDURE`
  - PL/pgSQL function syntax

### 5. Database/Scripts/01_InitialSetup.sql
- Complete PostgreSQL rewrite with:
  - `DROP TABLE IF EXISTS` / `DROP TRIGGER IF EXISTS` patterns
  - `BOOLEAN` instead of `BIT`
  - PostgreSQL trigger function with `TG_OP` instead of `inserted`/`deleted` pseudo-tables
  - `current_user` instead of `SYSTEM_USER`
  - All table/column names lowercase per DMS schema mapping
  - Foreign key constraints preserved
  - Indexes preserved with lowercase names

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Complete equivalency validation report for all 7 pairs |
| migration_report.md | sourceCode/ | This report |

## Build Status
- **Final Build**: ✅ Succeeded (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **No Vulnerability Warnings**: ✅ (Npgsql 8.0.6 has no known vulnerabilities)

## Statements Requiring Manual Review
All 7 statements require manual review because:
1. DMS statement conversion tool failed for all statements
2. SQL Equivalency tool returned ERROR for all statement pairs
3. Manual conversions were applied using DMS schema mapping (lowercase schema objects) but could not be machine-validated

## Recommendations
1. Validate all SQL statements against a running PostgreSQL database
2. Test transaction integrity for InsertProductAsync, UpdateProductAsync, and DeleteProductAsync
3. Verify the `::NUMERIC` cast in GetLowStockProductsAsync produces correct results
4. Test connection string authentication against actual PostgreSQL instance
5. Run integration tests with PostgreSQL database to verify end-to-end functionality
