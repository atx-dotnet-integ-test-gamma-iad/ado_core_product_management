-- ================================================================
-- CONVERTED SQL STATEMENTS FROM MS SQL SERVER TO POSTGRESQL
-- ================================================================
-- Conversion Date: 2026-02-17
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- DMS Tool Status: Failed for all statements with metadata model creation error
-- Total Statements Converted: 7
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- ================================================================
-- Original Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: Minor syntax already PostgreSQL compatible
-- Notes: CTEs, window functions, CASE, and ROUND are compatible with PostgreSQL
-- ================================================================

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

-- ================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- ================================================================
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: Parameter syntax (@ProductId) compatible with PostgreSQL
-- Notes: LAG window function, CTEs, and LEFT JOIN are PostgreSQL compatible
-- ================================================================

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

-- ================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- ================================================================
-- Original Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Removed DECLARE @NewProductId (handled in code using RETURNING)
--   2. Removed BEGIN TRANSACTION/COMMIT (handled in code with NpgsqlTransaction)
--   3. Changed SCOPE_IDENTITY() to RETURNING ProductId
--   4. Changed GETDATE() to CURRENT_TIMESTAMP
-- Notes: Transaction handling moved to C# code level
-- ================================================================

-- First INSERT with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Second INSERT (will be executed with returned ProductId as @NewProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Third UPDATE
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- ================================================================
-- Original Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Removed DECLARE statements (variables handled in code)
--   2. Removed BEGIN TRANSACTION/COMMIT (handled in code)
--   3. Changed GETDATE() to CURRENT_TIMESTAMP
-- Notes: SELECT into variables and transaction handling in C# code
-- ================================================================

-- First SELECT to get old values (executed separately in code)
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second UPDATE
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Third INSERT
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Fourth UPDATE
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- ================================================================
-- Original Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Removed DECLARE statements (variables handled in code)
--   2. Removed BEGIN TRANSACTION/COMMIT (handled in code)
--   3. Changed GETDATE() to CURRENT_TIMESTAMP
-- Notes: Transaction handling in C# code
-- ================================================================

-- First SELECT to get old values (executed separately in code)
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second INSERT
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Third DELETE
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Fourth UPDATE
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- ================================================================
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: None - fully compatible with PostgreSQL
-- Notes: RANK(), PERCENT_RANK(), CTEs, and BETWEEN are PostgreSQL compatible
-- ================================================================

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

-- ================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- ================================================================
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: None - fully compatible with PostgreSQL
-- Notes: Multiple window functions (AVG, MIN, MAX), CTEs are PostgreSQL compatible
-- ================================================================

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

-- ================================================================
-- END OF CONVERTED STATEMENTS
-- ================================================================
-- SUMMARY:
-- - Total Statements: 7
-- - Conversion Method: ALL statements converted manually after DMS tool failure
-- - Main Conversions Applied:
--   * GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
--   * SCOPE_IDENTITY() → RETURNING clause (Statement 3)
--   * Transaction blocks removed (handled in C# code) (Statements 3, 4, 5)
--   * Variable declarations removed (handled in C# code) (Statements 3, 4, 5)
-- - PostgreSQL Compatible Features (no changes needed):
--   * CTEs (WITH clauses)
--   * Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX)
--   * CASE expressions
--   * ROUND function
--   * BETWEEN clause
--   * Parameter syntax (@parameter)
-- ================================================================
