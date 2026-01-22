-- ==================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADOCORE APPLICATION
-- Source: ProductRepository.cs
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- Total Statements: 7
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 42-68
-- Method: GetAllProductsAsync()
-- Description: Retrieves all products with CTE, window functions (AVG, COUNT OVER), 
--              joins, and complex CASE expressions for price categorization
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
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 83-108
-- Method: GetProductByIdAsync(int productId)
-- Description: Retrieves single product by ID with CTE, LAG window function for 
--              historical price and stock comparison
-- Parameters: @ProductId (int)
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
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 123-148
-- Method: InsertProductAsync(Product product)
-- Description: Transaction block for inserting new product with SCOPE_IDENTITY() 
--              to retrieve new ID, GETDATE() for timestamps, and updates to 
--              ProductHistory and ProductStats tables
-- Parameters: @Name (string), @Description (string), @Price (decimal), 
--             @StockQuantity (int)
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
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 160-194
-- Method: UpdateProductAsync(Product product)
-- Description: Transaction block with variable declarations (@OldPrice, @OldStock),
--              SELECT to retrieve old values, UPDATE product, INSERT history log,
--              and UPDATE statistics with GETDATE() for timestamps
-- Parameters: @ProductId (int), @Name (string), @Description (string), 
--             @Price (decimal), @StockQuantity (int)
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
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 205-238
-- Method: DeleteProductAsync(int productId)
-- Description: Transaction block with variable declarations, SELECT old values,
--              INSERT history log, DELETE product, UPDATE statistics with CASE
--              expression for average calculation and GETDATE() for timestamps
-- Parameters: @ProductId (int)
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
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 249-274
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Description: CTE with window functions RANK() and PERCENT_RANK() OVER for price
--              ranking and percentile calculation with CASE for price segmentation
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
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
-- Source File: /sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 288-316
-- Method: GetLowStockProductsAsync(int threshold)
-- Description: CTE with aggregation window functions (AVG, MIN, MAX) OVER for stock
--              analysis with CASE for stock status categorization and ROUND function
-- Parameters: @Threshold (int)
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
-- END OF EXTRACTED SQL STATEMENTS
-- Total Count: 7 statements
-- Transaction Blocks: 3 (Insert, Update, Delete)
-- CTE Queries: 5 (GetAll, GetById, GetByPriceRange, GetLowStock)
-- Window Functions Used: AVG OVER, COUNT OVER, LAG OVER, RANK OVER, PERCENT_RANK OVER,
--                        MIN OVER, MAX OVER
-- SQL Server Specific Syntax: SCOPE_IDENTITY(), GETDATE(), @variable declarations,
--                              BEGIN TRANSACTION/COMMIT, parameter style @ParamName
-- ==================================================================================
