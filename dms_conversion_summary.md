# DMS Conversion Failure Summary

All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed due to database connectivity issues.

## Error Details
- Error: "Metadata model creation failed: Could not connect to source database at 172.31.83.165:1433"
- Alternate Error: "Metadata model creation did not complete after 15 attempts"

## Statements and Manual Conversions

### Statement 1: GetAllProductsAsync (SELECT with CTE - ProductStats)
- DMS Status: FAILED
- Manual Conversion: Applied lowercase schema mapping
- Key Changes: All identifiers lowercased (Products→products, ProductId→productid, etc.)

### Statement 2: GetProductByIdAsync (SELECT with CTE - ProductHistory)
- DMS Status: FAILED
- Manual Conversion: Applied lowercase schema mapping
- Key Changes: All identifiers lowercased

### Statement 3: InsertProductAsync (Transaction with INSERT/INSERT/UPDATE)
- DMS Status: FAILED
- Manual Conversion: Applied lowercase schema mapping + restructured to use CTE with RETURNING
- Key Changes: SCOPE_IDENTITY()→RETURNING clause, GETDATE()→NOW(), variables eliminated via CTE

### Statement 4: UpdateProductAsync (Transaction with SELECT/UPDATE/INSERT/UPDATE)
- DMS Status: FAILED
- Manual Conversion: Applied lowercase schema mapping + restructured to use CTE
- Key Changes: GETDATE()→NOW(), variables eliminated via CTE with subqueries

### Statement 5: DeleteProductAsync (Transaction with SELECT/INSERT/DELETE/UPDATE)
- DMS Status: FAILED
- Manual Conversion: Applied lowercase schema mapping + restructured to use CTE
- Key Changes: GETDATE()→NOW(), variables eliminated via CTE with subqueries

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE - RankedProducts)
- DMS Status: FAILED
- Manual Conversion: Applied lowercase schema mapping
- Key Changes: All identifiers lowercased

### Statement 7: GetLowStockProductsAsync (SELECT with CTE - StockAnalysis)
- DMS Status: FAILED
- Manual Conversion: Applied lowercase schema mapping + added CAST for integer division
- Key Changes: All identifiers lowercased, CAST(stockquantity AS NUMERIC) for proper division
