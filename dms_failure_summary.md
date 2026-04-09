# DMS Conversion Failure Summary

## DMS Tool Status
The DMS statement_conversion_tool consistently failed for all 7 SQL statements with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## DMS Schema Mapping Tool Status
The DMS schema_mapping_tool worked successfully and provided schema mappings:
- Products → productmanagement_dbo.products
- ProductHistory → productmanagement_dbo.producthistory
- ProductStats → productmanagement_dbo.productstats

## Statements Attempted (All 7 Failed)

### Statement 1: GetAllProductsAsync
- **DMS Timestamp**: 2026-04-09T03:50:38
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema mapping per DMS schema_mapping_tool output

### Statement 2: GetProductByIdAsync
- **DMS Timestamp**: 2026-04-09T03:52:25
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema mapping per DMS schema_mapping_tool output

### Statement 3: InsertProductAsync
- **DMS Timestamp**: 2026-04-09T03:52:41
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Decomposed T-SQL transaction block. SCOPE_IDENTITY() → RETURNING. GETDATE() → NOW(). Applied lowercase schema mapping.

### Statement 4: UpdateProductAsync
- **DMS Timestamp**: 2026-04-09T03:52:58
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Decomposed T-SQL transaction block. DECLARE/@variable → C# variables. GETDATE() → NOW(). Applied lowercase schema mapping.

### Statement 5: DeleteProductAsync
- **DMS Timestamp**: 2026-04-09T03:53:13
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Decomposed T-SQL transaction block. DECLARE/@variable → C# variables. GETDATE() → NOW(). Applied lowercase schema mapping.

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Timestamp**: 2026-04-09T03:53:30
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema mapping per DMS schema_mapping_tool output

### Statement 7: GetLowStockProductsAsync
- **DMS Timestamp**: 2026-04-09T03:53:46
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema mapping per DMS schema_mapping_tool output. Added CAST for integer division.
