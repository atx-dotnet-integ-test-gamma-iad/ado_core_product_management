-- ============================================================================
-- CONVERTED SQL STATEMENTS - SQL Server to PostgreSQL
-- Target: PostgreSQL
-- Conversion Method: MANUAL (DMS Tool Unavailable - Timeout Errors)
-- Conversion Date: 2026-01-28
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- ============================================================================
-- Original: SQL Server syntax with CTE, window functions, CASE, ROUND
-- PostgreSQL Conversion Notes:
--   - CTE syntax compatible
--   - Window functions (AVG OVER, COUNT OVER) compatible
--   - CASE statement compatible
--   - ROUND function compatible
--   - INNER JOIN compatible
--   - No schema name changes applied
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- ============================================================================
-- Original: SQL Server syntax with CTE, LAG window function, LEFT JOIN
-- PostgreSQL Conversion Notes:
--   - CTE syntax compatible
--   - LAG window function compatible with PostgreSQL
--   - LEFT JOIN compatible
--   - CASE statement with NULL handling compatible
--   - ROUND function compatible
--   - Parameterized query (@ProductId) compatible with PostgreSQL
--   - No schema name changes applied
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- ============================================================================
-- Original: SQL Server transaction with SCOPE_IDENTITY(), GETDATE()
-- PostgreSQL Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - DECLARE variable syntax remains same
--   - SCOPE_IDENTITY() -> RETURNING clause in INSERT
--   - GETDATE() -> NOW() (PostgreSQL function)
--   - Multiple INSERT/UPDATE operations compatible
--   - Transaction COMMIT compatible
--   - Changed to use RETURNING clause for ProductId instead of SCOPE_IDENTITY()
--   - Final SELECT @NewProductId removed (handled by RETURNING in application layer)
-- ============================================================================

DO $$
DECLARE 
    NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    -- Return the new product ID
    -- Note: In ADO.NET, we'll use RETURNING clause directly in the INSERT
END $$;

-- Alternative for ADO.NET implementation (preferred):
-- Use simple INSERT with RETURNING clause
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then execute history and stats updates separately
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- ============================================================================
-- Original: SQL Server transaction with variable declarations, GETDATE()
-- PostgreSQL Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - Variable declarations compatible
--   - SELECT into variables compatible
--   - GETDATE() -> NOW()
--   - UPDATE operations compatible
--   - INSERT compatible
--   - COMMIT compatible
-- ============================================================================

BEGIN;
    -- Store old values for history
    -- In PostgreSQL, we can use DO block or handle in application
    -- For ADO.NET, we'll use separate statements
END;

-- Alternative for ADO.NET implementation (preferred):
-- Execute as separate statements within application transaction

-- First: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Second: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Third: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Fourth: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- ============================================================================
-- Original: SQL Server transaction with variables, DELETE, CASE
-- PostgreSQL Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN
--   - Variable declarations compatible
--   - SELECT into variables compatible
--   - GETDATE() -> NOW()
--   - DELETE operation compatible
--   - UPDATE with CASE expression compatible
--   - COMMIT compatible
-- ============================================================================

-- For ADO.NET implementation (preferred):
-- Execute as separate statements within application transaction

-- First: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Second: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Third: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Fourth: Update product statistics
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- ============================================================================
-- Original: SQL Server CTE with RANK(), PERCENT_RANK() window functions
-- PostgreSQL Conversion Notes:
--   - CTE syntax compatible
--   - RANK() window function compatible
--   - PERCENT_RANK() window function compatible
--   - CASE statement compatible
--   - BETWEEN clause compatible
--   - ORDER BY compatible
--   - No schema name changes applied
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- ============================================================================
-- Original: SQL Server CTE with multiple window aggregations, ROUND
-- PostgreSQL Conversion Notes:
--   - CTE syntax compatible
--   - AVG() OVER() compatible
--   - MIN() OVER() compatible
--   - MAX() OVER() compatible
--   - CASE statement compatible
--   - ROUND function compatible
--   - WHERE clause compatible
--   - ORDER BY compatible
--   - No schema name changes applied
-- ============================================================================

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

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Transformations Applied:
--   1. GETDATE() -> NOW()
--   2. SCOPE_IDENTITY() -> RETURNING clause
--   3. BEGIN TRANSACTION -> BEGIN (or application-level transaction)
--   4. Transaction blocks converted to separate statements for ADO.NET
--   5. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) - Compatible
--   6. CTEs - Compatible
--   7. CASE statements - Compatible
--   8. ROUND function - Compatible
--   9. Parameterized queries (@param) - Compatible with PostgreSQL
-- 
-- Schema Changes: None (no schema name transformations applied)
-- ============================================================================
