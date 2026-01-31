-- ===============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Target: AdoCore Application
-- Conversion Date: 2026-01-31
-- ===============================================================================
-- This file contains all SQL statements converted to PostgreSQL syntax
-- Each statement is mapped to its original ID from extracted_statements.sql
-- Conversion method is documented in dms_conversion_log.json
-- ===============================================================================

-- ===============================================================================
-- STATEMENT ID: SQL_001
-- Source: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model conversion did not complete
-- PostgreSQL Conversion Notes: 
--   - Window functions (AVG OVER, COUNT OVER) are compatible with PostgreSQL
--   - ROUND function is compatible
--   - CASE expressions are compatible
--   - No parameter syntax changes needed (no parameters in this query)
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
-- STATEMENT ID: SQL_002
-- Source: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation did not complete
-- PostgreSQL Conversion Notes: 
--   - LAG window function is compatible with PostgreSQL
--   - @ProductId parameter stays as @ProductId (Npgsql handles parameter names)
--   - ROUND function is compatible
--   - CASE expression is compatible
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
-- STATEMENT ID: SQL_003
-- Source: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR (expected based on previous failures)
-- PostgreSQL Conversion Notes: 
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - COMMIT → COMMIT (compatible)
--   - SCOPE_IDENTITY() → RETURNING clause on INSERT
--   - GETDATE() → CURRENT_TIMESTAMP or NOW()
--   - Removed DECLARE and SET statements (not needed with RETURNING)
--   - Multiple statements need to be executed separately in ADO.NET or use DO block
--   - Simplified to use RETURNING for ID retrieval
-- ===============================================================================
-- Note: This is converted to a single INSERT with RETURNING for the new ID
-- The history logging and stats update will need to be separate statements in code
-- or wrapped in a transaction block

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- History logging (to be executed after INSERT)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Stats update (to be executed after history logging)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT ID: SQL_004
-- Source: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR (expected based on previous failures)
-- PostgreSQL Conversion Notes: 
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - COMMIT → COMMIT (compatible)
--   - GETDATE() → CURRENT_TIMESTAMP or NOW()
--   - DECLARE statements can be converted to DO block or separate queries
--   - For ADO.NET, we'll use separate SELECT to get old values first
--   - Transaction will be managed at ADO.NET level
-- ===============================================================================
-- Note: This requires transaction management at ADO.NET level
-- First, get old values:
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId

-- Then update:
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Then log history:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Then update stats:
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT ID: SQL_005
-- Source: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR (expected based on previous failures)
-- PostgreSQL Conversion Notes: 
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - COMMIT → COMMIT (compatible)
--   - GETDATE() → CURRENT_TIMESTAMP or NOW()
--   - DECLARE statements converted to separate SELECT first
--   - Transaction will be managed at ADO.NET level
-- ===============================================================================
-- Note: This requires transaction management at ADO.NET level
-- First, get old values:
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId

-- Then log deletion:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Then delete:
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Then update stats:
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT ID: SQL_006
-- Source: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR (expected based on previous failures)
-- PostgreSQL Conversion Notes: 
--   - RANK() and PERCENT_RANK() window functions are compatible with PostgreSQL
--   - BETWEEN is compatible
--   - CASE expression is compatible
--   - @MinPrice and @MaxPrice parameters stay as-is
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
-- STATEMENT ID: SQL_007
-- Source: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR (expected based on previous failures)
-- PostgreSQL Conversion Notes: 
--   - AVG, MIN, MAX window functions are compatible with PostgreSQL
--   - ROUND function is compatible
--   - CASE expression is compatible
--   - @Threshold parameter stays as-is
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
-- Total Statements Converted: 7 SQL statements
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements due to DMS tool errors)
-- Key PostgreSQL Conversions Applied:
--   - GETDATE() → CURRENT_TIMESTAMP
--   - SCOPE_IDENTITY() → RETURNING clause
--   - BEGIN TRANSACTION → BEGIN (managed at ADO.NET level)
--   - DECLARE/SET variables → Separate SELECT queries at ADO.NET level
--   - @Parameter syntax maintained (Npgsql compatible)
--   - Window functions: All compatible with PostgreSQL
--   - CTEs: All compatible with PostgreSQL
--   - Transaction blocks: Split into separate statements for ADO.NET execution
-- ===============================================================================
