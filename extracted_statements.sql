-- ================================================================================
-- EXTRACTED SQL STATEMENTS CATALOG FOR DMS CONVERSION
-- Source File: ProductRepository.cs
-- Migration: Microsoft SQL Server to PostgreSQL
-- Total Statements: 7
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Range: 40-67
-- Type: SELECT query with CTE and window functions
-- Parameters: None
-- Description: Complex CTE with AVG OVER() and COUNT OVER() window functions,
--              CASE expressions, ROUND function, and ORDER BY with CASE
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
-- STATEMENT 2: GetProductByIdAsync
-- Source File: ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line Range: 82-112
-- Type: SELECT query with CTE and LAG window function
-- Parameters: @ProductId (int)
-- Description: CTE with LAG() OVER window function for historical price tracking,
--              CASE expression with ROUND for percentage calculation
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
-- STATEMENT 3: InsertProductAsync - Transaction Block
-- Source File: ProductRepository.cs
-- Method: InsertProductAsync
-- Line Range: 127-152
-- Type: Transaction with INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement transaction with DECLARE, INSERT, SCOPE_IDENTITY(),
--              ProductHistory logging, ProductStats update, GETDATE() functions
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
-- STATEMENT 4: UpdateProductAsync - Transaction Block
-- Source File: ProductRepository.cs
-- Method: UpdateProductAsync
-- Line Range: 168-198
-- Type: Transaction with DECLARE, SELECT, UPDATE, INSERT, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement transaction storing old values, updating product,
--              logging to ProductHistory, updating ProductStats with GETDATE()
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
-- STATEMENT 5: DeleteProductAsync - Transaction Block
-- Source File: ProductRepository.cs
-- Method: DeleteProductAsync
-- Line Range: 213-242
-- Type: Transaction with DECLARE, SELECT, INSERT, DELETE, UPDATE, GETDATE()
-- Parameters: @ProductId (int)
-- Description: Multi-statement transaction storing product info, logging deletion,
--              deleting product, updating statistics with conditional CASE
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line Range: 257-279
-- Type: SELECT query with CTE, RANK() and PERCENT_RANK() window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: CTE with RANK() OVER and PERCENT_RANK() OVER window functions,
--              CASE expression for price segmentation based on percentile
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line Range: 294-319
-- Type: SELECT query with CTE and multiple window functions
-- Parameters: @Threshold (int)
-- Description: CTE with AVG/MIN/MAX OVER() window functions, CASE expression,
--              ROUND function for stock analysis, WHERE filter on threshold
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
-- Total Statements: 7
-- SELECT Queries: 4 (Statements 1, 2, 6, 7)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- 
-- SQL Server Features Used:
-- - Common Table Expressions (CTE) with WITH clause
-- - Window Functions: AVG OVER(), COUNT OVER(), LAG OVER(), RANK OVER(), PERCENT_RANK OVER(), MIN OVER(), MAX OVER()
-- - CASE expressions
-- - ROUND function
-- - SCOPE_IDENTITY() function
-- - GETDATE() function
-- - BEGIN TRANSACTION / COMMIT
-- - DECLARE variable statements
-- - SET variable assignments
-- - Parameterized queries with @ prefix
-- ================================================================================
