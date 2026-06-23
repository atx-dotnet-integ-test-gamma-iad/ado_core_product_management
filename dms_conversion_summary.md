# SQL Server to PostgreSQL Migration - DMS Conversion Summary

## Overview
- **Total SQL Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7
- **Conversion Method for all**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## DMS Failure Details
All 7 statements failed DMS conversion due to the same root cause:
- **Error Type**: Metadata model creation failure
- **Root Cause**: Could not connect to source database at '172.31.83.165:1433'
- **Details**: Network connectivity issue preventing DMS from reaching the SQL Server instance

## SQL Equivalency Validation Results
- **Tool Used**: sql-equivalency___validate_sql_equivalence
- **Total Pairs Validated**: 7
- **Equivalent**: 0
- **Not Equivalent**: 0
- **Error**: 7
- **Error Details**: All validations returned ERROR with message "'uniqueID'"

## Manual Conversion Rules Applied
Since DMS failed for all statements, the following rules were applied:
1. All schema object names converted to lowercase (tables, columns, aliases)
2. `GETDATE()` → `NOW()`
3. `SCOPE_IDENTITY()` → `RETURNING` clause with `lastval()`
4. `BEGIN TRANSACTION` / `COMMIT` → `BEGIN` / `COMMIT` for simple cases
5. `DECLARE @var` / `SET @var` → PostgreSQL `DO $$ DECLARE ... BEGIN ... END $$` blocks
6. `SELECT @var = col` → `SELECT col INTO var`
7. Integer division requiring explicit cast: `col::numeric` for ROUND operations
8. `NVARCHAR` → `VARCHAR` (in schema context)
9. `IDENTITY(1,1)` → `SERIAL` (in schema context)
10. `DATETIME` → `TIMESTAMP` (in schema context)

## Statement-by-Statement Log

### Statement 1: GetAllProductsAsync
- **Source**: ProductRepository.cs, GetAllProductsAsync method
- **DMS Output**: Error - Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Applied lowercase schema mapping; SQL syntax already PostgreSQL-compatible (CTEs, window functions)

### Statement 2: GetProductByIdAsync
- **Source**: ProductRepository.cs, GetProductByIdAsync method
- **DMS Output**: Error - Could not connect to source database at '172.31.83.165:1433'
- **Manual Conversion**: Applied lowercase schema mapping; SQL syntax already PostgreSQL-compatible (LAG window function)

### Statement 3: InsertProductAsync
- **Source**: ProductRepository.cs, InsertProductAsync method
- **DMS Output**: Error - Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Replaced SCOPE_IDENTITY() with RETURNING clause, GETDATE() with NOW(), applied lowercase schema, restructured as two separate commands

### Statement 4: UpdateProductAsync
- **Source**: ProductRepository.cs, UpdateProductAsync method
- **DMS Output**: Error - Could not connect to source database at '172.31.83.165:1433'
- **Manual Conversion**: Converted to DO $$ block with PostgreSQL variable declarations, replaced GETDATE() with NOW(), applied lowercase schema

### Statement 5: DeleteProductAsync
- **Source**: ProductRepository.cs, DeleteProductAsync method
- **DMS Output**: Error - Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Converted to DO $$ block with PostgreSQL variable declarations, replaced GETDATE() with NOW(), applied lowercase schema

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: ProductRepository.cs, GetProductsByPriceRangeAsync method
- **DMS Output**: Error - Could not connect to source database at '172.31.83.165:1433'
- **Manual Conversion**: Applied lowercase schema mapping; SQL syntax already PostgreSQL-compatible (RANK, PERCENT_RANK)

### Statement 7: GetLowStockProductsAsync
- **Source**: ProductRepository.cs, GetLowStockProductsAsync method
- **DMS Output**: Error - Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Applied lowercase schema mapping, added ::numeric cast for integer division in ROUND

## Static Code Changes
- **Package**: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.0
- **Classes Replaced**:
  - SqlConnection → NpgsqlConnection
  - SqlCommand → NpgsqlCommand
  - SqlDataReader → NpgsqlDataReader
- **Connection Strings**: Updated from SQL Server format to PostgreSQL format
  - Server= → Host=
  - Trusted_Connection/MultipleActiveResultSets/TrustServerCertificate removed
  - Added Username= and Password= parameters
  - Database name lowercased to match PostgreSQL conventions
