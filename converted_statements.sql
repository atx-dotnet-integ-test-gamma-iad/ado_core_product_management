-- ============================================================================
-- PostgreSQL Converted SQL Statements
-- ============================================================================
-- This file contains all SQL statements converted from SQL Server to PostgreSQL
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all DMS tool invocations failed)
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- 
-- Total Statements: 7
-- Conversion Date: 2026-02-11
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ============================================================================
-- Original SQL Server Statement Location: ProductRepository.cs, Lines 40-70
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes: None required - CTEs and window functions are compatible
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
-- Original SQL Server Statement Location: ProductRepository.cs, Lines 85-115
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes: None required - CTEs, LAG function, and joins are compatible
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
-- Original SQL Server Statement Location: ProductRepository.cs, Lines 130-153
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   1. Removed DECLARE @NewProductId INT (use DO block with variable or refactor)
--   2. BEGIN TRANSACTION → BEGIN (implicit transaction)
--   3. SCOPE_IDENTITY() → RETURNING ProductId clause on INSERT
--   4. GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   5. Combined INSERT with RETURNING to get new ID
-- Note: This requires restructuring the C# code to capture RETURNING value
-- ============================================================================

DO $$
DECLARE 
    v_NewProductId INT;
BEGIN
    -- Insert the new product and capture the ID
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

-- Alternative approach for ADO.NET (better for C# ExecuteScalar):
-- This version is better suited for the existing C# code pattern

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then in separate commands:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ============================================================================
-- Original SQL Server Statement Location: ProductRepository.cs, Lines 165-197
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   1. BEGIN TRANSACTION → BEGIN (implicit)
--   2. DECLARE moved into DO block
--   3. SELECT INTO syntax compatible
--   4. GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ============================================================================
-- Original SQL Server Statement Location: ProductRepository.cs, Lines 209-240
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
--   1. BEGIN TRANSACTION → BEGIN (implicit)
--   2. DECLARE moved into DO block
--   3. SELECT INTO syntax compatible
--   4. GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
--   5. CASE expression compatible
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ============================================================================
-- Original SQL Server Statement Location: ProductRepository.cs, Lines 250-280
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes: None required - CTEs, RANK, PERCENT_RANK fully compatible
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
-- Original SQL Server Statement Location: ProductRepository.cs, Lines 290-320
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes: None required - CTEs and window functions fully compatible
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
-- END OF CONVERTED STATEMENTS
-- ============================================================================
-- Conversion Summary:
-- - Statements 1, 2, 6, 7: No changes required (compatible syntax)
-- - Statements 3, 4, 5: Major changes required (transaction blocks, variables, SCOPE_IDENTITY, GETDATE)
-- 
-- Key Conversion Patterns Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause with INTO variable
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. BEGIN TRANSACTION/COMMIT → DO $$ ... END $$ blocks for complex transactions
-- 4. DECLARE @Variable → DECLARE v_Variable in DO block
-- 5. SET @Variable → Direct assignment in DO block
-- 
-- Note: Statements 3, 4, 5 use DO blocks which require refactoring in C# code
-- to execute multiple commands or use a different approach for transactions.
-- ============================================================================
