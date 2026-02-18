-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Compatible
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- This file contains all SQL statements converted from SQL Server T-SQL
-- to PostgreSQL syntax. Due to DMS tool errors, all conversions were
-- performed manually following PostgreSQL best practices.
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ============================================================================
-- Source: Statement 1 from extracted_statements.sql
-- Conversion Method: MANUAL (DMS tool failed with metadata model error)
-- PostgreSQL Changes:
--   - CTE and window functions are compatible with PostgreSQL
--   - ROUND function syntax remains the same
--   - CASE statements remain the same
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
-- Source: Statement 2 from extracted_statements.sql
-- Conversion Method: MANUAL (DMS tool failed with metadata model error)
-- PostgreSQL Changes:
--   - Parameter syntax changed from @ProductId to $1
--   - LAG window function is compatible with PostgreSQL
--   - ROUND function syntax remains the same
-- ============================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- ============================================================================
-- Source: Statement 3 from extracted_statements.sql
-- Conversion Method: MANUAL (DMS tool failed with metadata model error)
-- PostgreSQL Changes:
--   - Removed DECLARE statement (not needed with RETURNING)
--   - Removed BEGIN TRANSACTION/COMMIT (will be handled at connection level)
--   - Changed SCOPE_IDENTITY() to RETURNING clause
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Changed parameter syntax from @Name to $1, @Description to $2, etc.
--   - Modified to return the new ID using RETURNING
-- NOTE: This needs to be executed as multiple statements in a transaction
-- ============================================================================

-- First INSERT with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;

-- Second INSERT (uses the returned ProductId from first statement)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);

-- UPDATE statement
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ============================================================================
-- Source: Statement 4 from extracted_statements.sql
-- Conversion Method: MANUAL (DMS tool failed with metadata model error)
-- PostgreSQL Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (will be handled at connection level)
--   - Removed DECLARE statements, using CTE instead for old values
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Changed parameter syntax from @ProductId to $1, @Name to $2, etc.
-- NOTE: This needs to be executed as multiple statements in a transaction
-- ============================================================================

-- Get old values (can be done in a CTE or separate query)
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
)
-- Update the product
UPDATE Products
SET 
    Name = $2,
    Description = $3,
    Price = $4,
    StockQuantity = $5,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $1;

-- Insert history record (needs old values from previous query)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP);

-- Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ============================================================================
-- Source: Statement 5 from extracted_statements.sql
-- Conversion Method: MANUAL (DMS tool failed with metadata model error)
-- PostgreSQL Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (will be handled at connection level)
--   - Removed DECLARE statements, using CTE or separate query instead
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Changed parameter syntax from @ProductId to $1
-- NOTE: This needs to be executed as multiple statements in a transaction
-- ============================================================================

-- Get old values before deletion
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
)
SELECT OldPrice, OldStock FROM OldValues;

-- Insert history record
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM Products 
WHERE ProductId = $1;

-- Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ============================================================================
-- Source: Statement 6 from extracted_statements.sql
-- Conversion Method: MANUAL (DMS tool failed with metadata model error)
-- PostgreSQL Changes:
--   - Changed parameter syntax from @MinPrice to $1, @MaxPrice to $2
--   - RANK() and PERCENT_RANK() window functions are compatible with PostgreSQL
--   - CASE statement remains the same
-- ============================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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
-- Source: Statement 7 from extracted_statements.sql
-- Conversion Method: MANUAL (DMS tool failed with metadata model error)
-- PostgreSQL Changes:
--   - Changed parameter syntax from @Threshold to $1
--   - Aggregate window functions (AVG, MIN, MAX) are compatible with PostgreSQL
--   - ROUND function syntax remains the same
--   - CASE statement remains the same
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
-- Summary of Conversions:
-- Total Statements Converted: 7
-- All conversions performed manually due to DMS tool metadata model errors
--
-- Key PostgreSQL Conversions Applied:
-- 1. Parameter Syntax: @ParamName → $1, $2, $3, etc. (positional parameters)
-- 2. SCOPE_IDENTITY() → RETURNING clause in INSERT statements
-- 3. GETDATE() → CURRENT_TIMESTAMP
-- 4. BEGIN TRANSACTION/COMMIT → Removed (handled at application level)
-- 5. DECLARE statements → Removed or replaced with CTEs where needed
-- 6. Window functions, CTEs, CASE statements → Compatible as-is
--
-- Note: Transaction handling needs to be implemented at the application level
-- using Npgsql transaction objects instead of T-SQL transaction syntax.
-- ============================================================================
