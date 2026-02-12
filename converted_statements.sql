-- ================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Converted from: extracted_statements.sql
-- Target Database: PostgreSQL
-- Conversion Method: MANUAL (DMS Tool Failed)
-- Total Statements: 7
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: None required - PostgreSQL supports CTEs, window functions, CASE, ROUND
--              Parameter syntax compatible (@param works in Npgsql)
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: None required - PostgreSQL supports LAG window function, CTEs
--              Parameter syntax compatible
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
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Removed DECLARE @NewProductId - PostgreSQL uses RETURNING clause
--   2. Changed BEGIN TRANSACTION to BEGIN (PostgreSQL syntax)
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause in INSERT
--   4. Changed GETDATE() to NOW() (PostgreSQL equivalent)
--   5. Removed SELECT @NewProductId - value returned via RETURNING
-- NOTE: This will need C# code changes to use ExecuteScalarAsync with RETURNING
-- ================================================================================
BEGIN;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: The RETURNING value must be captured in C# code
    -- Then used in subsequent statements
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ((SELECT currval(pg_get_serial_sequence('Products', 'ProductId'))), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Changed BEGIN TRANSACTION to BEGIN
--   2. Changed DECLARE syntax to PostgreSQL format (still supported)
--   3. Changed GETDATE() to NOW()
--   4. COMMIT remains the same
-- ================================================================================
BEGIN;
    DECLARE v_OldPrice DECIMAL(18,2);
    DECLARE v_OldStock INT;
    
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = NOW()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, NOW());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Changed BEGIN TRANSACTION to BEGIN
--   2. Changed DECLARE syntax to PostgreSQL format
--   3. Changed GETDATE() to NOW()
--   4. CASE expression remains compatible
-- ================================================================================
BEGIN;
    DECLARE v_OldPrice DECIMAL(18,2);
    DECLARE v_OldStock INT;
    
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, NOW());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
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
COMMIT;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: None required - PostgreSQL fully supports RANK, PERCENT_RANK
--              window functions, CTEs, and BETWEEN operators
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: None required - PostgreSQL supports AVG/MIN/MAX window functions
--              CTEs, CASE expressions, ROUND function
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
-- END OF CONVERTED STATEMENTS
-- ================================================================================
-- CONVERSION SUMMARY:
-- Total Statements Converted: 7
-- Method: MANUAL_AFTER_DMS_FAILURE (DMS tool experienced metadata model errors)
-- 
-- Key PostgreSQL Conversions Applied:
-- - GETDATE() → NOW()
-- - SCOPE_IDENTITY() → RETURNING clause + currval()
-- - BEGIN TRANSACTION → BEGIN
-- - DECLARE @var → DECLARE v_var (for transaction blocks)
-- - SELECT @var = value → SELECT value INTO v_var
-- - Window functions, CTEs, CASE: Compatible, no changes needed
-- 
-- Schema Object Names: No changes (Products, ProductHistory, ProductStats remain)
-- ================================================================================
