# DMS Conversion Log

## Summary
All 7 SQL statements from `DataAccess/ProductRepository.cs` were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. **All 7 failed** due to metadata model creation/conversion timeout errors. Manual conversion with lowercase schema object names was applied for all statements per the transformation definition.

## DMS Tool Configuration
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database Name**: `ProductManagement`
- **Schema Name**: `dbo`
- **Region**: `us-east-1`
- **Server Name**: `172.31.83.165` (auto-resolved)

---

## Statement 1: GetAllProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-26T03:10:52 - 2026-03-26T03:13:38
- **DMS Attempts**: 3 (tried with default settings, then with max_poll_attempts=30/poll_interval=15, then again with default)
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: All table/column names lowercased (Products→products, ProductId→productid, etc.). SQL syntax (CTE, window functions, CASE, ROUND, ORDER BY) is already PostgreSQL-compatible.

## Statement 2: GetProductByIdAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-26T03:26:27 - 2026-03-26T03:29:02
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: All table/column names lowercased. LAG window function, LEFT JOIN, CASE, ROUND syntax is already PostgreSQL-compatible.

## Statement 3: InsertProductAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"}`
- **DMS Timestamp**: 2026-03-26T03:29:14 - 2026-03-26T03:31:49
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Removed `DECLARE @NewProductId INT` and `SET @NewProductId = SCOPE_IDENTITY()` pattern
  - Replaced `SCOPE_IDENTITY()` with `lastval()` (PostgreSQL function to get last auto-generated sequence value)
  - Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
  - Replaced `BEGIN TRANSACTION/COMMIT` with `BEGIN/COMMIT` (PostgreSQL syntax)
  - All table/column names lowercased

## Statement 4: UpdateProductAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-26T03:32:01 - 2026-03-26T03:36:15
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Converted T-SQL `DECLARE @variable` / `SELECT @variable = column` pattern to PostgreSQL `DO $$ DECLARE ... BEGIN ... END $$` anonymous block
  - Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
  - Replaced `BEGIN TRANSACTION/COMMIT` with anonymous DO block (handles its own transaction)
  - All table/column names lowercased

## Statement 5: DeleteProductAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-26T03:36:25 - 2026-03-26T03:39:00
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Converted T-SQL `DECLARE @variable` / `SELECT @variable = column` pattern to PostgreSQL `DO $$ DECLARE ... BEGIN ... END $$` anonymous block
  - Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
  - Replaced `BEGIN TRANSACTION/COMMIT` with anonymous DO block
  - All table/column names lowercased

## Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-26T03:39:12 - 2026-03-26T03:41:47
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: All table/column names lowercased. RANK(), PERCENT_RANK(), BETWEEN, CASE syntax is already PostgreSQL-compatible.

## Statement 7: GetLowStockProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-26T03:41:59 - 2026-03-26T03:44:34
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: All table/column names lowercased. Added explicit CAST for integer division to prevent integer truncation in PostgreSQL. AVG(), MIN(), MAX() window functions and CASE syntax are PostgreSQL-compatible.
