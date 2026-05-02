# DMS Conversion Failure Summary
## Date: 2026-05-02
## Project: AdoCore SQL Server to PostgreSQL Migration

### DMS Error (Consistent across all 7 statements)
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project ARN**: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
- **Schema**: dbo
- **Region**: us-east-1

### Statement Conversion Details

| # | Method | Statement | DMS Output | Manual Conversion Notes |
|---|--------|-----------|------------|------------------------|
| 1 | GetAllProductsAsync | CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN | Error: Metadata model creation failed | Lowercase schema objects; SQL syntax compatible with PostgreSQL |
| 2 | GetProductByIdAsync | CTE with LAG window function, CASE, ROUND, LEFT JOIN | Error: Metadata model creation failed | Lowercase schema objects; SQL syntax compatible with PostgreSQL |
| 3 | InsertProductAsync | Transaction with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE() | Error: Metadata model creation failed | Restructured to use CTE with INSERT...RETURNING; GETDATE()->NOW(); removed DECLARE @var |
| 4 | UpdateProductAsync | Transaction with DECLARE, SELECT into vars, UPDATE, INSERT, GETDATE() | Error: Metadata model creation failed | Restructured to use CTE pattern; GETDATE()->NOW(); removed DECLARE @var |
| 5 | DeleteProductAsync | Transaction with DECLARE, SELECT into vars, INSERT, DELETE, UPDATE with CASE, GETDATE() | Error: Metadata model creation failed | Restructured to use CTE pattern; GETDATE()->NOW(); removed DECLARE @var |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE | Error: Metadata model creation failed | Lowercase schema objects; SQL syntax compatible with PostgreSQL |
| 7 | GetLowStockProductsAsync | CTE with AVG/MIN/MAX window functions, CASE, ROUND | Error: Metadata model creation failed | Lowercase schema objects; integer division fix with ::NUMERIC cast |

### Key PostgreSQL Conversion Rules Applied
1. **SCOPE_IDENTITY()** → `INSERT...RETURNING productid` via CTE
2. **GETDATE()** → `NOW()`
3. **DECLARE @variable** → Restructured to use CTEs (PostgreSQL doesn't support DECLARE in plain SQL from ADO.NET)
4. **BEGIN TRANSACTION/COMMIT** → Managed by application-level transaction or single CTE statement
5. **Schema object names** → All converted to lowercase for PostgreSQL compatibility
6. **Integer division** → Added `::NUMERIC` cast where needed for ROUND operations
7. **All column/table aliases** → Converted to lowercase
