-- ================================================================================
-- CONVERTED SQL STATEMENTS CATALOG - UPDATED AFTER FIX
-- Microsoft SQL Server to PostgreSQL Migration
-- ================================================================================
-- This file contains all SQL statements converted from MS SQL Server syntax
-- to PostgreSQL syntax, with fixes applied to statements #3, #4, and #5.
-- 
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- Conversion Date: 2026-02-16
-- Fix Date: 2026-02-16
-- ================================================================================
-- NOTE: All statements were processed through DMS MCP tool first, but the tool
-- encountered metadata model creation failures. Manual conversions were performed
-- following PostgreSQL best practices. 
--
-- CRITICAL FIX APPLIED: Statements #3, #4, and #5 initially contained T-SQL
-- syntax (DECLARE @variable, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY()) which
-- is incompatible with PostgreSQL. These have been refactored to use:
-- - Application-level transaction management (NpgsqlTransaction)
-- - PostgreSQL RETURNING clause (instead of SCOPE_IDENTITY())
-- - Separate SELECT statements (instead of DECLARE @variable)
-- ================================================================================

-- ================================================================================
-- CONVERTED STATEMENT #1: GetAllProductsAsync
-- ================================================================================
-- Original Statement: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Minimal changes needed
-- Changes Made: None required - PostgreSQL-compatible syntax
-- ================================================================================

WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ================================================================================
-- CONVERTED STATEMENT #2: GetProductByIdAsync
-- ================================================================================
-- Original Statement: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Minimal changes needed
-- Changes Made: None required - PostgreSQL-compatible syntax
-- Parameters: @ProductId remains compatible with Npgsql
-- ================================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ================================================================================
-- CONVERTED STATEMENT #3: InsertProductAsync
-- ================================================================================
-- Original Statement: InsertProductAsync - Multi-statement Transaction with INSERT
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE (FIXED)
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH (after fix)
-- Changes Made:
--   1. Removed T-SQL DECLARE @NewProductId INT
--   2. Removed T-SQL BEGIN TRANSACTION/COMMIT from SQL string
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause
--   4. Split into 3 separate SQL statements executed within NpgsqlTransaction:
--      a) INSERT with RETURNING to get new ProductId
--      b) INSERT into ProductHistory
--      c) UPDATE ProductStats
--   5. Transaction management handled at application level (C# code)
-- CRITICAL FIX: Original version had T-SQL syntax that would fail at runtime
-- ================================================================================

-- Statement 3a: Insert product and return ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log the insertion (uses newProductId from previous RETURNING)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ================================================================================
-- CONVERTED STATEMENT #4: UpdateProductAsync
-- ================================================================================
-- Original Statement: UpdateProductAsync - Multi-statement Transaction with UPDATE
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE (FIXED)
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH (after fix)
-- Changes Made:
--   1. Removed T-SQL DECLARE @OldPrice DECIMAL(18,2), @OldStock INT
--   2. Removed T-SQL BEGIN TRANSACTION/COMMIT from SQL string
--   3. Removed T-SQL SET/SELECT @variable syntax
--   4. Split into 4 separate SQL statements executed within NpgsqlTransaction:
--      a) SELECT to get old values
--      b) UPDATE the product
--      c) INSERT into ProductHistory
--      d) UPDATE ProductStats
--   5. Transaction management handled at application level (C# code)
-- CRITICAL FIX: Original version had T-SQL syntax that would fail at runtime
-- ================================================================================

-- Statement 4a: Get old values for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Statement 4c: Log the changes (uses oldPrice/oldStock from previous SELECT)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ================================================================================
-- CONVERTED STATEMENT #5: DeleteProductAsync
-- ================================================================================
-- Original Statement: DeleteProductAsync - Multi-statement Transaction with DELETE
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE (FIXED)
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH (after fix)
-- Changes Made:
--   1. Removed T-SQL DECLARE @OldPrice DECIMAL(18,2), @OldStock INT
--   2. Removed T-SQL BEGIN TRANSACTION/COMMIT from SQL string
--   3. Removed T-SQL SET/SELECT @variable syntax
--   4. Split into 4 separate SQL statements executed within NpgsqlTransaction:
--      a) SELECT to get values before deletion
--      b) INSERT into ProductHistory
--      c) DELETE the product
--      d) UPDATE ProductStats
--   5. Transaction management handled at application level (C# code)
-- CRITICAL FIX: Original version had T-SQL syntax that would fail at runtime
-- ================================================================================

-- Statement 5a: Store product info for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log the deletion (uses oldPrice/oldStock from previous SELECT)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update product statistics
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

-- ================================================================================
-- CONVERTED STATEMENT #6: GetProductsByPriceRangeAsync
-- ================================================================================
-- Original Statement: GetProductsByPriceRangeAsync - SELECT with CTE, RANK and PERCENT_RANK
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Minimal changes needed
-- Changes Made: None required - PostgreSQL-compatible syntax
-- Parameters: @MinPrice, @MaxPrice remain compatible with Npgsql
-- ================================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank;

-- ================================================================================
-- CONVERTED STATEMENT #7: GetLowStockProductsAsync
-- ================================================================================
-- Original Statement: GetLowStockProductsAsync - SELECT with CTE and Multiple Window Functions
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Minimal changes needed
-- Changes Made: None required - PostgreSQL-compatible syntax
-- Parameters: @Threshold remains compatible with Npgsql
-- ================================================================================

WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ================================================================================
-- END OF CONVERTED STATEMENTS
-- ================================================================================

-- SUMMARY OF FIXES APPLIED:
-- 
-- Statement #3 (InsertProductAsync):
--   - Removed: DECLARE @NewProductId INT
--   - Removed: BEGIN TRANSACTION...COMMIT  
--   - Removed: SET @NewProductId = SCOPE_IDENTITY()
--   - Removed: SELECT @NewProductId
--   - Added: RETURNING ProductId clause
--   - Changed: Split into 3 separate statements with application-level transaction
--
-- Statement #4 (UpdateProductAsync):
--   - Removed: DECLARE @OldPrice DECIMAL(18,2), @OldStock INT
--   - Removed: BEGIN TRANSACTION...COMMIT
--   - Removed: SELECT @OldPrice = Price, @OldStock = StockQuantity
--   - Changed: Split into 4 separate statements with application-level transaction
--
-- Statement #5 (DeleteProductAsync):
--   - Removed: DECLARE @OldPrice DECIMAL(18,2), @OldStock INT
--   - Removed: BEGIN TRANSACTION...COMMIT
--   - Removed: SELECT @OldPrice = Price, @OldStock = StockQuantity
--   - Changed: Split into 4 separate statements with application-level transaction
--
-- All transaction management is now handled at the application level using
-- NpgsqlTransaction in the C# code, which is the proper approach for ADO.NET
-- applications with PostgreSQL.
