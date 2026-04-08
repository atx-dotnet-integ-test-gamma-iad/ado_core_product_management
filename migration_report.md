# Migration Report: SQL Server to PostgreSQL

## Overview
- **Project**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13
- **DMS Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Migration Date**: 2026-04-08

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as EQUIVALENT by SQL Equivalency tool | 0 |
| Validated as NOT_EQUIVALENT | 0 |
| Equivalency validation errors | 7 |

### DMS Tool Status
- **DMS statement_conversion_tool**: Failed for all 7 statements
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
  - All 7 statements were attempted through the DMS tool before manual fallback
- **DMS schema_mapping_tool**: Succeeded for all 3 tables (Products, ProductHistory, ProductStats)
  - Schema mapping was used to guide manual conversion (lowercase names, PostgreSQL types)

### SQL Equivalency Tool Status
- **sql-equivalency___validate_sql_equivalence**: Returned ERROR for all 7 statement pairs
  - Error: `'uniqueID'` (consistent tool-side error)
  - All 7 pairs were submitted; none could be validated

### Manual Conversion Method
All 7 statements were manually converted using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`:
- Schema object names converted to lowercase per DMS schema_mapping_tool output
- SQL Server functions replaced with PostgreSQL equivalents
- Transaction syntax updated for PostgreSQL

## Detailed Statement Conversion

### Statement 1: GetAllProductsAsync
- **Location**: ProductRepository.cs (GetAllProductsAsync method)
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Changes**: Table/column names to lowercase
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 2: GetProductByIdAsync
- **Location**: ProductRepository.cs (GetProductByIdAsync method)
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE
- **Changes**: Table/column names to lowercase
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 3: InsertProductAsync
- **Location**: ProductRepository.cs (InsertProductAsync method)
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), UPDATE
- **Changes**:
  - `DECLARE @NewProductId INT` → removed (use `lastval()` directly)
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `SELECT @NewProductId` → `SELECT lastval()`
  - Table/column names to lowercase
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 4: UpdateProductAsync
- **Location**: ProductRepository.cs (UpdateProductAsync method)
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Changes**:
  - `DECLARE @OldPrice/@OldStock` → removed (use C# parameters @OldPrice/@OldStock)
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Table/column names to lowercase
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 5: DeleteProductAsync
- **Location**: ProductRepository.cs (DeleteProductAsync method)
- **Type**: Transaction block with DECLARE, DELETE, INSERT history, UPDATE with CASE
- **Changes**:
  - `DECLARE @OldPrice/@OldStock` → removed (use C# parameters @OldPrice/@OldStock)
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Table/column names to lowercase
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Location**: ProductRepository.cs (GetProductsByPriceRangeAsync method)
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **Changes**: Table/column names to lowercase
- **DMS Status**: Failed
- **Equivalency**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Location**: ProductRepository.cs (GetLowStockProductsAsync method)
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Changes**:
  - Table/column names to lowercase
  - Added `CAST(stockquantity AS NUMERIC)` for integer division fix
- **DMS Status**: Failed
- **Equivalency**: ERROR

## File-by-File Change Summary

### sourceCode/DataAccess/ProductRepository.cs
- **using directives**: `Microsoft.Data.SqlClient` → `Npgsql`
- **Class references**: `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, `SqlDataReader` → `NpgsqlDataReader`
- **SQL strings**: All 7 SQL statements replaced with PostgreSQL equivalents
- **Column name references**: Updated to lowercase in `MapProductFromReader`

### sourceCode/AdoCore.csproj
- **Package**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.0`

### sourceCode/appsettings.json
- **Connection strings**: SQL Server format → PostgreSQL format
  - `Server=` → `Host=`
  - Added `Port=5432`
  - Removed `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
  - Added `Username=postgres;Password=postgres`

## DMS Schema Mapping Reference
| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `[dbo].[Products]` | `products` (schema: `productmanagement_dbo`) |
| `[dbo].[ProductHistory]` | `producthistory` (schema: `productmanagement_dbo`) |
| `[dbo].[ProductStats]` | `productstats` (schema: `productmanagement_dbo`) |
| Column: `ProductId` | Column: `productid` |
| Column: `Name` | Column: `name` |
| Column: `Price` | Column: `price` |
| Type: `int IDENTITY` | Type: `INTEGER GENERATED ALWAYS AS IDENTITY` |
| Type: `nvarchar` | Type: `VARCHAR` |
| Type: `decimal(18,2)` | Type: `NUMERIC(18,2)` |
| Type: `datetime` | Type: `TIMESTAMP WITHOUT TIME ZONE` |
| Function: `GETDATE()` | Function: `clock_timestamp()` |
| Function: `SCOPE_IDENTITY()` | Function: `lastval()` |

## Transformation Artifacts
| Artifact | Location | Content |
|----------|----------|---------|
| Extracted SQL statements | `extracted_statements.sql` | 7 original MS SQL statements |
| Converted SQL statements | `converted_statements.sql` | 7 PostgreSQL equivalents |
| Equivalency validation report | `sql_equivalency_validation_report.json` | 7 statement pairs with ERROR status |

## Build Status
- **Final build**: **PASSED** (0 errors, warnings are pre-existing nullable reference type warnings)
- **Compilation target**: net9.0

## Statements Requiring Manual Review
All 7 statements require manual review due to:
1. DMS tool failure (could not verify automated conversion)
2. SQL Equivalency tool failure (could not verify semantic equivalence)

**Priority statements for review:**
- **InsertProductAsync**: Uses `lastval()` instead of `SCOPE_IDENTITY()` - verify behavior with concurrent inserts
- **UpdateProductAsync**: Uses `@OldPrice`/`@OldStock` parameters - C# code must supply these values before executing
- **DeleteProductAsync**: Uses `@OldPrice`/`@OldStock` parameters - C# code must supply these values before executing
- **GetLowStockProductsAsync**: Added explicit `CAST(stockquantity AS NUMERIC)` for integer division
