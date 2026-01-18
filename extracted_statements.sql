-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- This file catalogs all SQL statements extracted from the application code
-- for processing through the DMS MCP tool and SQL Equivalency validation.
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions and CASE
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: 38-66
-- Description: Complex CTE using window functions (AVG, COUNT OVER), CASE expressions,
--              and ORDER BY with conditional logic
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function and LEFT JOIN
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 82-111
-- Description: CTE using LAG window function to track historical price/stock changes,
--              with LEFT JOIN and conditional CASE for percentage calculations
-- Parameters: @ProductId
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
-- STATEMENT 3: InsertProductAsync - Transaction Block with INSERT, SCOPE_IDENTITY, UPDATE
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 125-148
-- Description: Transaction block performing INSERT with SCOPE_IDENTITY() to retrieve
--              new ID, logging to ProductHistory, and updating ProductStats table
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE()
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
-- STATEMENT 4: UpdateProductAsync - Transaction Block with DECLARE, SELECT, UPDATE, INSERT
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 166-192
-- Description: Transaction block with variable declarations to store old values,
--              UPDATE statement with GETDATE(), and history logging
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- SQL Server Specific Functions: GETDATE()
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
-- STATEMENT 5: DeleteProductAsync - Transaction Block with DECLARE, SELECT, INSERT, DELETE, UPDATE
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 206-237
-- Description: Transaction block with variable storage, history logging, DELETE statement,
--              and statistics update with complex CASE expression
-- Parameters: @ProductId
-- SQL Server Specific Functions: GETDATE()
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 251-277
-- Description: CTE using RANK() and PERCENT_RANK() window functions with price segmentation
--              logic based on percentile ranges
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregation Window Functions and CASE
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 291-322
-- Description: CTE using AVG, MIN, MAX window functions with conditional CASE logic
--              for stock status categorization and percentage calculations
-- Parameters: @Threshold
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
-- END OF EXTRACTED SQL STATEMENTS
-- Total Statements: 7
-- ============================================================================
-- SUMMARY:
-- - 2 SELECT queries with CTEs and window functions (Statements 1, 2)
-- - 3 Transaction blocks with INSERT/UPDATE/DELETE operations (Statements 3, 4, 5)
-- - 2 SELECT queries with ranking/aggregation window functions (Statements 6, 7)
--
-- SQL Server Specific Features Identified:
-- - SCOPE_IDENTITY() - needs conversion to RETURNING clause in PostgreSQL
-- - GETDATE() - needs conversion to CURRENT_TIMESTAMP or NOW()
-- - BEGIN TRANSACTION/COMMIT syntax - compatible but may need adjustment
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) - compatible
-- - CTEs (WITH clauses) - compatible
-- - CASE expressions - compatible
-- ============================================================================
