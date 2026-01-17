-- ==========================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Migration from SQL Server to PostgreSQL
-- ==========================================
-- This file contains all SQL statements extracted from the ADO.NET codebase
-- for systematic processing through the DMS MCP tool.
--
-- Total Statements: 7
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- ==========================================

-- ==========================================
-- STATEMENT 1: GetAllProductsAsync
-- ==========================================
-- Statement ID: 1
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 38-68
-- Method Name: GetAllProductsAsync()
-- Statement Type: SELECT (CTE with Window Functions)
-- Parameters: None
-- Description: Complex CTE query with AVG OVER, COUNT OVER window functions, 
--              CASE expressions, and ROUND function for price analysis
-- ==========================================

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

-- ==========================================
-- STATEMENT 2: GetProductByIdAsync
-- ==========================================
-- Statement ID: 2
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 78-103
-- Method Name: GetProductByIdAsync(int productId)
-- Statement Type: SELECT (CTE with LAG Window Function)
-- Parameters: @ProductId (INT)
-- Description: CTE with LAG window function to track previous price and stock,
--              includes parameterized query for product filtering
-- ==========================================

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

-- ==========================================
-- STATEMENT 3: InsertProductAsync
-- ==========================================
-- Statement ID: 3
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 117-141
-- Method Name: InsertProductAsync(Product product)
-- Statement Type: TRANSACTION (INSERT, Variable Declaration, SCOPE_IDENTITY)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Multi-statement transaction with SCOPE_IDENTITY(), INSERT statements,
--              and GETDATE() function. Includes product insertion, history logging, and statistics update
-- ==========================================

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

-- ==========================================
-- STATEMENT 4: UpdateProductAsync
-- ==========================================
-- Statement ID: 4
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 153-185
-- Method Name: UpdateProductAsync(Product product)
-- Statement Type: TRANSACTION (Variable Declaration, SELECT, UPDATE)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), 
--             @Price (DECIMAL), @StockQuantity (INT)
-- Description: Multi-statement transaction with variable declarations, UPDATE statements,
--              history logging, and GETDATE() function
-- ==========================================

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

-- ==========================================
-- STATEMENT 5: DeleteProductAsync
-- ==========================================
-- Statement ID: 5
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 193-225
-- Method Name: DeleteProductAsync(int productId)
-- Statement Type: TRANSACTION (Variable Declaration, SELECT, INSERT, DELETE, UPDATE)
-- Parameters: @ProductId (INT)
-- Description: Multi-statement transaction with DELETE and statistics update,
--              includes variable declarations and GETDATE() function
-- ==========================================

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

-- ==========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ==========================================
-- Statement ID: 6
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 232-256
-- Method Name: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT (CTE with RANK and PERCENT_RANK Window Functions)
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: CTE with RANK() and PERCENT_RANK() window functions for price analysis
--              within a specified range
-- ==========================================

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

-- ==========================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ==========================================
-- Statement ID: 7
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 263-289
-- Method Name: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT (CTE with Multiple Window Functions)
-- Parameters: @Threshold (INT)
-- Description: CTE with multiple window functions (AVG, MIN, MAX OVER) for stock analysis,
--              includes ROUND function and complex CASE expressions
-- ==========================================

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

-- ==========================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- ==========================================
-- Summary:
-- Total Statements Extracted: 7
-- SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- TRANSACTION Statements: 3 (Statements 3, 4, 5)
-- Window Functions: 6 statements use window functions
-- CTEs (Common Table Expressions): 5 statements use CTEs
-- Parameterized Queries: 6 statements use parameters
-- 
-- Key SQL Server Features to Convert:
-- - SCOPE_IDENTITY() → PostgreSQL RETURNING clause
-- - GETDATE() → CURRENT_TIMESTAMP or NOW()
-- - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
-- - Variable declarations (DECLARE @var) → PostgreSQL variable syntax
-- - Window functions (should be compatible but syntax may vary)
-- - ROUND function (should be compatible)
-- ==========================================
