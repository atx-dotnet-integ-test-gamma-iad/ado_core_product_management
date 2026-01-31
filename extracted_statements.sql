-- ==================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- ==================================================================================
-- Source File: ProductRepository.cs
-- Extraction Date: 2025-01-31
-- Total SQL Statements: 7
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1 of 7
-- Method: GetAllProductsAsync()
-- Lines: 41-69
-- Type: SELECT with CTE and Window Functions
-- Complexity: Medium
-- Description: Retrieves all products with price category analysis using window functions
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
-- STATEMENT 2 of 7
-- Method: GetProductByIdAsync(int productId)
-- Lines: 81-110
-- Type: SELECT with CTE, LAG Window Function, and LEFT JOIN
-- Complexity: Medium
-- Description: Retrieves single product by ID with price change history using LAG
-- Parameters: @ProductId
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
-- STATEMENT 3 of 7
-- Method: InsertProductAsync(Product product)
-- Lines: 126-148
-- Type: TRANSACTION BLOCK (INSERT with SCOPE_IDENTITY, INSERT, UPDATE, SELECT)
-- Complexity: High
-- Description: Inserts new product, logs to history, updates statistics, returns new ID
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Tables: Products, ProductHistory, ProductStats
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
-- STATEMENT 4 of 7
-- Method: UpdateProductAsync(Product product)
-- Lines: 163-193
-- Type: TRANSACTION BLOCK (DECLARE, SELECT, UPDATE, INSERT)
-- Complexity: High
-- Description: Updates product, logs changes to history, updates statistics
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Tables: Products, ProductHistory, ProductStats
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
-- STATEMENT 5 of 7
-- Method: DeleteProductAsync(int productId)
-- Lines: 208-236
-- Type: TRANSACTION BLOCK (DECLARE, SELECT, INSERT, DELETE, UPDATE)
-- Complexity: High
-- Description: Deletes product, logs deletion to history, updates statistics
-- Parameters: @ProductId
-- Tables: Products, ProductHistory, ProductStats
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
-- STATEMENT 6 of 7
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: 251-275
-- Type: SELECT with CTE, RANK, and PERCENT_RANK Window Functions
-- Complexity: Medium
-- Description: Retrieves products within price range with ranking and segmentation
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7 of 7
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: 290-318
-- Type: SELECT with CTE and Multiple Aggregate Window Functions
-- Complexity: Medium
-- Description: Retrieves low stock products with stock analysis using window functions
-- Parameters: @Threshold
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
-- EXTRACTION SUMMARY
-- ==================================================================================
-- Total SQL Statements Extracted: 7
-- SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- TRANSACTION BLOCKS: 3 (Statements 3, 4, 5)
-- Statements with CTEs: 5 (Statements 1, 2, 6, 7 use CTEs; 3, 4, 5 are transactions)
-- Statements with Window Functions: 4 (Statements 1, 2, 6, 7)
-- Parameterized Statements: 6 (All except Statement 1)
-- 
-- Tables Referenced:
-- - Products (all statements)
-- - ProductHistory (statements 3, 4, 5)
-- - ProductStats (statements 3, 4, 5)
--
-- SQL Server Specific Features Identified:
-- - SCOPE_IDENTITY() (Statement 3)
-- - GETDATE() (Statements 3, 4, 5)
-- - BEGIN TRANSACTION/COMMIT (Statements 3, 4, 5)
-- - LAG() window function (Statement 2)
-- - RANK(), PERCENT_RANK() window functions (Statement 6)
-- - AVG(), MIN(), MAX() window functions (Statement 7)
-- - ROUND() function (Statements 1, 2, 7)
-- - CASE expressions (Statements 1, 2, 5, 6, 7)
-- ==================================================================================
