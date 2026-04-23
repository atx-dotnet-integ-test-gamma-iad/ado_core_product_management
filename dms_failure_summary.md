# DMS Conversion Failure Summary
# ================================
# All 7 SQL statements failed DMS conversion with the same error.
# Manual conversions were applied with lowercase schema object names.

## DMS Error (Same for all 7 statements)
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1

## Statement 1: GetAllProductsAsync
- **DMS Timestamp**: 2026-04-23T10:57:16.024053 (first attempt), 2026-04-23T10:57:33.613081 (second attempt), 2026-04-23T10:57:47.816946 (third attempt)
- **DMS Status**: error
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased (Products→products, ProductId→productid, etc.)

## Statement 2: GetProductByIdAsync
- **DMS Timestamp**: 2026-04-23T10:58:05.087948
- **DMS Status**: error
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased

## Statement 3: InsertProductAsync
- **DMS Timestamp**: 2026-04-23T10:58:19.988848
- **DMS Status**: error
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: SCOPE_IDENTITY()→lastval(), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN, DECLARE removed, schema objects lowercased

## Statement 4: UpdateProductAsync
- **DMS Timestamp**: 2026-04-23T10:58:34.197537
- **DMS Status**: error
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE removed (use subquery), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN, schema objects lowercased, reordered to capture old values before update

## Statement 5: DeleteProductAsync
- **DMS Timestamp**: 2026-04-23T10:58:47.223474
- **DMS Status**: error
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE removed (use subquery), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN, schema objects lowercased, reordered to capture old values before delete

## Statement 6: GetProductsByPriceRangeAsync
- **DMS Timestamp**: 2026-04-23T10:59:05.017734
- **DMS Status**: error
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased

## Statement 7: GetLowStockProductsAsync
- **DMS Timestamp**: 2026-04-23T10:59:19.398351
- **DMS Status**: error
- **Manual Conversion Applied**: Yes
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased, added ::numeric cast for ROUND division
