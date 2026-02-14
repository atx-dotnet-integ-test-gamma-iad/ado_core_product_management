-- =====================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Purpose: PostgreSQL-compatible versions of all SQL Server statements
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- DMS Tool Status: Failed for all statements (metadata model creation error)
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Source Method: GetAllProductsAsync()
-- Conversion: Already PostgreSQL-compatible
-- Changes: None - CTEs and window functions work identically in PostgreSQL
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
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion: Already PostgreSQL-compatible
-- Changes: None - LAG window function works identically in PostgreSQL
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
-- STATEMENT 3A: InsertProductAsync - Main Insert (PostgreSQL)
-- Source Method: InsertProductAsync(Product product)
-- Conversion: Use RETURNING clause instead of SCOPE_IDENTITY()
-- Changes: 
-- - Removed DECLARE @NewProductId
-- - Removed BEGIN TRANSACTION/COMMIT (handled in C# code)
-- - Replaced SCOPE_IDENTITY() with RETURNING ProductId
-- - GETDATE() → NOW()
-- Note: This is split into multiple statements, transaction managed in C#
-- =====================================================================

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- =====================================================================
-- STATEMENT 3B: InsertProductAsync - History Log (PostgreSQL)
-- To be executed after main insert with ProductId from RETURNING
-- =====================================================================

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- =====================================================================
-- STATEMENT 3C: InsertProductAsync - Stats Update (PostgreSQL)
-- To be executed after history log
-- =====================================================================

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- =====================================================================
-- STATEMENT 4A: UpdateProductAsync - Get Old Values (PostgreSQL)
-- Source Method: UpdateProductAsync(Product product)
-- Conversion: Split transaction into separate statements
-- Changes:
-- - Removed DECLARE, use separate SELECT
-- - Removed BEGIN TRANSACTION/COMMIT (handled in C# code)
-- - GETDATE() → NOW()
-- =====================================================================

SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- =====================================================================
-- STATEMENT 4B: UpdateProductAsync - Update Product (PostgreSQL)
-- To be executed after retrieving old values
-- =====================================================================

UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- =====================================================================
-- STATEMENT 4C: UpdateProductAsync - History Log (PostgreSQL)
-- To be executed after product update
-- =====================================================================

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- =====================================================================
-- STATEMENT 4D: UpdateProductAsync - Stats Update (PostgreSQL)
-- To be executed after history log
-- =====================================================================

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- =====================================================================
-- STATEMENT 5A: DeleteProductAsync - Get Old Values (PostgreSQL)
-- Source Method: DeleteProductAsync(int productId)
-- Conversion: Split transaction into separate statements
-- Changes:
-- - Removed DECLARE, use separate SELECT
-- - Removed BEGIN TRANSACTION/COMMIT (handled in C# code)
-- - GETDATE() → NOW()
-- =====================================================================

SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- =====================================================================
-- STATEMENT 5B: DeleteProductAsync - History Log (PostgreSQL)
-- To be executed after retrieving old values, before deletion
-- =====================================================================

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- =====================================================================
-- STATEMENT 5C: DeleteProductAsync - Delete Product (PostgreSQL)
-- To be executed after history log
-- =====================================================================

DELETE FROM Products 
WHERE ProductId = @ProductId;

-- =====================================================================
-- STATEMENT 5D: DeleteProductAsync - Stats Update (PostgreSQL)
-- To be executed after deletion
-- =====================================================================

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: Already PostgreSQL-compatible
-- Changes: None - RANK and PERCENT_RANK window functions work identically
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion: Already PostgreSQL-compatible
-- Changes: None - Window functions work identically in PostgreSQL
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
-- END OF CONVERTED SQL STATEMENTS
-- Total Original Statements: 7
-- Total Converted Statement Groups: 7 (some split into multiple statements)
-- Conversion Summary:
-- - Statements 1, 2, 6, 7: No changes (already PostgreSQL-compatible)
-- - Statement 3: Split into 3 statements (INSERT with RETURNING, 2 follow-ups)
-- - Statement 4: Split into 4 statements (SELECT old values, UPDATE, 2 follow-ups)
-- - Statement 5: Split into 4 statements (SELECT old values, history, DELETE, stats)
-- - All GETDATE() replaced with NOW()
-- - All SCOPE_IDENTITY() replaced with RETURNING clause
-- - All transaction control moved to C# code level
-- =====================================================================
