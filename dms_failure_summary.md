# DMS Conversion Failure Summary
## Date: 2026-04-30

## Overview
All 7 SQL statements from ProductRepository.cs were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion.
All 7 attempts failed with the same error. Manual conversion was applied with lowercase schema object names per transformation rules.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Server**: 172.31.83.165

## Statement Details

### Statement 1: GetAllProductsAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased (Products→products, ProductId→productid, etc.)

### Statement 2: GetProductByIdAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased, LAG window functions preserved (compatible)

### Statement 3: InsertProductAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: SCOPE_IDENTITY()→RETURNING clause, GETDATE()→NOW(), DECLARE/@variable→restructured as separate statements within C# managed transaction, table/column names lowercased

### Statement 4: UpdateProductAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: GETDATE()→NOW(), DECLARE/@variable→restructured as separate statements within C# managed transaction, table/column names lowercased

### Statement 5: DeleteProductAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: GETDATE()→NOW(), DECLARE/@variable→restructured as separate statements, CASE preserved (compatible), table/column names lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased, RANK/PERCENT_RANK preserved (compatible)

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased, AVG/MIN/MAX window functions preserved (compatible), added CAST to numeric for ROUND compatibility
