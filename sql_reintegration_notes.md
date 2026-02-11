# SQL Statement Re-integration Notes for ProductRepository.cs

## Overview
This document describes the SQL statement conversions applied to ProductRepository.cs and explains the phased approach for transaction-based statements.

## Completed Conversions (Step 4)

### Statement 1: GetAllProductsAsync
**Status**: ✅ COMPLETED
**Changes**:
- Updated ROUND calculation to use `::numeric` cast for PostgreSQL precision
- Changed: `ROUND((p.Price / ps.AvgPrice) * 100, 2)`
- To: `ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2)`
- All other syntax (CTE, window functions, CASE) is PostgreSQL compatible

###Statement 2: GetProductByIdAsync
**Status**: ✅ COMPLETED
**Changes**:
- Updated ROUND calculation to use `::numeric` cast for PostgreSQL precision
- Changed: `ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)`
- To: `ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice)::numeric * 100, 2)`
- LAG window function and CTE are PostgreSQL compatible

### Statement 3: InsertProductAsync
**Status**: ⚠️ PARTIAL - Requires Step 6 (ADO.NET class changes)
**Current State**: SQL Server T-SQL syntax still in place
**Required Changes**:
1. Remove `DECLARE @NewProductId INT;` (T-SQL variable declaration)
2. Remove `BEGIN TRANSACTION;` and `COMMIT;` (handled at C# level with NpgsqlTransaction)
3. Replace `SCOPE_IDENTITY()` with `RETURNING ProductId`
4. Replace `GETDATE()` with `NOW()`
5. Restructure to execute as 3 separate SQL commands within a C# transaction

**PostgreSQL Target Structure**:
```sql
-- Command 1: Insert with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Command 2: Log history (using returned ID from Command 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;
```

**Implementation Plan**: Will be completed in Step 6 when Npgsql classes are implemented

### Statement 4: UpdateProductAsync
**Status**: ⚠️ PARTIAL - Requires Step 6 (ADO.NET class changes)
**Current State**: SQL Server T-SQL syntax still in place
**Required Changes**:
1. Remove `DECLARE @OldPrice DECIMAL(18,2);` and `DECLARE @OldStock INT;`
2. Remove `BEGIN TRANSACTION;` and `COMMIT;` (handled at C# level)
3. Replace `GETDATE()` with `NOW()`
4. Restructure to execute as 4 separate SQL commands within a C# transaction

**PostgreSQL Target Structure**:
```sql
-- Command 1: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Command 3: Log changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Command 4: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;
```

**Implementation Plan**: Will be completed in Step 6 when Npgsql classes are implemented

### Statement 5: DeleteProductAsync
**Status**: ⚠️ PARTIAL - Requires Step 6 (ADO.NET class changes)
**Current State**: SQL Server T-SQL syntax still in place
**Required Changes**:
1. Remove `DECLARE @OldPrice DECIMAL(18,2);` and `DECLARE @OldStock INT;`
2. Remove `BEGIN TRANSACTION;` and `COMMIT;` (handled at C# level)
3. Replace `GETDATE()` with `NOW()`
4. Restructure to execute as 4 separate SQL commands within a C# transaction

**PostgreSQL Target Structure**:
```sql
-- Command 1: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Log deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Command 3: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Command 4: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;
```

**Implementation Plan**: Will be completed in Step 6 when Npgsql classes are implemented

### Statement 6: GetProductsByPriceRangeAsync
**Status**: ✅ COMPLETED
**Changes**: None required
**Notes**: CTE, RANK(), PERCENT_RANK() window functions, and all other syntax is fully PostgreSQL compatible

### Statement 7: GetLowStockProductsAsync
**Status**: ✅ COMPLETED
**Changes**:
- Updated ROUND calculation to use `::numeric` cast for PostgreSQL precision
- Changed: `ROUND((StockQuantity / AvgStock) * 100, 2)`
- To: `ROUND((StockQuantity::numeric / AvgStock) * 100, 2)`
- All other syntax (CTE, window functions, CASE) is PostgreSQL compatible

## Summary

### Statements Ready for PostgreSQL (Step 4 Complete):
- Statement 1: GetAllProductsAsync ✅
- Statement 2: GetProductByIdAsync ✅
- Statement 6: GetProductsByPriceRangeAsync ✅
- Statement 7: GetLowStockProductsAsync ✅

### Statements Awaiting Step 6 (Npgsql Implementation):
- Statement 3: InsertProductAsync ⚠️
- Statement 4: UpdateProductAsync ⚠️
- Statement 5: DeleteProductAsync ⚠️

### Reason for Deferred Changes:
Statements 3, 4, and 5 contain T-SQL transaction control statements (DECLARE, BEGIN TRANSACTION, COMMIT) and SQL Server-specific functions (SCOPE_IDENTITY(), GETDATE()) that require restructuring into multiple separate SQL commands executed within a C# transaction context. This restructuring cannot be completed until:
1. The Npgsql package is added (Step 5)
2. SqlClient classes are replaced with Npgsql classes (Step 6)
3. C# transaction handling code is updated to use NpgsqlTransaction

The converted SQL statements have been documented in converted_statements.sql and will be applied during Step 6 when the C# code structure can properly support the PostgreSQL transaction model.

## Next Steps (Step 6)
When implementing Step 6:
1. Replace `using Microsoft.Data.SqlClient;` with `using Npgsql;`
2. Replace all SqlConnection → NpgsqlConnection
3. Replace all SqlCommand → NpgsqlCommand  
4. Replace all SqlDataReader → NpgsqlDataReader
5. Implement the transaction-based statements (3, 4, 5) using the PostgreSQL structures documented above
6. Use NpgsqlTransaction for explicit transaction control
7. Execute multi-statement transactions as separate commands within the transaction scope

All conversion patterns are documented in converted_statements.sql for reference during Step 6 implementation.
