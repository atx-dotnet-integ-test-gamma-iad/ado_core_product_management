# DMS Conversion Failure Summary Log
# Date: 2026-05-05
# Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

## Summary
All 7 SQL statements failed DMS conversion with the same error.
Manual conversion applied using DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Status**: error
- **Workflow Step Failed**: create_metadata_model
- **Server**: 172.31.83.165
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **DMS Attempt Timestamp**: 2026-05-05T07:16:56.361435
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Approach**: Lowercase schema objects, CTE and window functions compatible as-is with PostgreSQL

### Statement 2: GetProductByIdAsync
- **DMS Attempt Timestamp**: 2026-05-05T07:17:26.844033
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Approach**: Lowercase schema objects, LAG window function compatible as-is with PostgreSQL

### Statement 3: InsertProductAsync
- **DMS Attempt Timestamp**: 2026-05-05T07:17:45.390695
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Approach**: 
  - Replaced SCOPE_IDENTITY() with INSERT...RETURNING clause
  - Replaced GETDATE() with NOW()
  - Removed DECLARE @variable patterns (handled in application code)
  - Transaction management moved to application code (Npgsql BeginTransaction)
  - Lowercase schema object names

### Statement 4: UpdateProductAsync
- **DMS Attempt Timestamp**: 2026-05-05T07:17:59.223587
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Approach**:
  - Replaced DECLARE @variable patterns with separate SELECT query
  - Replaced GETDATE() with NOW()
  - Transaction management moved to application code (Npgsql BeginTransaction)
  - Lowercase schema object names

### Statement 5: DeleteProductAsync
- **DMS Attempt Timestamp**: 2026-05-05T07:18:12.628673
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Approach**:
  - Replaced DECLARE @variable patterns with separate SELECT query
  - Replaced GETDATE() with NOW()
  - Transaction management moved to application code (Npgsql BeginTransaction)
  - Lowercase schema object names

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt Timestamp**: 2026-05-05T07:18:25.750907
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Approach**: Lowercase schema objects, RANK/PERCENT_RANK window functions compatible as-is with PostgreSQL

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt Timestamp**: 2026-05-05T07:18:40.241306
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes
- **Conversion Approach**: 
  - Lowercase schema objects
  - AVG/MIN/MAX window functions compatible as-is with PostgreSQL
  - Added CAST for integer division to avoid integer truncation in ROUND
