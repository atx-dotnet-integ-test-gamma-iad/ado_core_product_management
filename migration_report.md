# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-05-22

## Statistics
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention (DMS failure)**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Results
All 7 statements were submitted to the DMS MCP tool for conversion. All failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using lowercase schema naming convention (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Results
All 7 statement pairs were submitted to the SQL Equivalency tool. All returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

## Changes Made

### 1. Package References (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Added**: `Npgsql` Version 8.0.1

### 2. Database Access Code (DataAccess/ProductRepository.cs)
- **Replaced**: `using Microsoft.Data.SqlClient` → `using Npgsql`
- **Replaced**: `SqlConnection` → `NpgsqlConnection`
- **Replaced**: `SqlCommand` → `NpgsqlCommand`
- **Replaced**: `SqlDataReader` → `NpgsqlDataReader`
- **Converted**: All 7 SQL statements to PostgreSQL syntax with lowercase schema
- **Restructured**: Transaction blocks (INSERT, UPDATE, DELETE) from T-SQL DECLARE/BEGIN TRANSACTION to C#-managed NpgsqlTransaction with multiple commands
- **Replaced**: `SCOPE_IDENTITY()` → `RETURNING productid`
- **Replaced**: `GETDATE()` → `NOW()`
- **Added**: `CAST(stockquantity AS NUMERIC)` for integer division fix in GetLowStockProducts
- **Updated**: Column reader references to use lowercase names (e.g., `reader["ProductId"]` → `reader["productid"]`)

### 3. Connection Strings (appsettings.json)
- **Replaced**: SQL Server format (`Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`)
- **With**: PostgreSQL format (`Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;`)

## SQL Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, JOIN
- **Changes**: Lowercase schema objects only; SQL syntax is compatible between SQL Server and PostgreSQL

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE, ROUND
- **Changes**: Lowercase schema objects only; SQL syntax is compatible

### Statement 3: InsertProductAsync
- **Type**: Transaction with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Changes**: 
  - Removed DECLARE @NewProductId / SET @NewProductId = SCOPE_IDENTITY()
  - Used INSERT...RETURNING productid instead
  - Split into 3 separate commands managed by C# NpgsqlTransaction
  - Replaced GETDATE() with NOW()
  - Applied lowercase schema

### Statement 4: UpdateProductAsync
- **Type**: Transaction with DECLARE variables, SELECT into variables, UPDATE, INSERT history, UPDATE stats
- **Changes**:
  - Removed DECLARE statements (T-SQL specific)
  - Split into 4 separate commands managed by C# NpgsqlTransaction
  - Old values retrieved via SELECT and stored in C# variables
  - Replaced GETDATE() with NOW()
  - Applied lowercase schema

### Statement 5: DeleteProductAsync
- **Type**: Transaction with DECLARE variables, SELECT, INSERT history, DELETE, UPDATE stats with CASE
- **Changes**:
  - Removed DECLARE statements (T-SQL specific)
  - Split into 4 separate commands managed by C# NpgsqlTransaction
  - Old values retrieved via SELECT and stored in C# variables
  - Replaced GETDATE() with NOW()
  - Applied lowercase schema

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **Changes**: Lowercase schema objects only; SQL syntax is compatible

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER window functions, CASE, ROUND
- **Changes**: 
  - Lowercase schema objects
  - Added CAST(stockquantity AS NUMERIC) to prevent integer division truncation

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of all original MS SQL statements
2. `converted_statements.sql` - Complete catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This file
