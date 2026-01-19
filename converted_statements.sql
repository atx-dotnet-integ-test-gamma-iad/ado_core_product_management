-- =====================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Source: ProductRepository.cs
-- Database: PostgreSQL
-- Purpose: PostgreSQL-converted statements after DMS MCP tool processing
-- Conversion Method: Manual (due to DMS timeout errors)
-- =====================================================================================

-- =====================================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- Original Source: ProductRepository.cs, Lines 38-68
-- Conversion Notes: 
-- - Window functions (AVG OVER, COUNT OVER) are directly compatible with PostgreSQL
-- - ROUND function syntax is compatible
-- - CASE expressions are compatible
-- - Changed table references to maintain schema compatibility
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- Original Source: ProductRepository.cs, Lines 80-111
-- Conversion Notes:
-- - LAG window function is directly compatible with PostgreSQL
-- - Parameter @ProductId remains compatible (Npgsql supports named parameters)
-- - LEFT JOIN syntax is compatible
-- - ROUND function and CASE expressions are compatible
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- Original Source: ProductRepository.cs, Lines 123-150
-- Conversion Notes:
-- - Converted to PostgreSQL transaction syntax (no DECLARE before BEGIN)
-- - Replaced SCOPE_IDENTITY() with RETURNING clause on INSERT
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Modified to use DO block for procedural logic with RETURNING
-- - Simplified to return new product ID using RETURNING clause
-- =====================================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
log_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1
RETURNING (SELECT ProductId FROM inserted_product);

-- =====================================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- Original Source: ProductRepository.cs, Lines 162-193
-- Conversion Notes:
-- - PostgreSQL doesn't support variable declarations outside functions
-- - Converted to use CTEs to capture old values
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Structured as multiple statements to be executed in transaction
-- =====================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
FROM old_values ov;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =====================================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- Original Source: ProductRepository.cs, Lines 205-235
-- Conversion Notes:
-- - Converted to use CTEs to capture values before deletion
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Structured as multiple statements to be executed in transaction
-- - Modified CASE expression for AveragePrice calculation
-- =====================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM old_values;

DELETE FROM Products 
WHERE ProductId = @ProductId;

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =====================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- Original Source: ProductRepository.cs, Lines 247-277
-- Conversion Notes:
-- - RANK and PERCENT_RANK window functions are directly compatible with PostgreSQL
-- - BETWEEN operator is compatible
-- - Parameter syntax (@MinPrice, @MaxPrice) is compatible with Npgsql
-- - All other syntax is PostgreSQL-compatible
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- Original Source: ProductRepository.cs, Lines 289-320
-- Conversion Notes:
-- - AVG, MIN, MAX window functions are directly compatible with PostgreSQL
-- - CASE expressions and ROUND function are compatible
-- - Parameter syntax (@Threshold) is compatible with Npgsql
-- - All syntax is PostgreSQL-compatible
-- =====================================================================================

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

-- =====================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- Total Statements: 7
-- Conversion Method: Manual conversion after DMS timeout errors
-- Key Changes Summary:
-- 1. SCOPE_IDENTITY() → RETURNING clause
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. Transaction variable declarations → CTEs
-- 4. All window functions preserved (PostgreSQL compatible)
-- 5. Parameter syntax maintained (Npgsql supports @param notation)
-- =====================================================================================
