-- ================================================================================
-- SQL SERVER TO POSTGRESQL MIGRATION - EXTRACTED SQL STATEMENTS CATALOG
-- ================================================================================
-- This file documents all SQL statements extracted from the codebase before
-- conversion to PostgreSQL. Each statement is documented with its source location,
-- method name, line numbers, and complete SQL text.
--
-- Total Statements: 7
-- Source File: DataAccess/ProductRepository.cs
-- ================================================================================

-- ================================================================================
-- STATEMENT 1 of 7
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Range: Approximately lines 37-70
-- Description: CTE with window functions (AVG, COUNT OVER), CASE statements, 
--              INNER JOIN, and ORDER BY for product statistics
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
-- STATEMENT 2 of 7
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Range: Approximately lines 81-114
-- Description: CTE with LAG window function for product history, LEFT JOIN,
--              parameterized query with @ProductId
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
-- STATEMENT 3 of 7
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Range: Approximately lines 125-155
-- Description: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(),
--              UPDATE statements, and history logging
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ================================================================================

DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- ================================================================================
-- STATEMENT 4 of 7
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Range: Approximately lines 166-205
-- Description: Transaction block with DECLARE variables, SELECT into variables,
--              UPDATE with GETDATE(), INSERT for history logging
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ================================================================================

BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- ================================================================================
-- STATEMENT 5 of 7
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Range: Approximately lines 216-254
-- Description: Transaction block with DELETE, DECLARE variables, INSERT for
--              history logging, UPDATE with CASE statement
-- Parameters: @ProductId
-- ================================================================================

BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- ================================================================================
-- STATEMENT 6 of 7
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Range: Approximately lines 265-291
-- Description: CTE with RANK() and PERCENT_RANK() window functions,
--              parameterized query with BETWEEN clause
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7 of 7
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Range: Approximately lines 302-333
-- Description: CTE with AVG, MIN, MAX window functions for stock analysis,
--              CASE statement for stock status categorization
-- Parameters: @Threshold
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
-- END OF EXTRACTED STATEMENTS CATALOG
-- ================================================================================
-- Summary:
-- - Total statements extracted: 7
-- - Statements with CTEs: 5 (Statements 1, 2, 6, 7 with window functions)
-- - Statements with transactions: 3 (Statements 3, 4, 5)
-- - Statements with window functions: 5 (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX)
-- - Statements with GETDATE(): 3 (Statements 3, 4, 5)
-- - Statements with SCOPE_IDENTITY(): 1 (Statement 3)
-- ================================================================================
