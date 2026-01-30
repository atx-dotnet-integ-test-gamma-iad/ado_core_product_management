-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG - POSTGRESQL
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Conversion Date: 2026-01-30
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered errors/timeouts)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Original MS SQL Statement ID: 1
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model conversion did not complete after 15 attempts
-- PostgreSQL Compatibility: Window functions (AVG OVER, COUNT OVER), CTEs, and CASE statements are fully compatible
-- Changes Applied: None required - PostgreSQL supports this syntax natively
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Original MS SQL Statement ID: 2
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation did not complete after 15 attempts
-- PostgreSQL Compatibility: LAG window function, CTEs, and CASE statements are fully compatible
-- Changes Applied: None required - PostgreSQL supports this syntax natively
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
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY()
-- ============================================================================
-- Original MS SQL Statement ID: 3
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted due to previous failures
-- PostgreSQL Changes:
--   1. SCOPE_IDENTITY() → RETURNING clause pattern
--   2. GETDATE() → CURRENT_TIMESTAMP
--   3. BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   4. Variable declarations moved to DO block with proper PostgreSQL syntax
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

-- ============================================================================
-- ALTERNATIVE STATEMENT 3 (Simpler version for ADO.NET ExecuteScalar):
-- This version is more compatible with ADO.NET ExecuteScalar pattern
-- ============================================================================

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then in separate statements:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
-- 
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Multiple Updates
-- ============================================================================
-- Original MS SQL Statement ID: 4
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted due to previous failures
-- PostgreSQL Changes:
--   1. GETDATE() → CURRENT_TIMESTAMP
--   2. BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT (implicit in ADO.NET transaction)
--   3. DECIMAL type syntax unchanged (compatible)
-- Note: Transaction management handled by ADO.NET, not in SQL
-- ============================================================================

-- Store old values for history
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
-- Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log the changes (separate statement)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
FROM OldValues ov;

-- Update product statistics (separate statement)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT Price FROM Products WHERE ProductId = @ProductId) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- ALTERNATIVE STATEMENT 4 (Using local variables in procedural block):
-- More similar to original T-SQL structure
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
-- STATEMENT 5: DeleteProductAsync - Transaction with Delete and History
-- ============================================================================
-- Original MS SQL Statement ID: 5
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted due to previous failures
-- PostgreSQL Changes:
--   1. GETDATE() → CURRENT_TIMESTAMP
--   2. BEGIN TRANSACTION/COMMIT → handled by ADO.NET
--   3. CASE expression syntax unchanged (compatible)
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Original MS SQL Statement ID: 6
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Command execution timed out after 300 seconds
-- PostgreSQL Compatibility: RANK, PERCENT_RANK, CTEs, and CASE fully compatible
-- Changes Applied: None required - PostgreSQL supports this syntax natively
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ============================================================================
-- Original MS SQL Statement ID: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted due to previous failures
-- PostgreSQL Compatibility: Window functions (AVG, MIN, MAX OVER), CTEs fully compatible
-- Changes Applied: None required - PostgreSQL supports this syntax natively
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
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
-- Summary:
-- - Total Statements: 7
-- - Successfully Converted by DMS: 0
-- - Manually Converted After DMS Failure: 7
-- - Statements Requiring Transaction Handling Changes: 3 (INSERT, UPDATE, DELETE)
-- - Statements Compatible Without Changes: 4 (SELECT queries with CTEs/window functions)
-- ============================================================================
-- Critical Notes for Code Integration:
-- 1. Statements 3, 4, 5 (INSERT, UPDATE, DELETE) have transaction handling changes
-- 2. For Statement 3 (INSERT), use RETURNING clause instead of SCOPE_IDENTITY()
-- 3. For Statements 4 & 5 (UPDATE/DELETE), break into multiple statements or use DO blocks
-- 4. Parameter syntax (@param) is supported by Npgsql - no changes needed
-- 5. All GETDATE() replaced with CURRENT_TIMESTAMP
-- 6. Window functions, CTEs, and CASE expressions work identically in PostgreSQL
-- ============================================================================
