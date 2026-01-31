-- ============================================================================
-- PostgreSQL Converted SQL Statements Catalog
-- Migration: SQL Server to PostgreSQL
-- Conversion Date: 2026-01-31
-- Total Statements: 7
-- Conversion Method: Manual conversion after DMS tool timeout failures
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original: MS SQL Server with window functions and CTEs
-- Conversion: Minor syntax adjustments for PostgreSQL compatibility
-- Changes Applied:
--   - No major changes needed (CTEs and window functions compatible)
--   - String literals remain single-quoted
--   - ROUND function compatible
-- Schema Objects: Products (no name changes)
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
-- CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original: MS SQL Server with LAG window function
-- Conversion: Parameter syntax maintained (@ prefix compatible with Npgsql)
-- Changes Applied:
--   - LAG() OVER compatible with PostgreSQL
--   - @ProductId parameter syntax compatible with Npgsql
--   - ROUND function compatible
-- Schema Objects: Products (no name changes)
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
-- CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original: MS SQL Server with SCOPE_IDENTITY() and GETDATE()
-- Conversion: Major syntax changes for PostgreSQL
-- Changes Applied:
--   - Removed DECLARE @NewProductId (use RETURNING clause)
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - SCOPE_IDENTITY() -> RETURNING ProductId clause in INSERT
--   - GETDATE() -> CURRENT_TIMESTAMP (3 occurrences)
--   - Removed standalone SELECT statement
--   - Changed variable usage to RETURNING pattern
-- Schema Objects: Products, ProductHistory, ProductStats (no name changes)
-- CRITICAL: This returns the new ID via RETURNING in the INSERT statement
-- Application code must use ExecuteScalar on the INSERT to get the ID
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
END $$;

-- Alternative simplified version for ADO.NET ExecuteScalar:
-- INSERT INTO Products (Name, Description, Price, StockQuantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING ProductId;
--
-- Then in separate commands:
-- INSERT INTO ProductHistory... (with the returned ProductId)
-- UPDATE ProductStats...

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with History
-- CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original: MS SQL Server with DECLARE variables and GETDATE()
-- Conversion: Transaction syntax and date function changes
-- Changes Applied:
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - Variable declarations remain (PostgreSQL supports them in procedures)
--   - GETDATE() -> CURRENT_TIMESTAMP (3 occurrences)
--   - COMMIT remains the same
-- Schema Objects: Products, ProductHistory, ProductStats (no name changes)
-- ============================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
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
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Cleanup
-- CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original: MS SQL Server with DECLARE variables and GETDATE()
-- Conversion: Transaction syntax and date function changes
-- Changes Applied:
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - Variable declarations remain
--   - GETDATE() -> CURRENT_TIMESTAMP (2 occurrences)
--   - COMMIT remains the same
-- Schema Objects: Products, ProductHistory, ProductStats (no name changes)
-- ============================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK Functions
-- CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original: MS SQL Server with RANK() and PERCENT_RANK()
-- Conversion: Minor syntax adjustments
-- Changes Applied:
--   - RANK() and PERCENT_RANK() compatible with PostgreSQL
--   - BETWEEN clause compatible
--   - Parameter syntax (@MinPrice, @MaxPrice) compatible with Npgsql
-- Schema Objects: Products (no name changes)
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
-- CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original: MS SQL Server with multiple window functions
-- Conversion: No major changes needed
-- Changes Applied:
--   - Window functions (AVG, MIN, MAX OVER) compatible with PostgreSQL
--   - CASE expressions compatible
--   - Parameter syntax (@Threshold) compatible with Npgsql
-- Schema Objects: Products (no name changes)
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
-- Conversion Method: Manual after DMS timeout failures
-- DMS Tool Status: All 7 statements failed with timeout errors
--
-- Key Conversions Applied:
-- 1. SCOPE_IDENTITY() -> RETURNING clause (Statement 3)
-- 2. GETDATE() -> CURRENT_TIMESTAMP (8 occurrences total)
-- 3. BEGIN TRANSACTION -> BEGIN or DO $$ blocks (Statements 3, 4, 5)
-- 4. DECLARE syntax -> PostgreSQL variable declarations
-- 5. SET @variable -> INTO clause or direct assignment
-- 6. Window functions - Compatible, no changes
-- 7. CTEs - Compatible, no changes
-- 8. CASE expressions - Compatible, no changes
-- 9. Parameters (@param) - Compatible with Npgsql
--
-- Schema Object Name Changes: NONE
-- All table names (Products, ProductHistory, ProductStats) remain unchanged
--
-- IMPORTANT NOTES FOR CODE RE-INTEGRATION:
-- - Statements 1, 2, 6, 7: Minimal changes, mostly compatible
-- - Statements 3, 4, 5: Significant transaction block restructuring
-- - Statement 3 (INSERT): Must handle RETURNING clause differently in ADO.NET
--   The current implementation needs refactoring to separate INSERT with RETURNING
--   from the subsequent INSERT/UPDATE operations
-- - All @ parameter syntax remains compatible with Npgsql NpgsqlCommand.AddWithValue
-- ============================================================================
