# DMS Conversion Log

## Summary
- **Total Statements**: 7
- **DMS Conversion Successful**: 0
- **DMS Conversion Failed**: 7
- **Manual Conversion Required**: 7
- **DMS Schema Mapping Tool**: Successful (used for table/column name mappings)
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

## DMS Schema Mapping Results (Successful)
The DMS `schema_mapping_tool` successfully returned target schema information:

| Source Table (dbo) | Target Table (productmanagement_dbo) | Column Mapping |
|---|---|---|
| Products | products | ProductId→productid, Name→name, Description→description, Price→price, StockQuantity→stockquantity, CreatedDate→createddate, ModifiedDate→modifieddate |
| ProductHistory | producthistory | HistoryId→historyid, ProductId→productid, Action→action, OldPrice→oldprice, NewPrice→newprice, OldStock→oldstock, NewStock→newstock, ActionDate→actiondate |
| ProductStats | productstats | StatId→statid, TotalProducts→totalproducts, AveragePrice→averageprice, LastUpdated→lastupdated |

## Statement-by-Statement DMS Conversion Attempts

### Statement 1: GetAllProductsAsync()
- **DMS Attempt Timestamp**: 2026-04-10T01:54:28 (first attempt), 2026-04-10T01:55:50 (retry)
- **DMS Status**: error
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased, CTE name changed from ProductStats to productstats_cte to avoid conflict with table name

### Statement 2: GetProductByIdAsync()
- **DMS Attempt Timestamp**: 2026-04-10T01:54:33 (first attempt), 2026-04-10T01:56:26 (retry)
- **DMS Status**: error
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased, CTE name changed from ProductHistory to producthistory_cte to avoid conflict with table name

### Statement 3: InsertProductAsync()
- **DMS Attempt Timestamp**: 2026-04-10T01:56:29
- **DMS Status**: error
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema + structural changes for PostgreSQL compatibility
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Removed `DECLARE @NewProductId INT` and `SET @NewProductId = SCOPE_IDENTITY()` (T-SQL specific)
  - Replaced with `RETURNING productid` clause on INSERT
  - Removed inline `BEGIN TRANSACTION`/`COMMIT` (handled at C# level via NpgsqlTransaction)
  - `GETDATE()` → `NOW()`
  - Split single monolithic SQL into 3 separate statements for C# execution
  - All table/column names lowercased per DMS schema mapping

### Statement 4: UpdateProductAsync()
- **DMS Attempt Timestamp**: 2026-04-10T01:56:33
- **DMS Status**: error
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema + structural changes for PostgreSQL compatibility
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Removed `DECLARE @OldPrice`/`@OldStock` and `SELECT INTO variable` pattern (T-SQL specific)
  - Split into separate SELECT (to get old values) + UPDATE + INSERT + UPDATE statements
  - Removed inline `BEGIN TRANSACTION`/`COMMIT` (handled at C# level)
  - `GETDATE()` → `NOW()`
  - All table/column names lowercased per DMS schema mapping

### Statement 5: DeleteProductAsync()
- **DMS Attempt Timestamp**: 2026-04-10T01:56:36
- **DMS Status**: error
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema + structural changes for PostgreSQL compatibility
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Removed `DECLARE @OldPrice`/`@OldStock` and `SELECT INTO variable` pattern
  - Split into separate SELECT + INSERT + DELETE + UPDATE statements
  - Removed inline `BEGIN TRANSACTION`/`COMMIT` (handled at C# level)
  - `GETDATE()` → `NOW()`
  - All table/column names lowercased per DMS schema mapping

### Statement 6: GetProductsByPriceRangeAsync()
- **DMS Attempt Timestamp**: 2026-04-10T01:56:40
- **DMS Status**: error
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased, CTE name lowercased

### Statement 7: GetLowStockProductsAsync()
- **DMS Attempt Timestamp**: 2026-04-10T01:56:43
- **DMS Status**: error
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion**: Applied lowercase schema object names per DMS schema mapping
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased, CTE name lowercased, added CAST(stockquantity AS NUMERIC) for integer division fix in ROUND
