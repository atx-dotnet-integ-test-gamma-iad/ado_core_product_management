-- ================================================================================
-- SQL STATEMENTS EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ================================================================================
-- This file contains all SQL statements extracted from the .NET ADO application
-- for processing through the DMS MCP tool for PostgreSQL conversion.
-- 
-- Total Statements: 7
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-02-16
-- ================================================================================

-- ================================================================================
-- STATEMENT #1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ================================================================================
-- Location: DataAccess/ProductRepository.cs, Line 38-67
-- Method: GetAllProductsAsync()
-- Description: Retrieves all products with price categorization using CTE and window functions
-- Features: CTE (ProductStats), AVG() OVER(), COUNT() OVER(), CASE expressions, INNER JOIN
-- Parameters: None
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
-- STATEMENT #2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ================================================================================
-- Location: DataAccess/ProductRepository.cs, Line 83-111
-- Method: GetProductByIdAsync(int productId)
-- Description: Retrieves a single product with historical price comparison using LAG window function
-- Features: CTE (ProductHistory), LAG() OVER(), parameterized query, CASE expression, LEFT JOIN
-- Parameters: @ProductId (int)
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
-- STATEMENT #3: InsertProductAsync - Multi-statement Transaction with INSERT
-- ================================================================================
-- Location: DataAccess/ProductRepository.cs, Line 127-152
-- Method: InsertProductAsync(Product product)
-- Description: Inserts a new product with transaction handling, history logging, and statistics update
-- Features: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, COMMIT, SELECT
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Returns: New product ID
-- T-SQL Specific: SCOPE_IDENTITY(), GETDATE(), DECLARE variables, transaction syntax
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
-- STATEMENT #4: UpdateProductAsync - Multi-statement Transaction with UPDATE
-- ================================================================================
-- Location: DataAccess/ProductRepository.cs, Line 168-201
-- Method: UpdateProductAsync(Product product)
-- Description: Updates a product with transaction handling, history logging, and statistics update
-- Features: DECLARE, BEGIN TRANSACTION, SELECT into variables, UPDATE, INSERT, GETDATE(), COMMIT
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- T-SQL Specific: DECLARE variables, GETDATE(), transaction syntax
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
-- STATEMENT #5: DeleteProductAsync - Multi-statement Transaction with DELETE
-- ================================================================================
-- Location: DataAccess/ProductRepository.cs, Line 217-249
-- Method: DeleteProductAsync(int productId)
-- Description: Deletes a product with transaction handling, history logging, and statistics update
-- Features: DECLARE, BEGIN TRANSACTION, SELECT into variables, INSERT, DELETE, UPDATE with CASE, GETDATE(), COMMIT
-- Parameters: @ProductId (int)
-- T-SQL Specific: DECLARE variables, GETDATE(), transaction syntax, CASE in UPDATE
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
-- STATEMENT #6: GetProductsByPriceRangeAsync - SELECT with CTE, RANK and PERCENT_RANK
-- ================================================================================
-- Location: DataAccess/ProductRepository.cs, Line 265-285
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Description: Retrieves products within a price range with ranking and percentile calculations
-- Features: CTE (RankedProducts), RANK() OVER(), PERCENT_RANK() OVER(), CASE expression, BETWEEN
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Window Functions: RANK and PERCENT_RANK for price distribution analysis
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
-- STATEMENT #7: GetLowStockProductsAsync - SELECT with CTE and Multiple Window Functions
-- ================================================================================
-- Location: DataAccess/ProductRepository.cs, Line 301-328
-- Method: GetLowStockProductsAsync(int threshold)
-- Description: Analyzes low stock products with statistical comparisons using window functions
-- Features: CTE (StockAnalysis), AVG/MIN/MAX with OVER(), CASE expression, WHERE filtering
-- Parameters: @Threshold (int)
-- Window Functions: AVG, MIN, MAX for stock quantity analysis
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
-- END OF EXTRACTION CATALOG
-- ================================================================================
-- Summary:
-- - Total Statements Extracted: 7
-- - SELECT Statements: 4 (Statements #1, #2, #6, #7)
-- - INSERT Statements: 1 (Statement #3 - includes INSERT in transaction)
-- - UPDATE Statements: 1 (Statement #4 - includes UPDATE in transaction)
-- - DELETE Statements: 1 (Statement #5 - includes DELETE in transaction)
-- - Statements with CTEs: 5 (Statements #1, #2, #6, #7)
-- - Statements with Window Functions: 4 (Statements #1, #2, #6, #7)
-- - Statements with Transactions: 3 (Statements #3, #4, #5)
-- - Parameterized Statements: 5 (Statements #2, #3, #4, #5, #6, #7)
-- 
-- Ready for DMS MCP Tool Processing
-- ================================================================================
