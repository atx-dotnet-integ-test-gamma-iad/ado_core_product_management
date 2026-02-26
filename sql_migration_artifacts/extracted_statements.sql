-- ========================================================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ProductRepository.cs
-- Total Statements: 7
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Lines: 40-68
-- Method: GetAllProductsAsync()
-- Type: SELECT with CTE and Window Functions
-- Complexity: High (CTE, window functions AVG OVER(), COUNT OVER(), CASE expressions)
-- Description: Retrieves all products with price category analysis using window functions
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
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Lines: 81-109
-- Method: GetProductByIdAsync(int productId)
-- Type: SELECT with CTE and LAG Window Function
-- Complexity: High (CTE, LAG window function, LEFT JOIN, calculated fields)
-- Parameters: @ProductId (int)
-- Description: Retrieves product by ID with price history comparison using LAG function
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
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Lines: 120-147
-- Method: InsertProductAsync(Product product)
-- Type: INSERT with Transaction Block
-- Complexity: High (BEGIN/COMMIT transaction, SCOPE_IDENTITY(), GETDATE(), multi-table operations)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Inserts new product within transaction, logs history, and updates statistics
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
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
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Lines: 163-194
-- Method: UpdateProductAsync(Product product)
-- Type: UPDATE with Transaction Block
-- Complexity: High (BEGIN/COMMIT transaction, GETDATE(), multi-table operations with variables)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Updates product within transaction, captures old values, logs changes, and updates stats
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT, variable declarations
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
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Lines: 205-237
-- Method: DeleteProductAsync(int productId)
-- Type: DELETE with Transaction Block
-- Complexity: High (BEGIN/COMMIT transaction, GETDATE(), multi-table operations)
-- Parameters: @ProductId
-- Description: Deletes product within transaction after logging history and updating statistics
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT, variable declarations
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
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Lines: 248-272
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: SELECT with CTE and Ranking Window Functions
-- Complexity: High (CTE, RANK(), PERCENT_RANK() window functions, CASE expressions)
-- Parameters: @MinPrice, @MaxPrice
-- Description: Retrieves products in price range with rank and percentile calculations
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
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Lines: 285-309
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: SELECT with CTE and Aggregate Window Functions
-- Complexity: High (CTE, AVG/MIN/MAX window functions, CASE expressions, ROUND function)
-- Parameters: @Threshold
-- Description: Retrieves low stock products with stock analysis using window functions
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
