-- =============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Source: ProductRepository.cs
-- Purpose: Catalog of all SQL statements for DMS conversion to PostgreSQL
-- Total Statements: 6
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- =============================================================================
-- Source Method: GetAllProductsAsync()
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Lines: 40-70
-- Complexity: HIGH - CTE with window functions (AVG OVER, COUNT OVER), CASE expressions, JOIN
-- Parameters: None
-- Description: Retrieves all products with price category analysis using window functions
-- Notes: Uses CTE named 'ProductStats', window functions for aggregation, CASE for categorization
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- =============================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Lines: 87-118
-- Complexity: HIGH - CTE with LAG window function, LEFT JOIN, CASE expressions
-- Parameters: @ProductId (int)
-- Description: Retrieves product by ID with historical price change analysis
-- Notes: Uses LAG window function to get previous values, calculates percentage change
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 3: InsertProductAsync
-- =============================================================================
-- Source Method: InsertProductAsync(Product product)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Lines: 134-157
-- Complexity: HIGH - Transaction with DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Description: Inserts new product with transaction, logs history, updates statistics
-- Notes: Uses SCOPE_IDENTITY() to get new ID, involves ProductHistory and ProductStats tables
-- Critical: SCOPE_IDENTITY() must be converted to PostgreSQL RETURNING or currval()
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync
-- =============================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Lines: 176-206
-- Complexity: HIGH - Transaction with DECLARE, variable assignment via SELECT
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Description: Updates product with transaction, logs history, updates statistics
-- Notes: Uses DECLARE for variables, SELECT INTO pattern, GETDATE() for timestamps
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync
-- =============================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Lines: 223-253
-- Complexity: HIGH - Transaction with DECLARE, conditional CASE in UPDATE
-- Parameters: @ProductId (int)
-- Description: Deletes product with transaction, logs history, updates statistics
-- Notes: Uses CASE expression to handle division by zero in statistics update
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- =============================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Lines: 270-290
-- Complexity: HIGH - CTE with RANK and PERCENT_RANK window functions, CASE expressions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within price range with ranking and percentile analysis
-- Notes: Uses RANK() and PERCENT_RANK() window functions for price analysis
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- =============================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Lines: 307-330
-- Complexity: HIGH - CTE with multiple window functions (AVG, MIN, MAX OVER), CASE expressions
-- Parameters: @Threshold (int)
-- Description: Retrieves low stock products with stock analysis using window functions
-- Notes: Uses multiple window functions (AVG, MIN, MAX), CASE for stock status categorization
-- =============================================================================

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

-- =============================================================================
-- EXTRACTION SUMMARY
-- =============================================================================
-- Total Statements Extracted: 7
-- Statements with CTEs: 4 (GetAllProducts, GetProductById, GetProductsByPriceRange, GetLowStockProducts)
-- Statements with Transactions: 3 (InsertProduct, UpdateProduct, DeleteProduct)
-- Statements with Window Functions: 4 (GetAllProducts, GetProductById, GetProductsByPriceRange, GetLowStockProducts)
-- Statements with SCOPE_IDENTITY(): 1 (InsertProduct)
-- Statements with GETDATE(): 3 (InsertProduct, UpdateProduct, DeleteProduct)
-- Statements with DECLARE: 3 (InsertProduct, UpdateProduct, DeleteProduct)
-- 
-- Special Conversion Requirements:
-- 1. SCOPE_IDENTITY() → PostgreSQL RETURNING clause or currval()
-- 2. GETDATE() → NOW() or CURRENT_TIMESTAMP
-- 3. BEGIN TRANSACTION/COMMIT → PostgreSQL transaction syntax
-- 4. @parameter → $1, $2, etc. (positional parameters) or keep named parameters
-- 5. DECIMAL(18,2) → NUMERIC(18,2) in PostgreSQL
-- 6. Window functions syntax verification (mostly compatible)
-- 7. CTE syntax verification (mostly compatible)
-- =============================================================================
