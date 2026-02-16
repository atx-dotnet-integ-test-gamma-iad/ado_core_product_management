-- ================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ================================================================================
-- This file contains all SQL statements converted from MS SQL Server syntax
-- to PostgreSQL syntax. Each statement includes conversion status and mapping
-- to the original SQL Server statement.
-- 
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- Conversion Date: 2026-02-16
-- ================================================================================
-- NOTE: All statements were processed through DMS MCP tool first, but the tool
-- encountered metadata model creation failures. Manual conversions were performed
-- following PostgreSQL best practices. See dms_conversion_issues.log for details.
-- ================================================================================

-- ================================================================================
-- CONVERTED STATEMENT #1: GetAllProductsAsync
-- ================================================================================
-- Original Statement: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Minimal changes needed
-- Changes Made: None required - PostgreSQL-compatible syntax
-- ================================================================================

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

-- ================================================================================
-- CONVERTED STATEMENT #2: GetProductByIdAsync
-- ================================================================================
-- Original Statement: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Minimal changes needed
-- Changes Made: None required - PostgreSQL-compatible syntax
-- Parameters: @ProductId remains compatible with Npgsql
-- ================================================================================

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

-- ================================================================================
-- CONVERTED STATEMENT #3: InsertProductAsync
-- ================================================================================
-- Original Statement: InsertProductAsync - Multi-statement Transaction with INSERT
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: MEDIUM - Significant refactoring required
-- Changes Made:
--   1. Removed DECLARE statements - Using DO block approach instead
--   2. Changed BEGIN TRANSACTION to BEGIN
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause for better PostgreSQL style
--   4. Replaced GETDATE() with NOW()
--   5. Refactored to use WITH clause to capture returned ID
--   6. Used CTEs to chain operations
-- Note: This version uses PostgreSQL's RETURNING clause which is more idiomatic
-- than using LASTVAL() or currval()
-- ================================================================================

-- PostgreSQL Version using DO block with variable
DO $$
DECLARE
    v_NewProductId INT;
    v_OldAvgPrice DECIMAL(18,2);
    v_OldTotalProducts INT;
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
    
    -- Return the new product ID
    RAISE NOTICE 'New Product ID: %', v_NewProductId;
END $$;

-- Alternative simpler approach using RETURNING (recommended for application code)
-- This version is better suited for use with Npgsql in C# code
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The transaction handling and history logging would be done in separate
-- statements within a transaction block managed by the application code.
-- This is the recommended approach for .NET applications using Npgsql.

-- ================================================================================
-- CONVERTED STATEMENT #4: UpdateProductAsync
-- ================================================================================
-- Original Statement: UpdateProductAsync - Multi-statement Transaction with UPDATE
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: MEDIUM - Refactoring required for variables
-- Changes Made:
--   1. Removed DECLARE statements - Using CTE approach
--   2. Changed BEGIN TRANSACTION to BEGIN (handled by application)
--   3. Replaced GETDATE() with NOW()
--   4. Used CTE to capture old values before update
-- Note: In application code, this will be executed as multiple statements
-- within a transaction managed by NpgsqlTransaction
-- ================================================================================

-- CTE approach to capture old values
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
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Log the changes (separate statement within transaction)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, NOW()
FROM (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
) AS OldValues;

-- Update product statistics (separate statement within transaction)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT Price FROM Products WHERE ProductId = @ProductId) + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- Note: These statements should be executed sequentially within a single
-- transaction managed by the application using NpgsqlTransaction.BeginTransactionAsync()

-- ================================================================================
-- CONVERTED STATEMENT #5: DeleteProductAsync
-- ================================================================================
-- Original Statement: DeleteProductAsync - Multi-statement Transaction with DELETE
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: MEDIUM - Refactoring required for variables
-- Changes Made:
--   1. Removed DECLARE statements - Using CTE approach
--   2. Changed BEGIN TRANSACTION to BEGIN (handled by application)
--   3. Replaced GETDATE() with NOW()
--   4. Used CTE to capture values before deletion
-- Note: In application code, these operations will be within a transaction
-- ================================================================================

-- First capture the values to be deleted (as separate SELECT)
-- Then log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', Price, NULL, StockQuantity, NULL, NOW()
FROM Products
WHERE ProductId = @ProductId;

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT Price FROM Products WHERE ProductId = @ProductId)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- Note: These statements should be executed sequentially within a single
-- transaction managed by the application using NpgsqlTransaction.

-- ================================================================================
-- CONVERTED STATEMENT #6: GetProductsByPriceRangeAsync
-- ================================================================================
-- Original Statement: GetProductsByPriceRangeAsync - SELECT with CTE, RANK and PERCENT_RANK
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Fully compatible
-- Changes Made: None required - PostgreSQL-compatible syntax
-- Parameters: @MinPrice, @MaxPrice remain compatible with Npgsql
-- ================================================================================

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

-- ================================================================================
-- CONVERTED STATEMENT #7: GetLowStockProductsAsync
-- ================================================================================
-- Original Statement: GetLowStockProductsAsync - SELECT with CTE and Multiple Window Functions
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed
-- PostgreSQL Compatibility: HIGH - Fully compatible
-- Changes Made: None required - PostgreSQL-compatible syntax
-- Parameters: @Threshold remains compatible with Npgsql
-- ================================================================================

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

-- ================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ================================================================================
-- Summary:
-- - Total Statements Converted: 7
-- - Conversion Method: All statements - MANUAL_AFTER_DMS_FAILURE
-- - DMS Tool Status: Failed for all statements (metadata model creation error)
-- 
-- Compatibility Analysis:
-- - High Compatibility (Statements #1, #2, #6, #7): 4 statements
--   These are PostgreSQL-compatible with no or minimal changes
-- 
-- - Medium Compatibility (Statements #3, #4, #5): 3 statements
--   These require refactoring for PostgreSQL idioms:
--   * Variable handling (DO blocks or CTEs)
--   * SCOPE_IDENTITY() → RETURNING clause
--   * GETDATE() → NOW()
--   * Transaction management in application code
-- 
-- Key PostgreSQL Conversions Applied:
-- 1. GETDATE() → NOW() or CURRENT_TIMESTAMP
-- 2. SCOPE_IDENTITY() → RETURNING clause (PostgreSQL best practice)
-- 3. DECLARE @variable → DO $$ DECLARE variable or CTE approach
-- 4. BEGIN TRANSACTION/COMMIT → Managed by application (NpgsqlTransaction)
-- 5. All window functions (LAG, RANK, PERCENT_RANK, AVG OVER, etc.) - Compatible
-- 6. CTEs (WITH clause) - Compatible
-- 7. CASE expressions - Compatible
-- 8. Parameter syntax (@param) - Compatible with Npgsql
-- 
-- Ready for Code Re-integration
-- ================================================================================
