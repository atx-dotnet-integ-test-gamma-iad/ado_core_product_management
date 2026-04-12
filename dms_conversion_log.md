# DMS Conversion Log

## Migration Project Details
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database Name**: ProductManagement
- **Schema Name**: dbo
- **Region**: us-east-1
- **Server**: 172.31.83.165

## Schema Mapping Results (Successful)
The DMS schema_mapping_tool was successful and returned:

### Products Table
- **Source**: `[dbo].[Products]` → **Target**: `productmanagement_dbo.products`
- All column names converted to lowercase

### ProductHistory Table
- **Source**: `[dbo].[ProductHistory]` → **Target**: `productmanagement_dbo.producthistory`
- All column names converted to lowercase

### ProductStats Table
- **Source**: `[dbo].[ProductStats]` → **Target**: `productmanagement_dbo.productstats`
- All column names converted to lowercase

## Statement Conversion Attempts

All 7 statements failed with the same DMS error. Each is documented below.

### Statement 1: GetAllProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-12T05:54:04.707573
- **Manual Conversion Applied**: Yes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - CTE name `ProductStats` renamed to `productstats_cte` to avoid conflict with table name

### Statement 2: GetProductByIdAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-12T05:55:18.852361
- **Manual Conversion Applied**: Yes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - CTE name `ProductHistory` renamed to `producthistory_cte` to avoid conflict with table name

### Statement 3: InsertProductAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-12T05:55:33.090842
- **Manual Conversion Applied**: Yes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - `SCOPE_IDENTITY()` replaced with `RETURNING productid` clause
  - `GETDATE()` replaced with `clock_timestamp()`
  - `BEGIN TRANSACTION`/`COMMIT` replaced with C#-level transaction management
  - `DECLARE @NewProductId INT` removed; variable handling moved to C# code
  - Single monolithic SQL split into 3 separate parameterized statements executed within a C# transaction

### Statement 4: UpdateProductAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-12T05:55:47.372243
- **Manual Conversion Applied**: Yes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - `GETDATE()` replaced with `clock_timestamp()`
  - `BEGIN TRANSACTION`/`COMMIT` replaced with C#-level transaction management
  - `DECLARE @OldPrice`/`DECLARE @OldStock` removed; variable handling moved to C# code
  - `SELECT @OldPrice = Price, @OldStock = StockQuantity` converted to separate SELECT query with C# variable binding
  - Single monolithic SQL split into 4 separate parameterized statements executed within a C# transaction

### Statement 5: DeleteProductAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-12T05:56:01.330316
- **Manual Conversion Applied**: Yes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - `GETDATE()` replaced with `clock_timestamp()`
  - `BEGIN TRANSACTION`/`COMMIT` replaced with C#-level transaction management
  - `DECLARE @OldPrice`/`DECLARE @OldStock` removed; variable handling moved to C# code
  - Single monolithic SQL split into 4 separate parameterized statements executed within a C# transaction

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-12T05:56:15.399454
- **Manual Conversion Applied**: Yes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-12T05:56:29.644117
- **Manual Conversion Applied**: Yes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes Applied**:
  - All table/column names converted to lowercase
  - Added `CAST(stockquantity AS DECIMAL)` for integer division fix in PostgreSQL

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error `'uniqueID'`.
See `sql_equivalency_validation_report.json` for the complete report.

## Summary
- **Total Statements**: 7
- **DMS Conversions Successful**: 0
- **DMS Conversions Failed**: 7
- **Manual Conversions Applied**: 7
- **Equivalency Validations**: 7 (all ERROR due to tool issue)
