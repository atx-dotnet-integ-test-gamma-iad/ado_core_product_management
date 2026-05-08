# DMS Conversion Failure Summary Log
## Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4

### DMS Tool Error (Consistent across all 7 statements)
**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
**Timestamp Range**: 2026-05-08T10:01:59 to 2026-05-08T10:02:58
**Retry Attempts**: Multiple attempts with different poll configurations (default and 30 attempts/15s intervals)

### Conversion Approach
Since DMS failed for ALL statements, manual conversion was applied following the transformation rules:
- All schema object names converted to lowercase for PostgreSQL compatibility
- `SCOPE_IDENTITY()` replaced with `RETURNING productid` clause
- `GETDATE()` replaced with `NOW()`
- `DECLARE @variable` patterns replaced with application-level variables
- SQL Server transaction blocks refactored to use PostgreSQL ADO.NET transaction management via `NpgsqlTransaction`
- Integer division issue in Statement 7 fixed with `::numeric` cast

### Statements Processed

| # | Method | DMS Status | Manual Conversion Applied |
|---|--------|------------|--------------------------|
| 1 | GetAllProductsAsync | FAILED | Lowercase schema objects |
| 2 | GetProductByIdAsync | FAILED | Lowercase schema objects |
| 3 | InsertProductAsync | FAILED | Lowercase + RETURNING + NOW() + app-level transactions |
| 4 | UpdateProductAsync | FAILED | Lowercase + NOW() + app-level variables + transactions |
| 5 | DeleteProductAsync | FAILED | Lowercase + NOW() + app-level variables + transactions |
| 6 | GetProductsByPriceRangeAsync | FAILED | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | FAILED | Lowercase schema objects + ::numeric cast |

### SQL Equivalency Tool Results
**Tool Error**: All 7 statements returned ERROR with `'uniqueID'` error from the sql-equivalency___validate_sql_equivalence tool.
**Status**: All statements marked as ERROR per transformation instructions (tool failure does not substitute agent judgment).
