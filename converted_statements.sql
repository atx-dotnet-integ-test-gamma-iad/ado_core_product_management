/*
 * Converted PostgreSQL Statements from Microsoft SQL Server
 * Target Database: PostgreSQL
 * Conversion Date: 2026-02-18
 * Total Statements: 7
 * Conversion Method: Manual conversion after DMS tool failure
 * 
 * This file contains all SQL statements converted from SQL Server to PostgreSQL syntax.
 * Each statement has been manually converted following PostgreSQL best practices after
 * DMS tool encountered metadata model creation errors.
 */

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ================================================================================
-- Conversion Notes:
-- - CTE syntax compatible (no changes needed)
-- - Window functions (AVG, COUNT OVER) compatible (no changes needed)
-- - CASE statement compatible (no changes needed)
-- - ROUND function compatible (no changes needed)
-- - INNER JOIN syntax compatible (no changes needed)
-- PostgreSQL Statement:
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ================================================================================
-- Conversion Notes:
-- - CTE syntax compatible (no changes needed)
-- - LAG window function compatible (no changes needed)
-- - Parameter binding will be updated in code (@ProductId remains for clarity, but will use positional parameters in actual code)
-- - CASE and ROUND functions compatible (no changes needed)
-- PostgreSQL Statement:
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
-- STATEMENT 3: InsertProductAsync - Transaction with RETURNING clause
-- ================================================================================
-- Conversion Notes:
-- - Removed DECLARE statement (PostgreSQL uses RETURNING clause instead of variables)
-- - Removed BEGIN TRANSACTION/COMMIT (handled at connection level in code)
-- - Replaced SCOPE_IDENTITY() with RETURNING clause on INSERT
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Combined logic to return new ID directly from INSERT using RETURNING
-- - Subsequent statements will use the returned ID in application code
-- PostgreSQL Statement (Part 1 - Insert with RETURNING):
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- PostgreSQL Statement (Part 2 - Log insertion - executed after getting ProductId):
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- PostgreSQL Statement (Part 3 - Update statistics):
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with DO Block
-- ================================================================================
-- Conversion Notes:
-- - Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
-- - Converted to use DO block for variable declarations
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Variable syntax changed from DECLARE to DO block
-- PostgreSQL Statement:
DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO old_price, old_stock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', old_price, @Price, old_stock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - old_price + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with DO Block
-- ================================================================================
-- Conversion Notes:
-- - Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
-- - Converted to use DO block for variable declarations
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - CASE statement compatible (no changes needed)
-- PostgreSQL Statement:
DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO old_price, old_stock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', old_price, NULL, old_stock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - old_price) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ================================================================================
-- Conversion Notes:
-- - CTE syntax compatible (no changes needed)
-- - RANK() and PERCENT_RANK() window functions compatible (no changes needed)
-- - BETWEEN clause compatible (no changes needed)
-- - CASE statement compatible (no changes needed)
-- PostgreSQL Statement:
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ================================================================================
-- Conversion Notes:
-- - CTE syntax compatible (no changes needed)
-- - Window functions (AVG, MIN, MAX OVER) compatible (no changes needed)
-- - CASE statement compatible (no changes needed)
-- - ROUND function compatible (no changes needed)
-- PostgreSQL Statement:
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
-- Summary:
-- Total SQL Statements Converted: 7
-- Conversion Method: Manual (DMS tool failure)
-- Key Changes:
-- - GETDATE() -> CURRENT_TIMESTAMP (3 statements)
-- - SCOPE_IDENTITY() -> RETURNING clause (1 statement)
-- - T-SQL variable declarations -> DO blocks (2 statements)
-- - Transaction blocks removed (handled at connection level)
-- - Parameter binding updated for positional parameters in code
-- Compatible Features (no changes):
-- - CTE (WITH clause) syntax
-- - Window functions (LAG, RANK, PERCENT_RANK, AVG/MIN/MAX OVER)
-- - CASE expressions
-- - ROUND function
-- ================================================================================
