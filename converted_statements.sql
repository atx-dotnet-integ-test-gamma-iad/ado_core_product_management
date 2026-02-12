-- ===============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL VERSION
-- ===============================================================================
-- Conversion Date: 2026-02-12
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All 7 statements)
-- DMS Tool Status: Failed for all statements with metadata model creation error
-- Total Statements: 7
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED TO POSTGRESQL
-- ===============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - No syntax changes needed (CTEs and window functions are PostgreSQL compatible)
--   - Table and column names retained
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED TO POSTGRESQL
-- ===============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - No syntax changes needed (CTEs and LAG window function are PostgreSQL compatible)
--   - Table and column names retained
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED TO POSTGRESQL
-- ===============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed DECLARE @NewProductId INT (PostgreSQL uses RETURNING clause)
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Removed SET @NewProductId = SCOPE_IDENTITY()
--   - Modified first INSERT to use RETURNING ProductId
--   - Changed GETDATE() to CURRENT_TIMESTAMP (3 occurrences)
--   - Removed final SELECT @NewProductId (value returned via RETURNING clause)
-- NOTE: This will need code-level changes to handle RETURNING clause properly
-- ===============================================================================
BEGIN;
    -- Insert the new product and return the ID
    WITH new_product AS (
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING ProductId
    ),
    -- Log the insertion
    log_entry AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
        FROM new_product
        RETURNING ProductId
    )
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING (SELECT ProductId FROM new_product);
COMMIT;

-- ===============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED TO POSTGRESQL
-- ===============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Removed DECLARE statements (using CTEs to capture old values)
--   - Changed GETDATE() to CURRENT_TIMESTAMP (3 occurrences)
--   - Restructured to use WITH clause for capturing old values
-- ===============================================================================
BEGIN;
    -- Store old values and perform update
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
    history_log AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
        FROM old_values ov
        RETURNING ProductId
    )
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ===============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED TO POSTGRESQL
-- ===============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Removed DECLARE statements (using CTEs to capture old values)
--   - Changed GETDATE() to CURRENT_TIMESTAMP (1 occurrence)
--   - Restructured to use WITH clause for capturing old values before delete
-- ===============================================================================
BEGIN;
    -- Store product info for history before deletion
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    ),
    history_log AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP
        FROM old_values ov
        RETURNING ProductId
    ),
    product_delete AS (
        DELETE FROM Products 
        WHERE ProductId = @ProductId
        RETURNING ProductId
    )
    -- Update product statistics
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
COMMIT;

-- ===============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED TO POSTGRESQL
-- ===============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - No syntax changes needed (CTEs, RANK, and PERCENT_RANK are PostgreSQL compatible)
--   - Table and column names retained
-- ===============================================================================
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

-- ===============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED TO POSTGRESQL
-- ===============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - No syntax changes needed (CTEs and window functions are PostgreSQL compatible)
--   - Table and column names retained
-- ===============================================================================
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

-- ===============================================================================
-- CONVERSION SUMMARY
-- ===============================================================================
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- 
-- Key Transformations Applied:
-- 1. SCOPE_IDENTITY() -> RETURNING clause in INSERT statements
-- 2. GETDATE() -> CURRENT_TIMESTAMP
-- 3. BEGIN TRANSACTION -> BEGIN
-- 4. COMMIT (no change needed)
-- 5. DECLARE @Variable -> Removed, using CTEs or RETURNING clauses
-- 6. SET @Variable = value -> Removed, using RETURNING clauses
-- 7. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK) - No changes needed
-- 8. CTEs - No changes needed (PostgreSQL fully supports CTEs)
-- 
-- Schema Object Names:
-- - No schema name changes from DMS
-- - Tables: Products, ProductHistory, ProductStats (unchanged)
-- - All column names retained as-is
-- ===============================================================================
