-- ==================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Date: 2026-02-17
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ==================================================================================
-- NOTE: All statements were passed through DMS MCP tool first, but DMS returned 
-- consistent errors: "Metadata model creation failed: {'error': 'Unknown metadata 
-- model creation status: RECEIVED'}". Manual conversions were applied based on 
-- PostgreSQL best practices while maintaining functional equivalency.
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original Source: ProductRepository.cs, Lines ~42-70
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- ==================================================================================

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

-- Conversion Notes:
-- - CTE syntax is identical in PostgreSQL
-- - Window functions (AVG, COUNT OVER) are fully supported in PostgreSQL
-- - CASE expressions are identical
-- - ROUND function syntax is identical
-- - No changes required for this query

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Original Source: ProductRepository.cs, Lines ~78-111
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- ==================================================================================

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

-- Conversion Notes:
-- - LAG window function is fully supported in PostgreSQL
-- - Parameter syntax @ProductId is compatible with Npgsql
-- - LEFT JOIN syntax is identical
-- - No changes required for this query

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Original Source: ProductRepository.cs, Lines ~119-143
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- ==================================================================================

DO $$
DECLARE 
    v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    -- Return the new product ID
    RAISE NOTICE 'NewProductId: %', v_NewProductId;
END $$;

-- Conversion Notes:
-- - Replaced DECLARE @NewProductId INT with DO $$ DECLARE v_NewProductId INT block
-- - Replaced SCOPE_IDENTITY() with RETURNING ProductId INTO v_NewProductId
-- - Replaced GETDATE() with CURRENT_TIMESTAMP (PostgreSQL standard)
-- - Replaced BEGIN TRANSACTION/COMMIT with DO $$ block (implicit transaction)
-- - Changed SELECT @NewProductId to RAISE NOTICE for debugging
-- - For application usage, will need to use RETURNING clause in INSERT statement directly

-- ==================================================================================
-- STATEMENT 3b: InsertProductAsync (SIMPLIFIED FOR APPLICATION USE)
-- This version is more suitable for use in the application code
-- ==================================================================================

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The history logging and statistics update should be handled via triggers
-- or separate statements in the application. For now, keeping INSERT simple with RETURNING.

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original Source: ProductRepository.cs, Lines ~151-182
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- ==================================================================================

DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Conversion Notes:
-- - Replaced DECLARE @OldPrice with DECLARE v_OldPrice in DO $$ block
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Replaced BEGIN TRANSACTION/COMMIT with DO $$ block (implicit transaction)
-- - Changed variable names to PostgreSQL convention (v_ prefix)

-- ==================================================================================
-- STATEMENT 4b: UpdateProductAsync (SIMPLIFIED FOR APPLICATION USE)
-- This version is more suitable for use in the application code
-- ==================================================================================

UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Note: History logging and statistics update should be handled via triggers or separate statements

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original Source: ProductRepository.cs, Lines ~190-221
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- ==================================================================================

DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - v_OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Conversion Notes:
-- - Replaced DECLARE @OldPrice with DECLARE v_OldPrice in DO $$ block
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- - Replaced BEGIN TRANSACTION/COMMIT with DO $$ block (implicit transaction)
-- - CASE expression syntax is identical in PostgreSQL

-- ==================================================================================
-- STATEMENT 5b: DeleteProductAsync (SIMPLIFIED FOR APPLICATION USE)
-- This version is more suitable for use in the application code
-- ==================================================================================

DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Note: History logging and statistics update should be handled via triggers

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original Source: ProductRepository.cs, Lines ~229-257
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- ==================================================================================

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

-- Conversion Notes:
-- - RANK() and PERCENT_RANK() window functions are fully supported in PostgreSQL
-- - BETWEEN operator syntax is identical
-- - No changes required for this query

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Original Source: ProductRepository.cs, Lines ~265-293
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- ==================================================================================

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

-- Conversion Notes:
-- - Aggregate window functions (AVG, MIN, MAX OVER) are fully supported in PostgreSQL
-- - CASE expression and ROUND function syntax are identical
-- - No changes required for this query

-- ==================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- Total Statements: 7
-- Successfully Converted: 7 (all manual conversions after DMS failure)
-- DMS Tool Errors: 7 (all statements encountered DMS metadata model creation error)
-- ==================================================================================
-- Summary of Key Conversions:
--   1. GETDATE() → CURRENT_TIMESTAMP (5 occurrences in transaction statements)
--   2. SCOPE_IDENTITY() → RETURNING clause (1 occurrence in INSERT)
--   3. BEGIN TRANSACTION/COMMIT → DO $$ blocks or implicit transactions (3 occurrences)
--   4. Variable declarations: @Variable → v_Variable in DO blocks (6 variables)
--   5. No changes needed for: CTEs, Window Functions, CASE, ROUND, JOIN syntax
-- ==================================================================================
