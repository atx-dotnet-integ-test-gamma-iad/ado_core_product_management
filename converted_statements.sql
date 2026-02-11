-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: Microsoft SQL Server to PostgreSQL Migration
-- Purpose: Paired original and converted SQL statements
-- Conversion Method: Manual (DMS tool unavailable due to metadata errors)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: COMPLETED
-- ============================================================================

-- ORIGINAL SQL SERVER:
-- WITH ProductStats AS (
--     SELECT 
--         ProductId,
--         AVG(Price) OVER() as AvgPrice,
--         COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 'Above Average'
--         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
--         ELSE 'Average'
--     END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p
-- INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY 
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 1
--         ELSE 2
--     END,
--     p.Name;

-- CONVERTED POSTGRESQL:
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
    ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2) as PricePercentageOfAverage
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: COMPLETED
-- ============================================================================

-- ORIGINAL SQL SERVER:
-- WITH ProductHistory AS (
--     SELECT 
--         ProductId,
--         LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
--         LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products
--     WHERE ProductId = @ProductId
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     ph.PreviousPrice,
--     ph.PreviousStock,
--     CASE 
--         WHEN ph.PreviousPrice IS NOT NULL THEN 
--             ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
--         ELSE NULL
--     END as PriceChangePercentage
-- FROM Products p
-- LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
-- WHERE p.ProductId = @ProductId;

-- CONVERTED POSTGRESQL:
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
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice)::numeric * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: COMPLETED
-- Notes: Restructured to use RETURNING clause instead of SCOPE_IDENTITY()
--        Transaction handling moved to C# code level
-- ============================================================================

-- ORIGINAL SQL SERVER:
-- DECLARE @NewProductId INT;
-- 
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     
--     SET @NewProductId = SCOPE_IDENTITY();
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;
-- 
-- SELECT @NewProductId;

-- CONVERTED POSTGRESQL (Statement 3a - Insert with RETURNING):
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- CONVERTED POSTGRESQL (Statement 3b - Log history - execute after getting ProductId):
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- CONVERTED POSTGRESQL (Statement 3c - Update statistics):
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: COMPLETED
-- Notes: Transaction handling moved to C# code level
--        Execute statements sequentially within NpgsqlTransaction
-- ============================================================================

-- ORIGINAL SQL SERVER:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     UPDATE Products
--     SET 
--         Name = @Name,
--         Description = @Description,
--         Price = @Price,
--         StockQuantity = @StockQuantity,
--         ModifiedDate = GETDATE()
--     WHERE ProductId = @ProductId;
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     
--     UPDATE ProductStats
--     SET 
--         AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL (Statement 4a - Get old values):
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- CONVERTED POSTGRESQL (Statement 4b - Update product):
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- CONVERTED POSTGRESQL (Statement 4c - Log changes):
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- CONVERTED POSTGRESQL (Statement 4d - Update statistics):
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: COMPLETED
-- Notes: Transaction handling moved to C# code level
-- ============================================================================

-- ORIGINAL SQL SERVER:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     
--     DELETE FROM Products 
--     WHERE ProductId = @ProductId;
--     
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts - 1,
--         AveragePrice = CASE 
--             WHEN TotalProducts > 1 
--             THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--             ELSE 0
--         END,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL (Statement 5a - Get old values):
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- CONVERTED POSTGRESQL (Statement 5b - Log deletion):
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- CONVERTED POSTGRESQL (Statement 5c - Delete product):
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- CONVERTED POSTGRESQL (Statement 5d - Update statistics):
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: COMPLETED
-- ============================================================================

-- ORIGINAL SQL SERVER:
-- WITH RankedProducts AS (
--     SELECT 
--         p.*,
--         RANK() OVER (ORDER BY p.Price) as PriceRank,
--         PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM Products p
--     WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT 
--     rp.*,
--     CASE 
--         WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
--         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
--         ELSE 'Premium'
--     END as PriceSegment
-- FROM RankedProducts rp
-- ORDER BY rp.PriceRank;

-- CONVERTED POSTGRESQL:
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: COMPLETED
-- ============================================================================

-- ORIGINAL SQL SERVER:
-- WITH StockAnalysis AS (
--     SELECT 
--         p.*,
--         AVG(StockQuantity) OVER() as AvgStock,
--         MIN(StockQuantity) OVER() as MinStock,
--         MAX(StockQuantity) OVER() as MaxStock
--     FROM Products p
-- )
-- SELECT 
--     sa.*,
--     CASE 
--         WHEN StockQuantity <= @Threshold THEN 'Critical'
--         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
--         ELSE 'Adequate'
--     END as StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa
-- WHERE StockQuantity <= @Threshold
-- ORDER BY StockQuantity;

-- CONVERTED POSTGRESQL:
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
    ROUND((StockQuantity::numeric / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statement Pairs: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool metadata errors)
-- 
-- Key Changes Applied:
-- 1. GETDATE() → NOW()
-- 2. SCOPE_IDENTITY() → RETURNING clause
-- 3. BEGIN TRANSACTION/COMMIT → Transaction handling in C# code
-- 4. DECLARE @Variable → Restructured to use sequential queries
-- 5. Added ::numeric casts for precision in calculations
-- 6. Split multi-statement transactions into separate executable statements
-- 
-- All conversions maintain functional equivalency with original SQL Server code.
-- ============================================================================
