# DMS Conversion Log

## Overview
- **Date**: 2026-03-23
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Schema**: dbo
- **Region**: us-east-1
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions (due to DMS failure)**: 7

## DMS Schema Mapping Results (Successful)
The DMS `schema_mapping_tool` was successfully used to retrieve table mappings:

### Products Table
- Source: `[dbo].[Products]` → Target: `productmanagement_dbo.products`
- All columns lowercase: `productid`, `name`, `description`, `price`, `stockquantity`, `createddate`, `modifieddate`
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
- `decimal(18,2)` → `NUMERIC(18,2)`
- `nvarchar` → `VARCHAR`
- `GETDATE()` → `clock_timestamp()`

### ProductHistory Table
- Source: `[dbo].[ProductHistory]` → Target: `productmanagement_dbo.producthistory`
- All columns lowercase: `historyid`, `productid`, `action`, `oldprice`, `newprice`, `oldstock`, `newstock`, `actiondate`, `modifiedby`

### ProductStats Table
- Source: `[dbo].[ProductStats]` → Target: `productmanagement_dbo.productstats`
- All columns lowercase: `statid`, `totalproducts`, `averageprice`, `totalstockvalue`, `lowstockcount`, `discontinuedcount`, `lastupdated`

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-23T02:45:13 - 2026-03-23T02:47:59
- **DMS Workflow**: create_metadata_model (completed) → convert_metadata_model (failed after timeout)
- **Manual Conversion**: Applied lowercase schema mapping per DMS schema_mapping_tool results
- **Key Changes**: Table/column names lowercased. SQL constructs (CTE, CASE, ROUND, OVER) are PostgreSQL-compatible.

### Statement 2: GetProductByIdAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-23T02:48:00 - 2026-03-23T02:50:36
- **DMS Workflow**: create_metadata_model (failed after timeout)
- **Manual Conversion**: Applied lowercase schema mapping. LAG() window function is PostgreSQL-compatible.
- **Key Changes**: Table/column names lowercased.

### Statement 3: InsertProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-23T02:56:12 - 2026-03-23T02:58:47
- **DMS Workflow**: create_metadata_model (failed after timeout)
- **Manual Conversion**: Most complex conversion. Restructured from DECLARE/@variable/SCOPE_IDENTITY() pattern to PostgreSQL CTE with INSERT...RETURNING.
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid` in writable CTE
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @variable` → CTE-based approach (no DECLARE needed)
  - `BEGIN TRANSACTION/COMMIT` → Removed (managed by C# ADO.NET transaction)
  - Entire block restructured as writable CTE chain

### Statement 4: UpdateProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-23T02:58:48 - 2026-03-23T03:03:22
- **DMS Workflow**: create_metadata_model (completed, 12 polls) → convert_metadata_model (failed after timeout)
- **Manual Conversion**: Restructured DECLARE/SELECT INTO pattern to CTE-based approach.
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` + `SELECT INTO @var` → `WITH old_values AS (SELECT...)`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → Removed (managed by C# ADO.NET transaction)
  - Multi-statement block → writable CTE chain

### Statement 5: DeleteProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-23T03:03:40 - 2026-03-23T03:06:15
- **DMS Workflow**: create_metadata_model (failed after timeout)
- **Manual Conversion**: Similar to Statement 4 restructuring with CTE.
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` + `SELECT INTO @var` → `WITH old_values AS (SELECT...)`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → Removed (managed by C# ADO.NET transaction)
  - CASE expression in UPDATE preserved (PostgreSQL-compatible)

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-23T03:06:16 - 2026-03-23T03:11:12
- **DMS Workflow**: create_metadata_model (completed, 14 polls) → convert_metadata_model (failed after timeout)
- **Manual Conversion**: Lowercase schema mapping only. RANK(), PERCENT_RANK(), BETWEEN, CTE all PostgreSQL-compatible.
- **Key Changes**: Table/column names lowercased.

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **DMS Timestamp**: 2026-03-23T03:11:12 - 2026-03-23T03:13:47
- **DMS Workflow**: create_metadata_model (failed after timeout)
- **Manual Conversion**: Lowercase schema mapping + CAST for integer division.
- **Key Changes**:
  - Table/column names lowercased
  - Added `CAST(stockquantity AS NUMERIC)` for integer division compatibility in ROUND()

## SQL Equivalency Validation Results
All 7 statement pairs were submitted to the SQL Equivalency validation tool.
All 7 returned ERROR status with error: `'uniqueID'`.
This appears to be a systemic issue with the equivalency tool, not specific to any statement.
The ERROR status is recorded as-is per the transformation definition requirements.
