-- ==================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- ==================================================================================
-- Source Application: AdoCore - Product Management System
-- Database: Microsoft SQL Server
-- Extraction Date: 2024
-- Total Statements: 7
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 38-68
-- Method: GetAllProductsAsync()
-- Description: Complex CTE with window functions (AVG, COUNT OVER), CASE statements,
--              and INNER JOIN to retrieve all products with price analysis
-- Parameters: None
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 85-115
-- Method: GetProductByIdAsync(int productId)
-- Description: CTE with LAG window function to track price and stock changes,
--              with calculated price change percentage
-- Parameters: @ProductId (INT)
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 128-152
-- Method: InsertProductAsync(Product product)
-- Description: Multi-statement transaction with INSERT, SCOPE_IDENTITY(), 
--              logging to ProductHistory, and updating ProductStats
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), 
--             @StockQuantity (INT)
-- T-SQL Features: DECLARE, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE()
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 168-196
-- Method: UpdateProductAsync(Product product)
-- Description: Multi-statement transaction with variable declaration, SELECT into
--              variables, UPDATE, and INSERT for history logging
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), 
--             @Price (DECIMAL), @StockQuantity (INT)
-- T-SQL Features: DECLARE, BEGIN TRANSACTION/COMMIT, SELECT into variables, GETDATE()
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 210-238
-- Method: DeleteProductAsync(int productId)
-- Description: Multi-statement transaction with variable storage, INSERT for logging,
--              DELETE, and UPDATE with CASE expression for statistics
-- Parameters: @ProductId (INT)
-- T-SQL Features: DECLARE, BEGIN TRANSACTION/COMMIT, CASE in UPDATE, GETDATE()
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 244-268
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Description: CTE with RANK() and PERCENT_RANK() window functions to categorize
--              products by price range and percentile
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 284-309
-- Method: GetLowStockProductsAsync(int threshold)
-- Description: CTE with multiple window functions (AVG, MIN, MAX OVER) to analyze
--              stock levels and categorize products by stock status
-- Parameters: @Threshold (INT)
-- ==================================================================================

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

-- ==================================================================================
-- END OF EXTRACTED STATEMENTS
-- ==================================================================================
-- SUMMARY:
-- Total Statements Extracted: 7
-- - 3 SELECT queries with CTEs and window functions (GetAllProductsAsync, 
--   GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- - 1 INSERT transaction with SCOPE_IDENTITY (InsertProductAsync)
-- - 1 UPDATE transaction (UpdateProductAsync)
-- - 1 DELETE transaction (DeleteProductAsync)
--
-- T-SQL Specific Features Identified:
-- - SCOPE_IDENTITY() for identity retrieval
-- - GETDATE() for current timestamp
-- - DECLARE/SET for variable handling
-- - BEGIN TRANSACTION/COMMIT for transaction control
-- - Window functions: AVG() OVER(), COUNT() OVER(), LAG() OVER(), RANK(), 
--   PERCENT_RANK(), MIN() OVER(), MAX() OVER()
-- - CTEs (Common Table Expressions)
-- - CASE expressions
-- ==================================================================================
