-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- This file contains all SQL statements extracted from the codebase
-- for conversion to PostgreSQL syntax using AWS DMS MCP tool
-- Total Statements: 6
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Numbers: ~42-67
-- Description: Complex CTE query with window functions (AVG OVER, COUNT OVER)
--              and CASE statements for product statistics and categorization
-- Parameters: None
-- Return Type: List<Product>
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Numbers: ~79-108
-- Description: CTE query with LAG window function to track historical price
--              and stock changes
-- Parameters: @ProductId (int)
-- Return Type: Product (single object)
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
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Numbers: ~118-145
-- Description: Multi-statement transaction block with INSERT operations,
--              SCOPE_IDENTITY() for retrieving new ID, and GETDATE() calls.
--              Includes ProductHistory logging and ProductStats updates
-- Parameters: @Name (string), @Description (string/null), 
--             @Price (decimal), @StockQuantity (int)
-- Return Type: int (new ProductId)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Numbers: ~153-186
-- Description: Multi-statement transaction block with variable declarations,
--              SELECT to capture old values, UPDATE operation, history logging,
--              and statistics updates. Uses GETDATE() for timestamps
-- Parameters: @ProductId (int), @Name (string), @Description (string/null),
--             @Price (decimal), @StockQuantity (int)
-- Return Type: void (ExecuteNonQueryAsync)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Numbers: ~194-230
-- Description: Multi-statement transaction block with variable declarations,
--              SELECT to capture values before deletion, history logging,
--              DELETE operation, and statistics updates with CASE statement.
--              Uses GETDATE() for timestamps
-- Parameters: @ProductId (int)
-- Return Type: void (ExecuteNonQueryAsync)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Numbers: ~238-263
-- Description: CTE query with RANK() and PERCENT_RANK() window functions
--              for price-based product segmentation and ranking
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Return Type: List<Product>
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Numbers: ~271-298
-- Description: CTE query with multiple aggregate window functions (AVG, MIN, MAX)
--              for stock analysis and categorization
-- Parameters: @Threshold (int)
-- Return Type: List<Product>
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
-- END OF EXTRACTED STATEMENTS
-- ============================================================================
-- Summary:
-- Total Statements Extracted: 7 (Note: Plan mentions 6, but there are actually 7 methods)
-- - 3 SELECT queries with CTEs and window functions
-- - 3 Transaction blocks (INSERT, UPDATE, DELETE)
-- - 1 SELECT query with CTEs and window functions for stock analysis
--
-- SQL Server Specific Features Identified:
-- - SCOPE_IDENTITY() - needs conversion to PostgreSQL RETURNING clause
-- - GETDATE() - needs conversion to NOW() or CURRENT_TIMESTAMP
-- - Window functions (AVG OVER, COUNT OVER, LAG OVER, RANK, PERCENT_RANK)
-- - Common Table Expressions (CTEs) with WITH clause
-- - Transaction blocks (BEGIN TRANSACTION, COMMIT)
-- - CASE statements
-- - Parameter syntax (@ParamName)
-- ============================================================================
