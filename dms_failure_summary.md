# DMS Conversion Failure Summary

## Overview
All 15 individual SQL statements from ProductRepository.cs were submitted to the DMS MCP tool for conversion. All 15 failed with the same infrastructure error. Manual conversion was applied with lowercase schema object names per the transformation definition guidelines.

**Note**: The original code contained 7 logical method-level SQL groups. Three of these (InsertProductAsync, UpdateProductAsync, DeleteProductAsync) were monolithic transaction blocks that were decomposed into individual sub-statements during migration. This results in 15 individual SQL statement constants in the final PostgreSQL code:
- 4 standalone queries (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
- 3 sub-statements in InsertProductAsync (insertProductSql, insertHistorySql, updateStatsSql)
- 4 sub-statements in UpdateProductAsync (selectOldValuesSql, updateProductSql, insertHistorySql, updateStatsSql)
- 4 sub-statements in DeleteProductAsync (selectOldValuesSql, insertHistorySql, deleteProductSql, updateStatsSql)

## DMS Error (Consistent Across All 15 Statements)
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4`
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1

## Conversion Method Applied
`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## Key Conversion Rules Applied
1. All schema object names converted to lowercase (Products → products, ProductId → productid, etc.)
2. `SCOPE_IDENTITY()` → `RETURNING productid` clause
3. `GETDATE()` → `NOW()`
4. `DECLARE @var TYPE; ... SET @var = ...` → C# application-level variable management with separate SQL statements
5. `SELECT @var = col` → `SELECT col` with C# reader pattern
6. `BEGIN TRANSACTION; ... COMMIT;` → C# `BeginTransactionAsync()` / `CommitAsync()` pattern
7. Integer division in ROUND() → Added `CAST(... AS DECIMAL)` for proper decimal division in PostgreSQL
8. CTE, Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER), CASE, ROUND, JOIN → Largely compatible, only schema name casing changed

## Statement Conversion Details

### Statement 1: GetAllProductsAsync - sql (Standalone)
- **Type**: CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN, ORDER BY
- **Changes**: Lowercase schema objects only. SQL syntax fully compatible.

### Statement 2: GetProductByIdAsync - sql (Standalone)
- **Type**: CTE with LAG window function, parameterized @ProductId, CASE, ROUND, LEFT JOIN
- **Changes**: Lowercase schema objects only. SQL syntax fully compatible.

### Statement 3: InsertProductAsync - insertProductSql (Transaction sub-statement 1/3)
- **Type**: INSERT with SCOPE_IDENTITY() → RETURNING
- **Changes**: 
  - Replaced `INSERT ... ; SELECT SCOPE_IDENTITY()` with `INSERT ... RETURNING productid`
  - Lowercase schema objects

### Statement 4: InsertProductAsync - insertHistorySql (Transaction sub-statement 2/3)
- **Type**: INSERT into ProductHistory with GETDATE()
- **Changes**:
  - Replaced `GETDATE()` with `NOW()`
  - @NewProductId managed as C# variable @ProductId
  - Lowercase schema objects

### Statement 5: InsertProductAsync - updateStatsSql (Transaction sub-statement 3/3)
- **Type**: UPDATE ProductStats with GETDATE()
- **Changes**:
  - Replaced `GETDATE()` with `NOW()`
  - Lowercase schema objects

### Statement 6: UpdateProductAsync - selectOldValuesSql (Transaction sub-statement 1/4)
- **Type**: SELECT into SQL variables
- **Changes**:
  - Replaced `SELECT @OldPrice = Price, @OldStock = StockQuantity` with `SELECT price, stockquantity` (C# reader pattern)
  - Lowercase schema objects

### Statement 7: UpdateProductAsync - updateProductSql (Transaction sub-statement 2/4)
- **Type**: UPDATE Products with GETDATE()
- **Changes**:
  - Replaced `GETDATE()` with `NOW()`
  - Lowercase schema objects

### Statement 8: UpdateProductAsync - insertHistorySql (Transaction sub-statement 3/4)
- **Type**: INSERT into ProductHistory with UPDATE action and GETDATE()
- **Changes**:
  - Replaced `GETDATE()` with `NOW()`
  - Lowercase schema objects

### Statement 9: UpdateProductAsync - updateStatsSql (Transaction sub-statement 4/4)
- **Type**: UPDATE ProductStats recalculate average with GETDATE()
- **Changes**:
  - Replaced `GETDATE()` with `NOW()`
  - Lowercase schema objects

### Statement 10: DeleteProductAsync - selectOldValuesSql (Transaction sub-statement 1/4)
- **Type**: SELECT into SQL variables
- **Changes**:
  - Replaced `SELECT @OldPrice = Price, @OldStock = StockQuantity` with `SELECT price, stockquantity` (C# reader pattern)
  - Lowercase schema objects

### Statement 11: DeleteProductAsync - insertHistorySql (Transaction sub-statement 2/4)
- **Type**: INSERT into ProductHistory with DELETE action and GETDATE()
- **Changes**:
  - Replaced `GETDATE()` with `NOW()`
  - Lowercase schema objects

### Statement 12: DeleteProductAsync - deleteProductSql (Transaction sub-statement 3/4)
- **Type**: DELETE FROM Products
- **Changes**:
  - Lowercase schema objects only

### Statement 13: DeleteProductAsync - updateStatsSql (Transaction sub-statement 4/4)
- **Type**: UPDATE ProductStats with CASE expression and GETDATE()
- **Changes**:
  - Replaced `GETDATE()` with `NOW()`
  - Lowercase schema objects

### Statement 14: GetProductsByPriceRangeAsync - sql (Standalone)
- **Type**: CTE with RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **Changes**: Lowercase schema objects only. SQL syntax fully compatible.

### Statement 15: GetLowStockProductsAsync - sql (Standalone)
- **Type**: CTE with AVG/MIN/MAX OVER(), CASE, ROUND, parameterized @Threshold
- **Changes**: 
  - Lowercase schema objects
  - Added `CAST(stockquantity AS DECIMAL)` for proper decimal division in ROUND()

## SQL Equivalency Validation
All 15 individual statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 15 returned ERROR status with error: `'uniqueID'`.
This is a tool-level infrastructure error, not a statement-level equivalency issue.
