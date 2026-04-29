# DMS Conversion Failure Log
## Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

### Summary
- Total statements attempted: 7
- Successful DMS conversions: 0
- Failed DMS conversions: 7
- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

All 7 statements failed with the same DMS infrastructure error. Manual conversion was applied with lowercase schema object names per transformation rules (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

---

### Statement 1: GetAllProductsAsync
- **DMS Attempt Timestamp**: 2026-04-29T18:00:18
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema object names, ROUND compatible with PostgreSQL

### Statement 2: GetProductByIdAsync
- **DMS Attempt Timestamp**: 2026-04-29T18:00:33
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema object names, LAG window functions compatible

### Statement 3: InsertProductAsync
- **DMS Attempt Timestamp**: 2026-04-29T18:01:05
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - SCOPE_IDENTITY() -> lastval()/RETURNING, GETDATE() -> NOW(), DECLARE removed, lowercase schema

### Statement 4: UpdateProductAsync
- **DMS Attempt Timestamp**: 2026-04-29T18:01:21
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DECLARE/@var removed, GETDATE() -> NOW(), CTE-based approach, lowercase schema

### Statement 5: DeleteProductAsync
- **DMS Attempt Timestamp**: 2026-04-29T18:01:40
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DECLARE/@var removed, GETDATE() -> NOW(), CTE-based approach, lowercase schema

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt Timestamp**: 2026-04-29T18:01:56
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema object names, RANK/PERCENT_RANK compatible

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt Timestamp**: 2026-04-29T18:02:11
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema object names, integer division cast for ROUND
