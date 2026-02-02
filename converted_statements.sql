-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Source: AdoCore Application - Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7
-- Conversion Method: Manual conversion (DMS tool unavailable)
-- Conversion Date: 2026-02-02
-- ============================================================================
-- IMPORTANT: All conversions maintain original schema object names
-- Tables: Products, ProductHistory, ProductStats (default public schema)
-- Parameter prefix @ is retained (Npgsql supports @ prefix)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ============================================================================
-- Original: Lines 44-72 in ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - AVG() OVER(): Compatible with PostgreSQL
--   - COUNT(*) OVER(): Compatible with PostgreSQL
--   - ROUND(value, precision): Compatible with PostgreSQL
--   - CASE expressions: Compatible with PostgreSQL
--   - INNER JOIN: Compatible with PostgreSQL
-- Schema Objects: Products (no transformation)
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ============================================================================
-- Original: Lines 88-118 in ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - LAG() OVER (ORDER BY): Compatible with PostgreSQL
--   - LEFT JOIN: Compatible with PostgreSQL
--   - CASE with NULL handling: Compatible with PostgreSQL
--   - ROUND function: Compatible with PostgreSQL
--   - Parameter @ProductId: Retained (Npgsql supports @)
-- Schema Objects: Products (no transformation)
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
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- ============================================================================
-- Original: Lines 137-169 in ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - BEGIN TRANSACTION: Compatible with PostgreSQL (or just BEGIN)
--   - DECLARE @var: Removed, using RETURNING clause instead
--   - SCOPE_IDENTITY(): Replaced with RETURNING ProductId
--   - GETDATE(): Replaced with NOW()
--   - Multi-statement transaction: Using PostgreSQL DO block with CTEs
--   - COMMIT: Compatible with PostgreSQL
-- Schema Objects: Products, ProductHistory, ProductStats (no transformation)
-- CRITICAL: This uses PostgreSQL's RETURNING clause for identity retrieval
-- ============================================================================

DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product and get the new ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    -- Return the new product ID
    RAISE NOTICE 'NewProductId: %', v_NewProductId;
END $$;

-- Note: For ADO.NET usage, this needs to be restructured to return the ID properly.
-- Alternative approach using simple statements with RETURNING:

WITH inserted AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId, Price, StockQuantity
),
history_logged AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, Price, NULL, StockQuantity, NOW()
    FROM inserted
    RETURNING ProductId
),
stats_updated AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + (SELECT Price FROM inserted)) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM inserted;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ============================================================================
-- Original: Lines 177-213 in ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - BEGIN TRANSACTION: Compatible with PostgreSQL
--   - DECLARE variables: Using PostgreSQL variables or CTE approach
--   - Variable assignment SELECT: Using CTE or direct UPDATE
--   - GETDATE(): Replaced with NOW()
--   - COMMIT: Compatible with PostgreSQL
-- Schema Objects: Products, ProductHistory, ProductStats (no transformation)
-- ============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
product_updated AS (
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = NOW()
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
history_logged AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, NOW()
    FROM old_values ov
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ============================================================================
-- Original: Lines 219-254 in ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - BEGIN TRANSACTION: Compatible with PostgreSQL
--   - DECLARE variables: Using CTE approach
--   - GETDATE(): Replaced with NOW()
--   - CASE expression: Compatible with PostgreSQL
--   - COMMIT: Compatible with PostgreSQL
-- Schema Objects: Products, ProductHistory, ProductStats (no transformation)
-- ============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
history_logged AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, NOW()
    FROM old_values ov
    RETURNING ProductId
),
product_deleted AS (
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
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ============================================================================
-- Original: Lines 262-285 in ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - RANK() OVER (ORDER BY): Compatible with PostgreSQL
--   - PERCENT_RANK() OVER (ORDER BY): Compatible with PostgreSQL
--   - BETWEEN clause: Compatible with PostgreSQL
--   - CASE expression: Compatible with PostgreSQL
--   - Parameters @MinPrice, @MaxPrice: Retained (Npgsql supports @)
-- Schema Objects: Products (no transformation)
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ============================================================================
-- Original: Lines 297-324 in ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - AVG() OVER(): Compatible with PostgreSQL
--   - MIN() OVER(): Compatible with PostgreSQL
--   - MAX() OVER(): Compatible with PostgreSQL
--   - CASE expression: Compatible with PostgreSQL
--   - ROUND function: Compatible with PostgreSQL
--   - Parameter @Threshold: Retained (Npgsql supports @)
-- Schema Objects: Products (no transformation)
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
-- Total Statements Converted: 7
-- Conversion Method: Manual (DMS tool unavailable)
-- 
-- Key Transformations Applied:
-- 1. GETDATE() → NOW() (8 occurrences across statements 3, 4, 5)
-- 2. SCOPE_IDENTITY() → RETURNING clause (statement 3)
-- 3. DECLARE/SET pattern → CTE or DO block approach (statements 3, 4, 5)
-- 4. Multi-statement transactions → CTE chains or DO blocks
-- 
-- Compatible Features (No Changes Required):
-- - CTE (WITH) syntax
-- - Window functions: AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER()
-- - CASE expressions
-- - JOIN types (INNER, LEFT)
-- - ROUND function
-- - BETWEEN clause
-- - Parameter prefix @ (Npgsql supports it)
-- 
-- Schema Transformations: NONE
-- All table names remain unchanged: Products, ProductHistory, ProductStats
-- ============================================================================
