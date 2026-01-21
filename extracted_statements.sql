-- ================================================================================
-- EXTRACTED SQL STATEMENTS FROM PRODUCTREPOSITORY.CS
-- Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7 (6 methods + transaction blocks)
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ================================================================================
-- Source File: ProductRepository.cs
-- Source Line: 43-69
-- Method: GetAllProductsAsync()
-- Complexity: High - CTE with window functions (AVG OVER, COUNT OVER), CASE expressions
-- Parameters: None
-- Transaction: No
-- Description: Retrieves all products with price category analysis using window functions
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
-- ================================================================================
-- Source File: ProductRepository.cs
-- Source Line: 80-115
-- Method: GetProductByIdAsync(int productId)
-- Complexity: Medium - CTE with LAG window function for historical analysis
-- Parameters: @ProductId (int)
-- Transaction: No
-- Description: Retrieves product by ID with historical price/stock comparison
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
-- STATEMENT 3: InsertProductAsync
-- ================================================================================
-- Source File: ProductRepository.cs
-- Source Line: 127-165
-- Method: InsertProductAsync(Product product)
-- Complexity: High - Multi-statement transaction with SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Transaction: Yes (BEGIN TRANSACTION...COMMIT)
-- Description: Inserts new product and logs to history, updates statistics
-- T-SQL Specific Features: SCOPE_IDENTITY(), GETDATE(), DECLARE variables, BEGIN TRANSACTION
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
-- STATEMENT 4: UpdateProductAsync
-- ================================================================================
-- Source File: ProductRepository.cs
-- Source Line: 175-215
-- Method: UpdateProductAsync(Product product)
-- Complexity: High - Multi-statement transaction with variable declarations and history logging
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Transaction: Yes (BEGIN TRANSACTION...COMMIT)
-- Description: Updates product, logs changes to history, updates statistics
-- T-SQL Specific Features: DECLARE variables, BEGIN TRANSACTION, GETDATE()
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
-- STATEMENT 5: DeleteProductAsync
-- ================================================================================
-- Source File: ProductRepository.cs
-- Source Line: 225-265
-- Method: DeleteProductAsync(int productId)
-- Complexity: High - Multi-statement transaction with conditional statistics update
-- Parameters: @ProductId (int)
-- Transaction: Yes (BEGIN TRANSACTION...COMMIT)
-- Description: Deletes product, logs to history, updates statistics with conditional logic
-- T-SQL Specific Features: DECLARE variables, BEGIN TRANSACTION, GETDATE(), CASE in UPDATE
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
-- ================================================================================
-- Source File: ProductRepository.cs
-- Source Line: 277-305
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Complexity: Medium - CTE with RANK() and PERCENT_RANK() window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Transaction: No
-- Description: Retrieves products within price range with ranking and percentile analysis
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
-- ================================================================================
-- Source File: ProductRepository.cs
-- Source Line: 317-350
-- Method: GetLowStockProductsAsync(int threshold)
-- Complexity: Medium - CTE with aggregate window functions (AVG, MIN, MAX OVER)
-- Parameters: @Threshold (int)
-- Transaction: No
-- Description: Retrieves low stock products with stock level analysis
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
-- EXTRACTION SUMMARY
-- ================================================================================
-- Total Statements Extracted: 7
-- Simple SELECT queries: 0
-- CTE queries: 7
-- Window function queries: 7
-- Transaction blocks: 3 (INSERT, UPDATE, DELETE)
-- T-SQL specific features identified:
--   - SCOPE_IDENTITY() (1 occurrence)
--   - GETDATE() (7 occurrences)
--   - DECLARE variables (3 transaction blocks)
--   - BEGIN TRANSACTION...COMMIT (3 blocks)
--   - LAG window function (1 occurrence)
--   - AVG/COUNT/MIN/MAX OVER (5 occurrences)
--   - RANK/PERCENT_RANK (1 occurrence each)
--   - CASE expressions (multiple)
-- ================================================================================
