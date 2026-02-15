-- ========================================================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Purpose: Comprehensive catalog of all SQL statements extracted from ProductRepository.cs
-- Date: 2026-02-15
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 6
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync, Lines: 43-66
-- Type: SELECT with CTE, Window Functions, CASE expressions
-- Parameters: None
-- Description: Retrieves all products with price category analysis using window functions to calculate 
--              average price across all products and categorize each product relative to that average.
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync, Lines: 72-95
-- Type: SELECT with CTE, LAG Window Function
-- Parameters: @ProductId (int)
-- Description: Retrieves a specific product by ID with historical price tracking using LAG window function
--              to calculate price change percentage compared to previous price.
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync, Lines: 110-132
-- Type: Transaction Block with INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product within a transaction, logs the insertion to ProductHistory, 
--              updates ProductStats, and returns the new ProductId using SCOPE_IDENTITY().
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync, Lines: 149-177
-- Type: Transaction Block with DECLARE, SELECT, UPDATE, INSERT, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Updates an existing product within a transaction, logs the changes to ProductHistory,
--              and updates ProductStats with new average price calculation.
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync, Lines: 187-215
-- Type: Transaction Block with DECLARE, SELECT, INSERT, DELETE, UPDATE, GETDATE()
-- Parameters: @ProductId (int)
-- Description: Deletes a product within a transaction, logs the deletion to ProductHistory,
--              and updates ProductStats with recalculated average price.
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync, Lines: 223-243
-- Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a specified price range, ranks them by price, and categorizes
--              them into price segments (Budget/Mid-Range/Premium) based on price percentile.
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync, Lines: 251-272
-- Type: SELECT with CTE, Multiple Aggregate Window Functions (AVG, MIN, MAX)
-- Parameters: @Threshold (int)
-- Description: Retrieves products with low stock (below threshold), includes stock statistics using
--              window functions, and categorizes stock status (Critical/Low/Adequate).
-- ========================================================================================================
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

-- ========================================================================================================
-- END OF EXTRACTION CATALOG
-- ========================================================================================================
