-- ============================================================================
-- SQL Statement Conversion Catalog - PostgreSQL
-- Source: extracted_statements.sql
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original: MS SQL Server with CTE and window functions
-- PostgreSQL Notes: Window functions compatible, ROUND precision same
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original: MS SQL Server with CTE, LAG window function, LEFT JOIN
-- PostgreSQL Notes: LAG function compatible, parameter @ProductId kept
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original: MS SQL Server transaction with SCOPE_IDENTITY(), GETDATE()
-- PostgreSQL Changes:
-- - Removed DECLARE (not needed outside PL/pgSQL function)
-- - Changed SCOPE_IDENTITY() to use RETURNING clause
-- - Changed GETDATE() to CURRENT_TIMESTAMP
-- - Changed SET to variable assignment pattern
-- - PostgreSQL transactions: BEGIN/COMMIT same syntax
-- ============================================================================

BEGIN;
    -- Insert the new product and get the ID
    INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
    VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
    RETURNING ProductId;
    
    -- Note: In ADO.NET code, capture the returned ProductId and use it in subsequent statements
    -- For a single-statement context, this would need to be restructured or use DO block
    
    -- Log the insertion (assuming @NewProductId available from RETURNING)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (LASTVAL(), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- Alternative implementation using RETURNING and single variable:
-- This approach uses CTE to chain the operations
WITH new_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
    VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM new_product
    RETURNING ProductId
),
stats_update AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM new_product;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original: MS SQL Server transaction with DECLARE, SELECT into variables
-- PostgreSQL Changes:
-- - Removed variable declarations (using subqueries instead)
-- - Changed GETDATE() to CURRENT_TIMESTAMP
-- - BEGIN TRANSACTION → BEGIN
-- ============================================================================

BEGIN;
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes (using subquery to get old values)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT 
        @ProductId, 
        'UPDATE', 
        Price, 
        @Price, 
        StockQuantity, 
        @StockQuantity, 
        CURRENT_TIMESTAMP
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update product statistics (using subquery for old price)
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT Price FROM Products WHERE ProductId = @ProductId) + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- Alternative using WITH for old values capture:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, CURRENT_TIMESTAMP
FROM old_values;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original: MS SQL Server transaction with DECLARE, SELECT into variables
-- PostgreSQL Changes:
-- - Removed variable declarations (using subquery)
-- - Changed GETDATE() to CURRENT_TIMESTAMP
-- - BEGIN TRANSACTION → BEGIN
-- ============================================================================

BEGIN;
    -- Log the deletion (capture values before delete)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT 
        ProductId, 
        'DELETE', 
        Price, 
        NULL, 
        StockQuantity, 
        NULL, 
        CURRENT_TIMESTAMP
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Store old price for stats update
    WITH old_product AS (
        SELECT Price as OldPrice FROM Products WHERE ProductId = @ProductId
    )
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
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- Better approach with CTE to capture old values before delete:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
history_log AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING ProductId
),
product_delete AS (
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
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original: MS SQL Server with CTE, RANK(), PERCENT_RANK()
-- PostgreSQL Notes: Window functions fully compatible
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original: MS SQL Server with CTE and multiple window functions
-- PostgreSQL Notes: Window functions fully compatible
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
-- Successfully Converted by DMS: 0
-- Manually Converted After DMS Failure: 7
--
-- Key PostgreSQL Conversions Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP or NOW()
-- 2. SCOPE_IDENTITY() → RETURNING clause or LASTVAL()
-- 3. BEGIN TRANSACTION → BEGIN
-- 4. DECLARE variables → Eliminated or used CTEs/subqueries
-- 5. SELECT @var = value → Use CTEs or RETURNING clause
-- 6. Named parameters @ParamName → Kept for Npgsql compatibility
-- 7. Window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) → Direct compatibility
-- 8. CTEs (WITH clause) → Direct compatibility
-- 9. DECIMAL(18,2) → Compatible with PostgreSQL NUMERIC
-- 10. Transaction structure adapted for PostgreSQL multi-statement handling
-- ============================================================================
