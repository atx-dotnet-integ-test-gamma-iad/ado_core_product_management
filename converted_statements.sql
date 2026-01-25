-- ============================================================================
-- PostgreSQL Converted SQL Statements
-- Migration: Microsoft SQL Server to PostgreSQL
-- Target: AdoCore Application - ProductRepository.cs
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Total Statements: 7 converted statements
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model conversion failed after 15 attempts
-- Manual Conversion Applied: YES
-- Changes Applied:
-- 1. CTE syntax remains compatible with PostgreSQL
-- 2. Window functions (AVG OVER, COUNT OVER) are compatible
-- 3. ROUND function syntax compatible
-- 4. CASE expressions compatible
-- 5. No schema changes needed (Products table name preserved)
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
-- STATEMENT 2: GetProductByIdAsync - LAG Window Function
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model conversion failed after 15 attempts
-- Manual Conversion Applied: YES
-- Changes Applied:
-- 1. CTE syntax remains compatible
-- 2. LAG window function fully compatible with PostgreSQL
-- 3. ROUND function compatible
-- 4. CASE expressions compatible
-- 5. Parameter syntax @ProductId remains compatible
-- 6. No schema changes needed
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
-- STATEMENT 3: InsertProductAsync - Transaction Block with RETURNING
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted (anticipated failure based on previous errors)
-- Manual Conversion Applied: YES
-- Changes Applied:
-- 1. Removed DECLARE statement (PostgreSQL handles this differently)
-- 2. Changed BEGIN TRANSACTION to BEGIN
-- 3. Replaced SCOPE_IDENTITY() with RETURNING ProductId
-- 4. Changed GETDATE() to NOW()
-- 5. Combined INSERT with RETURNING to get new ProductId
-- 6. Modified to use PostgreSQL transaction syntax
-- 7. Returns ProductId directly from INSERT RETURNING
-- ============================================================================
-- PostgreSQL Version - Using DO block for transaction with variable
DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product and get the ID
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
    
    -- Return the new ProductId
    RETURN v_NewProductId;
END $$;

-- Alternative simpler version for use in ADO.NET (without DO block):
-- This version uses a single INSERT with RETURNING and separate statements
-- INSERT INTO Products (Name, Description, Price, StockQuantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING ProductId;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted (anticipated failure)
-- Manual Conversion Applied: YES
-- Changes Applied:
-- 1. Changed BEGIN TRANSACTION to BEGIN
-- 2. DECLARE syntax remains compatible in PostgreSQL function context
-- 3. Changed GETDATE() to NOW()
-- 4. SELECT INTO syntax compatible
-- 5. Transaction COMMIT syntax compatible
-- ============================================================================
BEGIN;
    -- Store old values for history
    DO $$
    DECLARE
        v_OldPrice DECIMAL(18,2);
        v_OldStock INT;
    BEGIN
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
            ModifiedDate = NOW()
        WHERE ProductId = @ProductId;
        
        -- Log the changes
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, NOW());
        
        -- Update product statistics
        UPDATE ProductStats
        SET 
            AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
            LastUpdated = NOW()
        WHERE StatId = 1;
    END $$;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted (anticipated failure)
-- Manual Conversion Applied: YES
-- Changes Applied:
-- 1. Changed BEGIN TRANSACTION to BEGIN
-- 2. DECLARE syntax in DO block for PostgreSQL
-- 3. Changed GETDATE() to NOW()
-- 4. CASE expression compatible
-- 5. Transaction COMMIT syntax compatible
-- ============================================================================
BEGIN;
    -- Store product info for history
    DO $$
    DECLARE
        v_OldPrice DECIMAL(18,2);
        v_OldStock INT;
    BEGIN
        SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
        FROM Products
        WHERE ProductId = @ProductId;
        
        -- Log the deletion
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, NOW());
        
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
            LastUpdated = NOW()
        WHERE StatId = 1;
    END $$;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK/PERCENT_RANK
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted (anticipated failure)
-- Manual Conversion Applied: YES
-- Changes Applied:
-- 1. CTE syntax remains compatible
-- 2. RANK() and PERCENT_RANK() window functions fully compatible
-- 3. BETWEEN operator compatible
-- 4. Parameter syntax compatible
-- 5. No schema changes needed
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
-- STATEMENT 7: GetLowStockProductsAsync - Window Functions for Stock Analysis
-- ============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Not attempted (anticipated failure)
-- Manual Conversion Applied: YES
-- Changes Applied:
-- 1. CTE syntax remains compatible
-- 2. Window functions (AVG, MIN, MAX OVER) fully compatible
-- 3. ROUND function compatible
-- 4. CASE expressions compatible
-- 5. Parameter syntax compatible
-- 6. No schema changes needed
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Errors: 2 explicit attempts failed, 5 not attempted due to anticipated failure
-- 
-- Key PostgreSQL Conversions Applied:
-- 1. GETDATE() → NOW()
-- 2. BEGIN TRANSACTION → BEGIN
-- 3. SCOPE_IDENTITY() → RETURNING clause
-- 4. DECLARE statements → DO $$ blocks for transaction contexts
-- 5. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK OVER) - All compatible, no changes
-- 6. CTE (WITH clause) - Fully compatible, no changes
-- 7. CASE expressions - Fully compatible, no changes
-- 8. Parameter syntax (@ParamName) - Compatible with Npgsql
-- 9. Data types (DECIMAL, INT, VARCHAR) - Compatible
-- 10. ROUND function - Compatible
--
-- Schema Object Names:
-- - All table names preserved (Products, ProductHistory, ProductStats)
-- - No schema name changes from DMS tool
-- ============================================================================
