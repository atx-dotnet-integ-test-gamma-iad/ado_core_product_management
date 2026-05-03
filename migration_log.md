# Migration Log: SQL Server to PostgreSQL

## Overview
This log documents every SQL statement processed during the migration from Microsoft SQL Server to PostgreSQL for the AdoCore .NET application.

## DMS MCP Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Status**: FAILED for all 7 inline SQL statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Note**: DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) worked successfully and provided schema mappings

## Schema Mappings (from DMS Schema Mapping Tool)
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `[dbo].[Products]` | `products` (schema: `productmanagement_dbo`) |
| `[dbo].[ProductHistory]` | `producthistory` |
| `[dbo].[ProductStats]` | `productstats` |
| `[dbo].[Categories]` | `categories` |
| `[dbo].[Suppliers]` | `suppliers` |
| All column names | Lowercase equivalents |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `LASTVAL()` |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `nvarchar` | `VARCHAR` |
| `decimal` | `NUMERIC` |
| `bit` | `NUMERIC(1,0)` |
| `SYSTEM_USER` | `CURRENT_USER` |

---

## Statement 1: GetAllProductsAsync()
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, Window Functions, CASE, ROUND, INNER JOIN
- **DMS Result**: FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - `ROUND((p.Price / ps.AvgPrice) * 100, 2)` → `ROUND((p.price / ps.avgprice * 100)::numeric, 2)` (added `::numeric` cast)
- **SQL Equivalency Tool Result**: ERROR - `'uniqueID'`

## Statement 2: GetProductByIdAsync()
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG Window Function, CASE, ROUND, LEFT JOIN
- **Parameters**: `@ProductId`
- **DMS Result**: FAILED - Same error
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - `ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)` → `ROUND(((p.price - ph.previousprice) / ph.previousprice * 100)::numeric, 2)` (added `::numeric` cast)
- **SQL Equivalency Tool Result**: ERROR - `'uniqueID'`

## Statement 3: InsertProductAsync()
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction Block (DECLARE, INSERT, SCOPE_IDENTITY, UPDATE, SELECT)
- **Parameters**: `@Name, @Description, @Price, @StockQuantity`
- **DMS Result**: FAILED - Same error
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - Removed `DECLARE @NewProductId INT` (not supported in PostgreSQL plain SQL)
  - Removed `BEGIN TRANSACTION` / `COMMIT` (handled by ADO.NET)
  - `SCOPE_IDENTITY()` → `LASTVAL()`
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names converted to lowercase
- **SQL Equivalency Tool Result**: ERROR - `'uniqueID'`

## Statement 4: UpdateProductAsync()
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction Block (DECLARE, SELECT INTO variables, UPDATE, INSERT)
- **Parameters**: `@ProductId, @Name, @Description, @Price, @StockQuantity`
- **DMS Result**: FAILED - Same error
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - Removed `DECLARE @OldPrice` / `DECLARE @OldStock` (not supported in PostgreSQL plain SQL)
  - Replaced variable references with subqueries: `@OldPrice` → `(SELECT price FROM products WHERE productid = @ProductId)`
  - Reordered operations: INSERT history first, UPDATE stats, UPDATE products last (to capture old values)
  - Removed `BEGIN TRANSACTION` / `COMMIT` (handled by ADO.NET)
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names converted to lowercase
- **SQL Equivalency Tool Result**: ERROR - `'uniqueID'`

## Statement 5: DeleteProductAsync()
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction Block (DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE)
- **Parameters**: `@ProductId`
- **DMS Result**: FAILED - Same error
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - Same DECLARE/variable removal pattern as Statement 4
  - Replaced variable references with subqueries
  - Reordered operations: INSERT history first, UPDATE stats, DELETE last (to capture old values)
  - Removed `BEGIN TRANSACTION` / `COMMIT` (handled by ADO.NET)
  - `GETDATE()` → `clock_timestamp()`
  - All table/column names converted to lowercase
- **SQL Equivalency Tool Result**: ERROR - `'uniqueID'`

## Statement 6: GetProductsByPriceRangeAsync()
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK, PERCENT_RANK Window Functions, BETWEEN, CASE
- **Parameters**: `@MinPrice, @MaxPrice`
- **DMS Result**: FAILED - Same error
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - Window functions (RANK, PERCENT_RANK) are compatible, only lowercase changes needed
- **SQL Equivalency Tool Result**: ERROR - `'uniqueID'`

## Statement 7: GetLowStockProductsAsync()
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Parameters**: `@Threshold`
- **DMS Result**: FAILED - Same error
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND((stockquantity::numeric / avgstock * 100)::numeric, 2)` (added `::numeric` casts for integer division)
- **SQL Equivalency Tool Result**: ERROR - `'uniqueID'`

---

## Script File Conversions

### Scripts/01_InitialSetup.sql
- Removed `IF NOT EXISTS (SELECT * FROM sys.databases ...)` checks
- Removed `IF NOT EXISTS (SELECT * FROM sys.objects ...)` checks
- Converted to `CREATE TABLE IF NOT EXISTS`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION ... RETURNS TABLE ... LANGUAGE plpgsql`
- Removed `GO` statements
- Removed `SET NOCOUNT ON`
- `SCOPE_IDENTITY()` → `RETURNING ... INTO`
- `GETDATE()` → `clock_timestamp()`

### Database/Scripts/01_InitialSetup.sql
- `IF EXISTS ... DROP` → `DROP ... IF EXISTS`
- All `CREATE TABLE` statements converted with PostgreSQL types
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `[nvarchar]` → `VARCHAR`, `[datetime]` → `TIMESTAMP WITHOUT TIME ZONE`
- `[bit]` → `NUMERIC(1,0)` (per DMS mapping)
- `SYSTEM_USER` → `CURRENT_USER`
- SQL Server trigger → PostgreSQL trigger function + CREATE TRIGGER
- All stored procedures → PostgreSQL functions
- All `[dbo].` schema prefixes removed
- All `GO` batch separators removed
- Indexes: Removed `[dbo].` prefixes, kept lowercase names

---

## SQL Equivalency Validation Summary
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Status**: All 7 statement pairs returned ERROR with `'uniqueID'` error
- **Note**: The equivalency tool experienced a consistent internal error for all statements
- **Report**: See `sql_equivalency_validation_report.json` for full details
