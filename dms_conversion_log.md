# DMS Conversion Log

## Overview
- **Date**: 2026-02-27
- **DMS Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Region**: us-east-1
- **Source Schema**: dbo
- **Database**: ProductManagement
- **Total Statements Attempted**: 7
- **Successful DMS Conversions**: 0
- **Failed DMS Conversions**: 7

## DMS Error Summary
All 7 statements failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The error occurs at the `create_metadata_model` workflow step. The DMS service appears to be unable to create the metadata model needed for conversion, returning a status of "RECEIVED" which the tool cannot process.

Multiple retry attempts were made with different configurations:
1. Default poll settings (15 attempts, 10s interval) - Failed
2. Extended poll settings (30 attempts, 15s interval) - Failed
3. With explicit server_name parameter - Failed

## Statement-by-Statement DMS Log

### Statement 1: GetAllProductsAsync
- **Timestamp**: 2026-02-27T18:46:39.270468
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: Window functions (AVG OVER, COUNT OVER) are PostgreSQL-compatible. Lowercased all schema objects.

### Statement 2: GetProductByIdAsync
- **Timestamp**: 2026-02-27T18:47:26.520411
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: LAG window function is PostgreSQL-compatible. Lowercased all schema objects. Parameter @ProductId preserved for Npgsql binding.

### Statement 3: InsertProductAsync
- **Timestamp**: 2026-02-27T18:47:42.351668
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: 
  - SCOPE_IDENTITY() → RETURNING productid INTO v_newproductid
  - GETDATE() → NOW()
  - DECLARE @NewProductId INT → DECLARE v_newproductid INT in DO $$ block
  - BEGIN TRANSACTION/COMMIT → Restructured as individual statements (transaction managed by Npgsql at C# level)
  - Lowercased all schema objects

### Statement 4: UpdateProductAsync
- **Timestamp**: 2026-02-27T18:47:57.534674
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**:
  - DECLARE @OldPrice/@OldStock → DECLARE v_oldprice/v_oldstock in DO $$ block
  - SELECT @var = col → SELECT col INTO v_var (PostgreSQL syntax)
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → Restructured (transaction managed by Npgsql)
  - Lowercased all schema objects

### Statement 5: DeleteProductAsync
- **Timestamp**: 2026-02-27T18:48:12.659475
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**:
  - Same DECLARE/SELECT INTO restructuring as Statement 4
  - GETDATE() → NOW()
  - CASE WHEN expression preserved (compatible with PostgreSQL)
  - Lowercased all schema objects

### Statement 6: GetProductsByPriceRangeAsync
- **Timestamp**: 2026-02-27T18:48:27.264355
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: RANK(), PERCENT_RANK(), BETWEEN are PostgreSQL-compatible. Lowercased all schema objects.

### Statement 7: GetLowStockProductsAsync
- **Timestamp**: 2026-02-27T18:48:42.337231
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: 
  - AVG/MIN/MAX window functions are PostgreSQL-compatible
  - Added CAST(stockquantity AS NUMERIC) for integer division in ROUND to avoid integer truncation
  - Lowercased all schema objects

## SQL Equivalency Validation Summary
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error: `'uniqueID'`

This appears to be a systemic issue with the SQL Equivalency tool service, not related to the statements themselves.
