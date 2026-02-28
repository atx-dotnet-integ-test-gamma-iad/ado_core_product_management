# DMS Conversion Log

## Summary
- **Total Statements Processed**: 20 (7 from ProductRepository.cs + 13 from SQL scripts)
- **DMS Successful Conversions**: 0
- **DMS Failures (Manual Conversion Required)**: 20
- **Conversion Method for All**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Common DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

## DMS Tool Parameters Used
- **migration_project_identifier**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **database_name**: `ProductManagement`
- **schema_name**: `dbo`
- **region**: `us-east-1`
- **server_name**: `172.31.83.165` (auto-detected)

## Part 1: ProductRepository.cs Inline SQL (Statements 1-7)

### Statement 1: GetAllProductsAsync
- **DMS Attempt**: Failed at 2026-02-28T04:25:23
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Retry Attempt**: Failed at 2026-02-28T04:25:37 (with increased poll_interval_seconds=15, max_poll_attempts=30)
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Schema names lowercased (Products→products, ProductId→productid, etc.)

### Statement 2: GetProductByIdAsync
- **DMS Attempt**: Failed at 2026-02-28T04:26:13
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Schema names lowercased, LAG window function syntax preserved (PostgreSQL compatible)

### Statement 3: InsertProductAsync
- **DMS Attempt**: Failed at 2026-02-28T04:26:28
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names + SQL Server-specific construct conversion
- **Key Changes**:
  - `SCOPE_IDENTITY()` → Replaced with `INSERT...RETURNING` clause in CTE
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId INT` / `SET @NewProductId = ...` → CTE-based approach with `RETURNING`
  - `BEGIN TRANSACTION` / `COMMIT` → Removed (transaction managed by C# code via BeginTransactionAsync)
  - Multi-table operations restructured into writable CTEs

### Statement 4: UpdateProductAsync
- **DMS Attempt**: Failed at 2026-02-28T04:26:45
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names + SQL Server-specific construct conversion
- **Key Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` / `COMMIT` → Removed (transaction managed by C# code)
  - Restructured into writable CTEs

### Statement 5: DeleteProductAsync
- **DMS Attempt**: Failed at 2026-02-28T04:26:58
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names + SQL Server-specific construct conversion
- **Key Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - CASE expression in UPDATE preserved (PostgreSQL compatible)
  - Restructured into writable CTEs

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt**: Failed at 2026-02-28T04:27:13
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt**: Failed at 2026-02-28T04:27:27
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names + `CAST(stockquantity AS DECIMAL)` for integer division

## Part 2: SQL Setup Scripts (Statements 8-20)

### Statement 8: CREATE TABLE Products (simple - Scripts/01_InitialSetup.sql)
- **DMS Attempt**: Failed at 2026-02-28T04:38:11
- **Error**: `Metadata model creation failed`
- **Key Changes**: IDENTITY(1,1)→SERIAL, nvarchar→varchar, datetime→timestamp, GETDATE()→NOW(), [dbo].[]→removed

### Statement 9: CREATE TABLE Categories
- **DMS Attempt**: Failed at 2026-02-28T04:40:21
- **Error**: `Metadata model creation failed`
- **Key Changes**: IDENTITY(1,1)→SERIAL, nvarchar→varchar, datetime→timestamp, GETDATE()→NOW()

### Statement 10: CREATE TABLE Suppliers
- **DMS Attempt**: Failed (same error pattern)
- **Key Changes**: IDENTITY(1,1)→SERIAL, nvarchar→varchar, [bit]→BOOLEAN, DEFAULT 1→DEFAULT TRUE

### Statement 11: CREATE TABLE Products (comprehensive - Database/Scripts/01_InitialSetup.sql)
- **DMS Attempt**: Failed (same error pattern)
- **Key Changes**: All of Statement 8 plus FOREIGN KEY references lowercased, [bit]→BOOLEAN

### Statement 12: CREATE TABLE ProductHistory
- **DMS Attempt**: Failed (same error pattern)
- **Key Changes**: IDENTITY(1,1)→SERIAL, nvarchar→varchar, FOREIGN KEY reference lowercased

### Statement 13: CREATE TABLE ProductStats
- **DMS Attempt**: Failed (same error pattern)
- **Key Changes**: Schema names lowercased, datetime→timestamp

### Statement 14: CREATE TRIGGER trg_Products_History
- **DMS Attempt**: Failed at 2026-02-28T04:40:36
- **Error**: `Metadata model creation failed`
- **Key Changes**: Complete restructure to PostgreSQL trigger function pattern:
  - SQL Server single trigger with inserted/deleted pseudo-tables → PostgreSQL trigger function + trigger
  - `SYSTEM_USER` → `CURRENT_USER`
  - IF EXISTS (SELECT 1 FROM inserted) → IF (TG_OP = 'INSERT')
  - `inserted.column` → `NEW.column`
  - `deleted.column` → `OLD.column`
  - SET NOCOUNT ON → removed

### Statements 15-19: Stored Procedures (sp_GetAllProducts, sp_GetProductById, sp_InsertProduct, sp_UpdateProduct, sp_DeleteProduct)
- **DMS Attempt**: Failed at 2026-02-28T04:39:50 (sp_GetAllProducts tested)
- **Error**: `Metadata model creation failed`
- **Key Changes**:
  - `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
  - `@Parameter` → `p_parameter` (function parameter naming)
  - `SET NOCOUNT ON` → removed
  - `SCOPE_IDENTITY()` → `RETURNING ... INTO variable`
  - `GETDATE()` → `NOW()`
  - Return types: `RETURNS TABLE(...)` for SELECT procedures, `RETURNS INT/VOID` for DML

### Statement 20: UPDATE ProductStats (initial statistics)
- **DMS Attempt**: Failed (same error pattern)
- **Key Changes**: Schema names lowercased, `IsDiscontinued = 1` → `isdiscontinued = TRUE`, `GETDATE()` → `NOW()`

## SQL Equivalency Validation Summary
- **Tool Used**: sql-equivalency___validate_sql_equivalence
- **All 20 statements validated**: All returned ERROR with `'uniqueID'` error
- **Note**: The SQL Equivalency tool had a systemic error affecting all validations. Per transformation rules, all statements are marked as ERROR (no agent judgment substituted).

## Manual Conversion Rules Applied
Per the transformation definition, when DMS fails, the following rules were applied:
1. **Lowercase Schema Object Names**: All table names, column names, view names, procedure names converted to lowercase
2. **SQL Server Functions**: `SCOPE_IDENTITY()`→`RETURNING`, `GETDATE()`→`NOW()`, `SYSTEM_USER`→`CURRENT_USER`
3. **SQL Server Constructs**: `DECLARE @variable`→CTE/PL/pgSQL variables, `BEGIN TRANSACTION`/`COMMIT`→managed by app code
4. **Data Types**: `nvarchar`→`varchar`, `datetime`→`timestamp`, `[bit]`→`BOOLEAN`, `IDENTITY(1,1)`→`SERIAL`
5. **Syntax**: `[dbo].[TableName]`→`tablename`, `GO`→removed, `SET NOCOUNT ON`→removed
6. **Procedures→Functions**: `CREATE OR ALTER PROCEDURE`→`CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql`
7. **Triggers**: Restructured to PostgreSQL trigger function + trigger pattern, `inserted`/`deleted`→`NEW`/`OLD` with `TG_OP`
8. **PostgreSQL-specific**: Integer division `CAST(... AS DECIMAL)`, `DEFAULT 1`→`DEFAULT TRUE` for boolean
