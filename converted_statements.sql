-- ============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL SYNTAX
-- Converted from Microsoft SQL Server T-SQL to PostgreSQL
-- Total Statements: 7
-- Conversion Method: Manual (after DMS tool failures)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync()
-- Original Source: DataAccess/ProductRepository.cs, Line 38-63
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - CTE and window functions are identical
-- Schema Objects: Products (no schema changes)
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
-- STATEMENT 2: GetProductByIdAsync(int productId)
-- Original Source: DataAccess/ProductRepository.cs, Line 80-106
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - CTE and LAG window function are identical
-- Parameters: @ProductId (int)
-- Schema Objects: Products (no schema changes)
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
-- STATEMENT 3: InsertProductAsync(Product product)
-- Original Source: DataAccess/ProductRepository.cs, Line 123-146
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: 
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> NOW()
--   - Transaction split into separate statements for ADO.NET NpgsqlTransaction
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Schema Objects: Products, ProductHistory, ProductStats (no schema changes)
-- ============================================================================

-- Statement 3a: Insert Product with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES (@Name, @Description, @Price, @StockQuantity, NOW())
RETURNING ProductId;

-- Statement 3b: Log insertion (executed after getting ProductId from RETURNING)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync(Product product)
-- Original Source: DataAccess/ProductRepository.cs, Line 157-189
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - DECLARE @variable removed (managed in ADO.NET code)
--   - GETDATE() -> NOW()
--   - Transaction split into separate statements for ADO.NET NpgsqlTransaction
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Schema Objects: Products, ProductHistory, ProductStats (no schema changes)
-- ============================================================================

-- Statement 4a: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update product (executed after getting old values in ADO.NET)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Statement 4c: Log the update
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync(int productId)
-- Original Source: DataAccess/ProductRepository.cs, Line 199-232
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - DECLARE @variable removed (managed in ADO.NET code)
--   - GETDATE() -> NOW()
--   - Transaction split into separate statements for ADO.NET NpgsqlTransaction
-- Parameters: @ProductId
-- Schema Objects: Products, ProductHistory, ProductStats (no schema changes)
-- ============================================================================

-- Statement 5a: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log deletion (executed after getting old values in ADO.NET)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update statistics
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
-- STATEMENT 6: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Original Source: DataAccess/ProductRepository.cs, Line 242-265
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - RANK() and PERCENT_RANK() are identical
-- Parameters: @MinPrice, @MaxPrice
-- Schema Objects: Products (no schema changes)
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
-- STATEMENT 7: GetLowStockProductsAsync(int threshold)
-- Original Source: DataAccess/ProductRepository.cs, Line 281-308
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - Window functions are identical
-- Parameters: @Threshold
-- Schema Objects: Products (no schema changes)
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
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- Conversion Method: All statements - MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (all tables remain in default schema)
-- 
-- Key Changes Made:
-- 1. GETDATE() -> NOW() (Statements 3, 4, 5)
-- 2. SCOPE_IDENTITY() -> RETURNING clause (Statement 3)
-- 3. Multi-statement transactions split for ADO.NET management (Statements 3, 4, 5)
-- 4. DECLARE @variable removed (handled in ADO.NET code) (Statements 3, 4, 5)
-- 5. Statements 1, 2, 6, 7: No changes required (PostgreSQL compatible)
-- 
-- All parameter placeholders (@param) maintained for Npgsql compatibility
-- ============================================================================
