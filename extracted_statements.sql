-- ============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- ============================================================================
-- Purpose: Comprehensive catalog of all SQL statements extracted from the 
--          ADO.NET application for Microsoft SQL Server to PostgreSQL migration
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: 2026-02-11
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Location: DataAccess/ProductRepository.cs, Line ~39
-- Method: GetAllProductsAsync()
-- Type: SELECT query with CTE and window functions
-- Parameterized: No
-- Transaction: No
-- Dynamic Construction: No
-- Description: Retrieves all products with price statistics using CTE,
--              window functions (AVG OVER, COUNT OVER), CASE expressions,
--              and complex ordering logic
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
-- Location: DataAccess/ProductRepository.cs, Line ~78
-- Method: GetProductByIdAsync(int productId)
-- Type: SELECT query with CTE and LAG window function
-- Parameterized: Yes (@ProductId)
-- Transaction: No
-- Dynamic Construction: No
-- Description: Retrieves single product with historical price comparison
--              using CTE, LAG window function, LEFT JOIN, and price change
--              percentage calculation
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
-- Location: DataAccess/ProductRepository.cs, Line ~118
-- Method: InsertProductAsync(Product product)
-- Type: Multi-statement transaction with INSERT operations
-- Parameterized: Yes (@Name, @Description, @Price, @StockQuantity)
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Dynamic Construction: No
-- Description: Inserts new product with transaction control, uses
--              SCOPE_IDENTITY() for ID retrieval, GETDATE() for timestamps,
--              logs to ProductHistory, updates ProductStats
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
-- Location: DataAccess/ProductRepository.cs, Line ~148
-- Method: UpdateProductAsync(Product product)
-- Type: Multi-statement transaction with UPDATE and INSERT operations
-- Parameterized: Yes (@ProductId, @Name, @Description, @Price, @StockQuantity)
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Dynamic Construction: No
-- Description: Updates product with transaction control, captures old values
--              with SELECT INTO, uses GETDATE() for timestamps, logs changes
--              to ProductHistory, updates ProductStats
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
-- Location: DataAccess/ProductRepository.cs, Line ~195
-- Method: DeleteProductAsync(int productId)
-- Type: Multi-statement transaction with DELETE and UPDATE operations
-- Parameterized: Yes (@ProductId)
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Dynamic Construction: No
-- Description: Deletes product with transaction control, captures values
--              before deletion, logs to ProductHistory, updates ProductStats
--              with CASE logic for average calculation
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
-- Location: DataAccess/ProductRepository.cs, Line ~237
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: SELECT query with CTE and ranking window functions
-- Parameterized: Yes (@MinPrice, @MaxPrice)
-- Transaction: No
-- Dynamic Construction: No
-- Description: Retrieves products within price range using CTE with RANK()
--              and PERCENT_RANK() window functions, BETWEEN clause, and
--              price segment categorization
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
-- Location: DataAccess/ProductRepository.cs, Line ~266
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: SELECT query with CTE and multiple aggregate window functions
-- Parameterized: Yes (@Threshold)
-- Transaction: No
-- Dynamic Construction: No
-- Description: Retrieves low stock products using CTE with multiple window
--              functions (AVG, MIN, MAX), conditional filtering, stock status
--              categorization, and percentage calculation
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
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total SQL Statements Extracted: 7
-- 
-- Statement Types:
--   - SELECT queries with CTEs: 4 (Statements 1, 2, 6, 7)
--   - Multi-statement transactions: 3 (Statements 3, 4, 5)
--
-- Parameterized Statements: 6 (Statements 2, 3, 4, 5, 6, 7)
-- Non-parameterized Statements: 1 (Statement 1)
--
-- Statements in Transactions: 3 (Statements 3, 4, 5)
-- Statements without Transactions: 4 (Statements 1, 2, 6, 7)
--
-- SQL Server Specific Features to Convert:
--   - @parameter syntax → PostgreSQL $n or :named syntax
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → NOW() or CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION / COMMIT → BEGIN / COMMIT
--   - DECLARE variable syntax → PostgreSQL variable declaration
--   - Window functions (compatible but verify syntax)
--   - CTE syntax (compatible but verify)
--   - ROUND function (verify precision handling)
--
-- Next Steps:
--   1. Pass each statement through DMS MCP conversion tool
--   2. Validate converted statements with SQL Equivalency tool
--   3. Re-integrate converted statements back into ProductRepository.cs
-- ============================================================================
