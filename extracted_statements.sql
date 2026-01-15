-- =====================================================================
-- SQL Statement Extraction Catalog
-- Project: ADO.NET Core Product Management - SQL Server to PostgreSQL Migration
-- Source File: DataAccess/ProductRepository.cs
-- Date Extracted: 2026-01-15
-- Total Statements: 7
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync
-- =====================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync
-- Line Approximate: 37-67
-- Description: Complex CTE query with window functions (AVG, COUNT OVER), 
--              CASE expressions, and computed columns for product statistics
-- SQL Server Features Used: CTE (WITH clause), Window Functions (OVER), 
--              CASE expressions, INNER JOIN
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync
-- =====================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync
-- Line Approximate: 77-107
-- Description: CTE query with LAG window function to retrieve previous values
--              and compute price change percentage with parameterized filter
-- SQL Server Features Used: CTE (WITH clause), LAG window function, 
--              CASE expressions, LEFT JOIN, Parameters (@ProductId)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 3: InsertProductAsync
-- =====================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: InsertProductAsync
-- Line Approximate: 117-143
-- Description: Transaction block with multiple INSERT statements, using 
--              SCOPE_IDENTITY() to capture inserted ID, and GETDATE() for timestamps
-- SQL Server Features Used: BEGIN TRANSACTION/COMMIT, DECLARE variables,
--              SCOPE_IDENTITY(), GETDATE(), INSERT with VALUES, UPDATE with WHERE
--              Parameters (@Name, @Description, @Price, @StockQuantity)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync
-- =====================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: UpdateProductAsync
-- Line Approximate: 153-184
-- Description: Transaction block for updating product with history logging,
--              captures old values before update, updates product, logs changes
-- SQL Server Features Used: BEGIN TRANSACTION/COMMIT, DECLARE variables,
--              SELECT to populate variables, UPDATE with SET and WHERE, 
--              INSERT with VALUES, GETDATE()
--              Parameters (@ProductId, @Name, @Description, @Price, @StockQuantity)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync
-- =====================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: DeleteProductAsync
-- Line Approximate: 194-224
-- Description: Transaction block for deleting product with history logging,
--              captures product info before deletion, logs deletion, deletes product,
--              updates statistics with CASE for handling division by zero
-- SQL Server Features Used: BEGIN TRANSACTION/COMMIT, DECLARE variables,
--              SELECT to populate variables, INSERT with VALUES, DELETE with WHERE,
--              UPDATE with CASE expression, GETDATE()
--              Parameters (@ProductId)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- =====================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Line Approximate: 234-257
-- Description: CTE query with RANK and PERCENT_RANK window functions,
--              filters by price range, categorizes products into price segments
-- SQL Server Features Used: CTE (WITH clause), RANK() OVER, PERCENT_RANK() OVER,
--              CASE expressions, BETWEEN operator, ORDER BY with window function result
--              Parameters (@MinPrice, @MaxPrice)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- =====================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync
-- Line Approximate: 267-292
-- Description: CTE query with multiple aggregate window functions (AVG, MIN, MAX OVER),
--              filters by stock threshold, categorizes stock status with computed fields
-- SQL Server Features Used: CTE (WITH clause), AVG/MIN/MAX window functions (OVER),
--              CASE expressions, WHERE filter with parameter, ROUND function
--              Parameters (@Threshold)
-- =====================================================================

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

-- =====================================================================
-- END OF EXTRACTION CATALOG
-- =====================================================================
-- Summary:
-- - Total Statements Extracted: 7
-- - Statements with CTEs: 5 (Statements 1, 2, 6, 7)
-- - Statements with Transactions: 3 (Statements 3, 4, 5)
-- - Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- - Statements with Parameters: 6 (Statements 2, 3, 4, 5, 6, 7)
-- - SQL Server Specific Functions to Convert:
--   * SCOPE_IDENTITY() -> PostgreSQL RETURNING clause
--   * GETDATE() -> NOW() or CURRENT_TIMESTAMP
--   * BEGIN TRANSACTION -> BEGIN
--   * @param syntax -> $1, $2, etc.
-- =====================================================================
