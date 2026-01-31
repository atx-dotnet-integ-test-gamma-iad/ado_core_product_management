-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Extraction Date: 2025-01-31
-- Source: Microsoft SQL Server T-SQL
-- Target: PostgreSQL
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: 39-68
-- Construction Method: Inline const string
-- Parameters: None
-- Purpose: Retrieve all products with price analysis using CTE and window functions
-- Complexity: High (CTE + Window Functions + CASE expressions)
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
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 83-109
-- Construction Method: Inline const string
-- Parameters: @ProductId (int)
-- Purpose: Retrieve product by ID with historical price comparison using LAG window function
-- Complexity: High (CTE + LAG Window Function + CASE expression)
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
-- File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 125-149
-- Construction Method: Inline const string
-- Parameters: @Name (string), @Description (string nullable), @Price (decimal), @StockQuantity (int)
-- Purpose: Insert new product with transaction - includes history logging and statistics update
-- Complexity: Very High (Multi-statement transaction + SCOPE_IDENTITY + GETDATE)
-- T-SQL Specific Features: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE(), SET
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
-- File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 163-193
-- Construction Method: Inline const string
-- Parameters: @ProductId (int), @Name (string), @Description (string nullable), @Price (decimal), @StockQuantity (int)
-- Purpose: Update product with transaction - includes history logging and statistics update
-- Complexity: Very High (Multi-statement transaction + Variable declarations + GETDATE)
-- T-SQL Specific Features: BEGIN TRANSACTION, DECLARE, GETDATE(), SET via SELECT
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
-- File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 207-236
-- Construction Method: Inline const string
-- Parameters: @ProductId (int)
-- Purpose: Delete product with transaction - includes history logging and statistics update
-- Complexity: Very High (Multi-statement transaction + Variable declarations + GETDATE + CASE in UPDATE)
-- T-SQL Specific Features: BEGIN TRANSACTION, DECLARE, GETDATE(), CASE expression
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
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 251-274
-- Construction Method: Inline const string
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Purpose: Retrieve products within price range with ranking using CTE and window functions
-- Complexity: High (CTE + RANK + PERCENT_RANK Window Functions + CASE expression)
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
-- File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 289-314
-- Construction Method: Inline const string
-- Parameters: @Threshold (int)
-- Purpose: Retrieve low stock products with stock analysis using CTE and window functions
-- Complexity: High (CTE + Multiple Window Functions (AVG, MIN, MAX) + CASE expression)
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
-- Total Statements Extracted: 7
-- Note: The plan mentions 6 statements, but 7 distinct SQL statements were found:
--   1. GetAllProductsAsync - CTE with window functions
--   2. GetProductByIdAsync - CTE with LAG window function
--   3. InsertProductAsync - Multi-statement transaction with SCOPE_IDENTITY
--   4. UpdateProductAsync - Multi-statement transaction
--   5. DeleteProductAsync - Multi-statement transaction
--   6. GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK window functions
--   7. GetLowStockProductsAsync - CTE with multiple window functions
--
-- T-SQL Specific Features to Convert:
-- - GETDATE() → PostgreSQL equivalent (CURRENT_TIMESTAMP or NOW())
-- - SCOPE_IDENTITY() → PostgreSQL RETURNING clause
-- - BEGIN TRANSACTION/COMMIT → PostgreSQL BEGIN/COMMIT
-- - DECLARE/SET variables → PostgreSQL DO block or CTEs
-- - Square brackets [dbo].[Table] → PostgreSQL identifiers
-- - Window functions syntax verification
-- - DECIMAL(18,2) → PostgreSQL NUMERIC or DECIMAL
-- ============================================================================
