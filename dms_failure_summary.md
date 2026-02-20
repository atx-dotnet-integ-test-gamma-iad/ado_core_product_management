# DMS Tool Failure Summary

## Overview
All 7 SQL statements from ProductRepository.cs were submitted to the DMS MCP tool for conversion.
All 7 failed with the same error, requiring manual conversion.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo

## Statements and Manual Conversions

### Statement 1: GetAllProductsAsync
- **DMS Attempts**: 2 (initial + retry with extended polling)
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Applied lowercase schema objects. CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND, ORDER BY CASE - all PostgreSQL compatible.

### Statement 2: GetProductByIdAsync
- **DMS Attempts**: 1
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Applied lowercase schema objects. CTE with LAG window function, LEFT JOIN, CASE with ROUND - all PostgreSQL compatible.

### Statement 3: InsertProductAsync
- **DMS Attempts**: 1
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Converted DECLARE/SET/SCOPE_IDENTITY() pattern to writable CTE with RETURNING clause. GETDATE() -> NOW(). Applied lowercase schema objects.

### Statement 4: UpdateProductAsync
- **DMS Attempts**: 1
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Converted DECLARE variable pattern to writable CTE with old_values subquery. GETDATE() -> NOW(). Applied lowercase schema objects.

### Statement 5: DeleteProductAsync
- **DMS Attempts**: 1
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Converted DECLARE variable pattern to writable CTE with old_values subquery. GETDATE() -> NOW(). Applied lowercase schema objects.

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempts**: 1
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Applied lowercase schema objects. CTE with RANK/PERCENT_RANK, BETWEEN, CASE - all PostgreSQL compatible.

### Statement 7: GetLowStockProductsAsync
- **DMS Attempts**: 1
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Applied lowercase schema objects. Added CAST for integer division in ROUND. CTE with AVG/MIN/MAX over all rows, CASE - all PostgreSQL compatible.
