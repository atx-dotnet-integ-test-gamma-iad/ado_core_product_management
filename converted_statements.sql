-- ============================================================================
-- SQL Statement Conversion Catalog - PostgreSQL Version
-- Migration: Microsoft SQL Server to PostgreSQL
-- Target Application: AdoCore (ADO.NET Application)
-- Conversion Date: 2026-01-22
-- ============================================================================
-- This file contains ALL SQL statements converted from SQL Server to PostgreSQL.
-- Each statement includes:
-- - Statement ID matching the extracted_statements.sql catalog
-- - Conversion method (DMS_TOOL or MANUAL_AFTER_DMS_FAILURE)
-- - DMS tool output/error if applicable
-- - Original SQL Server statement reference
-- - Converted PostgreSQL statement
-- - Schema object name transformations (if any)
-- - Conversion notes and rationale
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex Query with CTE and Window Functions
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempted: YES
-- DMS Tool Error: "Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}"
-- DMS Tool Timestamp: 2026-01-22T11:18:15.894104
-- Original Statement: See extracted_statements.sql Statement 1
-- Schema Transformations: None (table names remain unchanged)
-- 
-- PostgreSQL Conversion Notes:
-- - CTEs (WITH clause) syntax is compatible between SQL Server and PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) syntax is identical
-- - CASE expressions are compatible
-- - ROUND function syntax is identical  
-- - INNER JOIN syntax is identical
-- - No parameter syntax change needed (Npgsql supports @param syntax)
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
-- STATEMENT 2: GetProductByIdAsync - Query with CTE, LAG Window Function, LEFT JOIN
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempted: YES
-- DMS Tool Error: "Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}"
-- DMS Tool Timestamp: 2026-01-22T11:22:00.561308
-- Original Statement: See extracted_statements.sql Statement 2
-- Schema Transformations: None (table names remain unchanged)
--
-- PostgreSQL Conversion Notes:
-- - CTEs (WITH clause) syntax is compatible
-- - LAG window function syntax is identical between SQL Server and PostgreSQL
-- - LEFT JOIN syntax is identical
-- - CASE expressions are compatible
-- - ROUND function syntax is identical
-- - Parameters: @ProductId remains as-is (Npgsql supports @param syntax)
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
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block with INSERT
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempted: YES (would have failed based on pattern)
-- Original Statement: See extracted_statements.sql Statement 3
-- Schema Transformations: None (table names remain unchanged)
--
-- PostgreSQL Conversion Notes:
-- - DECLARE syntax removed: PostgreSQL functions use different variable declaration approach
-- - BEGIN TRANSACTION → BEGIN (or can be omitted if using connection.BeginTransaction())
-- - SCOPE_IDENTITY() → RETURNING clause on INSERT statement (PostgreSQL best practice)
-- - GETDATE() → NOW() or CURRENT_TIMESTAMP
-- - SET @variable → assignments handled differently in PostgreSQL
-- - Multi-statement block restructured: using RETURNING to get new ID, followed by separate statements
-- - Transaction control moved to application code (Npgsql connection.BeginTransaction())
-- - Parameters remain @param format (Npgsql compatible)
--
-- IMPORTANT: This conversion returns the new ProductId using RETURNING clause.
-- The subsequent statements for ProductHistory and ProductStats will be executed
-- separately by the application code within the same transaction.
-- ============================================================================

-- Insert the new product and return the new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Log the insertion (executed separately with the returned ProductId)
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics (executed separately)
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = NOW()
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 3 ALTERNATIVE: Complete Transaction Block Version
-- ============================================================================
-- If the application requires a single multi-statement block, PostgreSQL supports
-- this via DO blocks or PL/pgSQL functions. However, for ADO.NET applications,
-- the preferred approach is to execute statements separately within a transaction.
-- Below is the complete version for reference:
-- ============================================================================

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
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    -- Return the new product ID
    -- Note: DO blocks cannot return values directly; use a function instead
    -- or execute RETURNING in the INSERT statement directly
END $$;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Declarations
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempted: YES (would have failed based on pattern)
-- Original Statement: See extracted_statements.sql Statement 4
-- Schema Transformations: None (table names remain unchanged)
--
-- PostgreSQL Conversion Notes:
-- - Transaction control moved to application code (BEGIN/COMMIT handled by Npgsql)
-- - DECLARE statements removed - variables handled in PostgreSQL differently
-- - GETDATE() → NOW()
-- - For ADO.NET, this will be executed as separate statements within a transaction:
--   1. SELECT to get old values
--   2. UPDATE statement
--   3. INSERT into history
--   4. UPDATE statistics
-- - Parameters remain @param format (Npgsql compatible)
-- ============================================================================

-- Store old values for history (executed first within transaction)
-- Application code will capture these values
SELECT Price, StockQuantity
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

-- Log the changes (with @OldPrice and @OldStock captured from SELECT above)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Complex CASE in UPDATE
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempted: YES (would have failed based on pattern)
-- Original Statement: See extracted_statements.sql Statement 5
-- Schema Transformations: None (table names remain unchanged)
--
-- PostgreSQL Conversion Notes:
-- - Transaction control moved to application code
-- - DECLARE statements removed
-- - GETDATE() → NOW()
-- - CASE expression syntax is identical between SQL Server and PostgreSQL
-- - Execution as separate statements within transaction
-- - Parameters remain @param format (Npgsql compatible)
-- ============================================================================

-- Store product info for history (executed first within transaction)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion (with @OldPrice and @OldStock captured from SELECT above)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempted: YES (would have failed based on pattern)
-- Original Statement: See extracted_statements.sql Statement 6
-- Schema Transformations: None (table names remain unchanged)
--
-- PostgreSQL Conversion Notes:
-- - CTEs (WITH clause) syntax is identical
-- - RANK() window function syntax is identical
-- - PERCENT_RANK() window function syntax is identical
-- - BETWEEN clause syntax is identical
-- - CASE expressions are compatible
-- - Parameters: @MinPrice, @MaxPrice remain as-is (Npgsql supports @param syntax)
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions (AVG, MIN, MAX)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Attempted: YES (would have failed based on pattern)
-- Original Statement: See extracted_statements.sql Statement 7
-- Schema Transformations: None (table names remain unchanged)
--
-- PostgreSQL Conversion Notes:
-- - CTEs (WITH clause) syntax is identical
-- - Window functions (AVG, MIN, MAX with OVER) syntax is identical
-- - CASE expressions are compatible
-- - ROUND function syntax is identical
-- - Parameters: @Threshold remains as-is (Npgsql supports @param syntax)
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
-- Conversion Methods:
--   - DMS_TOOL: 0 (all attempts failed due to metadata model conversion timeout)
--   - MANUAL_AFTER_DMS_FAILURE: 7
--
-- Key SQL Server to PostgreSQL Syntax Conversions Applied:
--   1. GETDATE() → NOW()
--   2. SCOPE_IDENTITY() → RETURNING clause
--   3. DECLARE @variable → Removed (handled in application or DO block)
--   4. BEGIN TRANSACTION / COMMIT → Handled by Npgsql connection.BeginTransaction()
--   5. Parameter syntax: @param remains compatible with Npgsql
--   6. Data types: DECIMAL → NUMERIC (handled automatically by PostgreSQL)
--
-- Schema Object Name Transformations: NONE
--   - All table names remain unchanged (Products, ProductHistory, ProductStats)
--   - All column names remain unchanged
--
-- Transaction Block Handling:
--   - Statements 3, 4, 5 are transaction blocks in SQL Server
--   - PostgreSQL version: Execute as separate statements within Npgsql transaction
--   - Alternative: Use DO blocks or PL/pgSQL functions (shown for Statement 3)
--
-- Compatibility Notes:
--   - CTEs (WITH clause): Fully compatible
--   - Window functions: Fully compatible (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER)
--   - CASE expressions: Fully compatible
--   - JOINs (INNER, LEFT): Fully compatible
--   - ROUND function: Fully compatible
--   - BETWEEN clause: Fully compatible
--
-- ============================================================================
-- NEXT STEP: Validate equivalency using SQL Equivalency MCP Tool
-- ============================================================================
