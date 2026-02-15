-- ========================================================================================================
-- SQL STATEMENT CONVERSION CATALOG - PostgreSQL
-- Purpose: PostgreSQL converted statements from Microsoft SQL Server
-- Date: 2026-02-15
-- Conversion Method: Manual (DMS tool experienced systemic errors)
-- Total Statements: 7
-- ========================================================================================================

-- ========================================================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync
-- Original Source: extracted_statements.sql, Statement 1
-- Conversion Notes: 
--   - CTEs are fully compatible between SQL Server and PostgreSQL
--   - Window functions (AVG, COUNT OVER) are compatible
--   - CASE expressions are compatible
--   - ROUND function is compatible
--   - No schema object name changes required
-- Changes Made: None required - SQL is compatible with PostgreSQL
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
-- CONVERTED STATEMENT 2: GetProductByIdAsync
-- Original Source: extracted_statements.sql, Statement 2
-- Conversion Notes:
--   - CTEs are compatible
--   - LAG window function is fully supported in PostgreSQL
--   - Parameter syntax (@ProductId) is compatible with Npgsql
--   - No schema object name changes required
-- Changes Made: None required - SQL is compatible with PostgreSQL
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
-- CONVERTED STATEMENT 3: InsertProductAsync
-- Original Source: extracted_statements.sql, Statement 3
-- Conversion Notes:
--   - SCOPE_IDENTITY() converted to RETURNING clause pattern
--   - GETDATE() converted to CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT handled at application level (ADO.NET)
--   - Variable declarations removed (handled by application code)
--   - Combined into single statement with RETURNING for new ID
-- Changes Made:
--   1. Removed DECLARE @NewProductId and explicit transaction control
--   2. Converted SCOPE_IDENTITY() to RETURNING ProductId pattern
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Restructured as CTE to maintain transaction logic
-- ========================================================================================================
WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
),
stats_update AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM inserted_product;

-- ========================================================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync
-- Original Source: extracted_statements.sql, Statement 4
-- Conversion Notes:
--   - DECLARE statements converted to CTE pattern
--   - GETDATE() converted to CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT handled at application level
--   - Variable assignments converted to CTE subqueries
-- Changes Made:
--   1. Removed explicit transaction control (handled by ADO.NET)
--   2. Converted DECLARE and SELECT variable assignment to CTE
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Maintained original logic flow with CTEs
-- ========================================================================================================
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
product_update AS (
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync
-- Original Source: extracted_statements.sql, Statement 5
-- Conversion Notes:
--   - DECLARE statements converted to CTE pattern
--   - GETDATE() converted to CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT handled at application level
--   - Variable assignments converted to CTE subqueries
-- Changes Made:
--   1. Removed explicit transaction control (handled by ADO.NET)
--   2. Converted DECLARE and SELECT variable assignment to CTE
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Maintained delete cascade logic
-- ========================================================================================================
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING ProductId
),
product_delete AS (
    DELETE FROM Products 
    WHERE ProductId = @ProductId
    RETURNING ProductId
)
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

-- ========================================================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync
-- Original Source: extracted_statements.sql, Statement 6
-- Conversion Notes:
--   - CTEs are compatible
--   - RANK() and PERCENT_RANK() window functions are fully supported
--   - BETWEEN operator is compatible
--   - No schema object name changes required
-- Changes Made: None required - SQL is compatible with PostgreSQL
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
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync
-- Original Source: extracted_statements.sql, Statement 7
-- Conversion Notes:
--   - CTEs are compatible
--   - Window functions (AVG, MIN, MAX OVER) are compatible
--   - ROUND function is compatible
--   - No schema object name changes required
-- Changes Made: None required - SQL is compatible with PostgreSQL
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
-- END OF CONVERSION CATALOG
-- ========================================================================================================
