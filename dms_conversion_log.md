# DMS Conversion Log

## Summary
- **Date**: 2026-05-01
- **Total Statements Processed**: 7 (from ProductRepository.cs)
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Applied**: 7

## DMS Tool Configuration
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Server**: 172.31.83.165

## Schema Mapping (Successfully Retrieved from DMS)
The DMS schema_mapping_tool successfully provided the following mappings:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`
- `dbo.Categories` → `productmanagement_dbo.categories`
- `dbo.Suppliers` → `productmanagement_dbo.suppliers`
- All column names → lowercase
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `GETDATE()` → `clock_timestamp()`
- `nvarchar` → `varchar`
- `bit` → `NUMERIC(1,0)`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`

---

## Statement 1: GetAllProductsAsync

### DMS Tool Attempt
- **Timestamp**: 2026-05-01T18:05:06 and 2026-05-01T18:05:24
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: 
  - Table name `Products` → `products`
  - Column names lowercased (ProductId → productid, Name → name, etc.)
  - CTE name `ProductStats` → `productstats`
  - All alias names lowercased
  - SQL syntax (CTE, CASE, ROUND, OVER, INNER JOIN, ORDER BY) is PostgreSQL-compatible

---

## Statement 2: GetProductByIdAsync

### DMS Tool Attempt
- **Timestamp**: 2026-05-01T18:05:47
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: 
  - Table name `Products` → `products`
  - Column names lowercased
  - CTE name `ProductHistory` → `producthistory`
  - LAG window function syntax is PostgreSQL-compatible
  - Parameter @ProductId preserved (Npgsql supports @ prefix)

---

## Statement 3: InsertProductAsync

### DMS Tool Attempt
- **Timestamp**: 2026-05-01T18:05:51
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: 
  - `SCOPE_IDENTITY()` → `RETURNING productid` with CTE-based approach
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @NewProductId INT` → Eliminated, used CTE with RETURNING
  - `BEGIN TRANSACTION/COMMIT` → Removed from SQL (managed by ADO.NET BeginTransactionAsync)
  - Table names: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
  - All column names lowercased

---

## Statement 4: UpdateProductAsync

### DMS Tool Attempt
- **Timestamp**: 2026-05-01T18:05:54
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: 
  - `DECLARE @OldPrice / @OldStock` → Eliminated, used CTE with subquery
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → Removed from SQL (managed by ADO.NET BeginTransactionAsync)
  - Table names lowercased
  - All column names lowercased

---

## Statement 5: DeleteProductAsync

### DMS Tool Attempt
- **Timestamp**: 2026-05-01T18:06:15
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: 
  - `DECLARE @OldPrice / @OldStock` → Eliminated, used CTE with subquery
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → Removed from SQL (managed by ADO.NET BeginTransactionAsync)
  - Table names lowercased
  - All column names lowercased

---

## Statement 6: GetProductsByPriceRangeAsync

### DMS Tool Attempt
- **Timestamp**: 2026-05-01T18:06:18
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: 
  - Table name `Products` → `products`
  - Column names lowercased
  - CTE name `RankedProducts` → `rankedproducts`
  - RANK(), PERCENT_RANK(), BETWEEN syntax is PostgreSQL-compatible
  - Parameters @MinPrice, @MaxPrice preserved

---

## Statement 7: GetLowStockProductsAsync

### DMS Tool Attempt
- **Timestamp**: 2026-05-01T18:06:22
- **Status**: ERROR
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

### Manual Conversion
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: 
  - Table name `Products` → `products`
  - Column names lowercased
  - CTE name `StockAnalysis` → `stockanalysis`
  - Added `::numeric` cast for integer division in ROUND function
  - AVG/MIN/MAX window functions are PostgreSQL-compatible
  - Parameter @Threshold preserved



---

## SQL Script Conversions (Step 4)

### Scripts/01_InitialSetup.sql - Summary
- **Total Logical Statements**: 7 (CREATE TABLE, 5 stored procedures, INSERT sample data)
- **DMS Attempts**: 3 representative statements attempted
- **DMS Results**: All 3 failed with same error
- **Manual Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Database/Scripts/01_InitialSetup.sql - Summary
- **Total Logical Statements**: 12 (5 CREATE TABLEs, 5 CREATE INDEXes, INSERT data x3, UPDATE stats, TRIGGER, 5 stored procedures)
- **DMS Attempts**: 3 representative statements attempted (CREATE TABLE, stored procedure, trigger)
- **DMS Results**: All failed with same error
- **Manual Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Key Script Conversions Applied:
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `GETDATE()` → `clock_timestamp()`
- `NVARCHAR(n)` → `VARCHAR(n)`
- `BIT` → `BOOLEAN`
- `GO` statements → removed
- `IF NOT EXISTS (SELECT * FROM sys.objects ...)` → `CREATE TABLE IF NOT EXISTS` / `DROP TABLE IF EXISTS`
- `IF NOT EXISTS (SELECT * FROM sys.databases ...)` → Comment with instructions
- `USE database` → Comment (connect to database manually)
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION` returning TABLE/VOID
- `SET NOCOUNT ON` → removed (not needed in PostgreSQL)
- `SCOPE_IDENTITY()` → `RETURNING ... INTO`
- `EXEC sp_name` → `PERFORM sp_name()` / `SELECT sp_name()`
- `SYSTEM_USER` → `current_user`
- `CREATE TRIGGER` → `CREATE OR REPLACE FUNCTION` + `CREATE TRIGGER` (PostgreSQL trigger function pattern)
- `inserted/deleted` pseudo-tables → `NEW/OLD` record references
- `IF EXISTS (SELECT 1 FROM inserted)` → `IF TG_OP = 'INSERT'` pattern
- `DEFAULT 1` (bit) → `DEFAULT TRUE` (boolean)
- `DEFAULT 0` (bit) → `DEFAULT FALSE` (boolean)
- `IsDiscontinued = 1` → `isdiscontinued = TRUE`

### DMS Tool Error (consistent across all attempts):
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
