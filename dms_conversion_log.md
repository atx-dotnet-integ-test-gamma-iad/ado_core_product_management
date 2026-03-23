# DMS Conversion Log

## Migration Context
- **Project**: AdoCore - MS SQL Server to PostgreSQL Migration
- **DMS Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Migration Project Identifier**: `NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Date**: 2026-03-23

## DMS Tool Availability

**Status: FAILED - AccessDeniedException**

All 7 DMS conversion attempts failed with the same error:
```
AccessDeniedException: User: arn:aws:sts::812756961751:assumed-role/AWSTransform-Connector-role-mi98stgw-wWlUW/AWSTransformConnectorDataPlane-* 
is not authorized to perform: dms:StartMetadataModelCreation on resource: 
arn:aws:dms:us-east-1:812756961751:migration-project:* 
because no identity-based policy allows the dms:StartMetadataModelCreation action
```

## Conversion Attempts

### Statement 1: GetAllProductsAsync
- **DMS Call Timestamp**: 2026-03-23T10:25:52.014324
- **DMS Status**: error
- **DMS Error**: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
- **Fallback**: Manual conversion with lowercase schema object names
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: All table names (Products → products), column names (ProductId → productid, Name → name, etc.), CTE names (ProductStats → productstats), alias names lowercased

### Statement 2: GetProductByIdAsync
- **DMS Call Timestamp**: 2026-03-23T10:26:33.800331
- **DMS Status**: error
- **DMS Error**: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
- **Fallback**: Manual conversion with lowercase schema object names
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: All table/column/CTE/alias names lowercased (Products → products, ProductHistory → producthistory, etc.)

### Statement 3: InsertProductAsync
- **DMS Call Timestamp**: 2026-03-23T10:26:47.138552
- **DMS Status**: error
- **DMS Error**: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
- **Fallback**: Manual conversion with lowercase schema object names
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - `SCOPE_IDENTITY()` → `lastval()` (PostgreSQL sequence function)
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId INT` → removed (using `lastval()` instead)
  - `SET @NewProductId = SCOPE_IDENTITY()` → removed (using `lastval()`)
  - `SELECT @NewProductId` → `SELECT lastval()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - All table/column names lowercased

### Statement 4: UpdateProductAsync
- **DMS Call Timestamp**: 2026-03-23T10:26:58.784544
- **DMS Status**: error
- **DMS Error**: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
- **Fallback**: Manual conversion with lowercase schema object names
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - `DECLARE @OldPrice DECIMAL(18,2)` → removed (using subquery approach)
  - `DECLARE @OldStock INT` → removed
  - `SELECT @OldPrice = Price, @OldStock = StockQuantity` → subquery approach
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - All table/column names lowercased

### Statement 5: DeleteProductAsync
- **DMS Call Timestamp**: 2026-03-23T10:27:10.721763
- **DMS Status**: error
- **DMS Error**: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
- **Fallback**: Manual conversion with lowercase schema object names
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - `DECLARE @OldPrice DECIMAL(18,2)` → removed (using subquery approach)
  - `DECLARE @OldStock INT` → removed
  - `SELECT @OldPrice = ...` → subquery in INSERT
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - All table/column names lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Call Timestamp**: 2026-03-23T10:27:27.681194
- **DMS Status**: error
- **DMS Error**: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
- **Fallback**: Manual conversion with lowercase schema object names
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**: All table/column/CTE/alias names lowercased (Products → products, RankedProducts → rankedproducts, etc.)

### Statement 7: GetLowStockProductsAsync
- **DMS Call Timestamp**: 2026-03-23T10:27:40.771492
- **DMS Status**: error
- **DMS Error**: AccessDeniedException - not authorized to perform dms:StartMetadataModelCreation
- **Fallback**: Manual conversion with lowercase schema object names
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - Added `CAST(stockquantity AS DECIMAL)` for integer division in ROUND to avoid integer truncation
  - All table/column/CTE/alias names lowercased (Products → products, StockAnalysis → stockanalysis, etc.)

## SQL Equivalency Validation

**Status: ALL ERROR**

All 7 equivalency validation attempts returned ERROR with `'uniqueID'` error. The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) appears to have a systemic issue unrelated to individual statement quality. Each statement was individually submitted and each returned the same error.

### Equivalency Validation Timestamps:
1. Statement 1 (GetAllProductsAsync): 2026-03-23T10:28:07.307827 - ERROR: 'uniqueID'
2. Statement 2 (GetProductByIdAsync): 2026-03-23T10:28:21.209974 - ERROR: 'uniqueID'
3. Statement 3 (InsertProductAsync): 2026-03-23T10:28:51.070728 - ERROR: 'uniqueID'
4. Statement 4 (UpdateProductAsync): 2026-03-23T10:29:09.408800 - ERROR: 'uniqueID'
5. Statement 5 (DeleteProductAsync): 2026-03-23T10:29:23.361504 - ERROR: 'uniqueID'
6. Statement 6 (GetProductsByPriceRangeAsync): 2026-03-23T10:29:36.675665 - ERROR: 'uniqueID'
7. Statement 7 (GetLowStockProductsAsync): 2026-03-23T10:29:49.718914 - ERROR: 'uniqueID'

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7 (all AccessDeniedException)
- **Manual Conversions**: 7 (all with DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Equivalency Validated (EQUIVALENT)**: 0
- **Equivalency Validated (NOT_EQUIVALENT)**: 0
- **Equivalency Errors**: 7 (all 'uniqueID' error)
