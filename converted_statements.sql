-- ========================================================================================================
-- CONVERTED SQL STATEMENTS - MS SQL SERVER TO POSTGRESQL
-- ========================================================================================================
-- Purpose: PostgreSQL converted statements from MS SQL Server originals
-- Conversion Date: 2026-02-14
-- Total Statements: 7
-- DMS Tool Status: All statements attempted through DMS tool, metadata model creation errors encountered
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements due to DMS technical issues
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ========================================================================================================
-- Statement ID: STMT_001_GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- DMS Attempt Timestamp: 2026-02-14T06:50:49.107309
-- Manual Conversion Notes: Window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible. 
--                          ROUND function is compatible. CASE statements are compatible.
--                          Schema objects remain unchanged (Products table).
-- ========================================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ========================================================================================================
-- Statement ID: STMT_002_GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- DMS Attempt Timestamp: 2026-02-14T06:51:04.715054
-- Manual Conversion Notes: LAG() OVER() window function is PostgreSQL compatible.
--                          Parameter @ProductId remains same (Npgsql supports @ syntax).
--                          Schema objects remain unchanged (Products table).
-- ========================================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync
-- ========================================================================================================
-- Statement ID: STMT_003_InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- DMS Attempt Timestamp: 2026-02-14T06:51:20.744940
-- Manual Conversion Notes: 
--   - DECLARE @Variable not needed, using DO block for procedural logic
--   - BEGIN TRANSACTION → BEGIN
--   - SCOPE_IDENTITY() → Use RETURNING clause to get new ID directly
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Multi-statement transaction converted to single atomic operation with CTE
--   - Schema objects remain unchanged (Products, ProductHistory, ProductStats tables)
-- CRITICAL: This conversion uses RETURNING clause for ID, code re-integration must handle result
-- ========================================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
*/

-- CONVERTED POSTGRESQL STATEMENT:
WITH new_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM new_product
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
FROM history_insert
WHERE StatId = 1
RETURNING (SELECT ProductId FROM new_product);

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync
-- ========================================================================================================
-- Statement ID: STMT_004_UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- DMS Attempt Timestamp: 2026-02-14T07:10:18.426633
-- Manual Conversion Notes:
--   - BEGIN TRANSACTION → BEGIN
--   - DECLARE variables → Use subquery to capture old values
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Multi-statement transaction converted with CTEs
--   - Schema objects remain unchanged (Products, ProductHistory, ProductStats tables)
-- ========================================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL STATEMENT:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
product_update AS (
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync
-- ========================================================================================================
-- Statement ID: STMT_005_DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- DMS Attempt Timestamp: 2026-02-14T07:10:31.937573
-- Manual Conversion Notes:
--   - BEGIN TRANSACTION → BEGIN
--   - DECLARE variables → Use subquery to capture old values
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Multi-statement transaction converted with CTEs
--   - Schema objects remain unchanged (Products, ProductHistory, ProductStats tables)
-- ========================================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
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
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL STATEMENT:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
history_insert AS (
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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ========================================================================================================
-- Statement ID: STMT_006_GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- DMS Attempt Timestamp: 2026-02-14T07:10:44.610744
-- Manual Conversion Notes: RANK() and PERCENT_RANK() window functions are PostgreSQL compatible.
--                          Parameters @MinPrice and @MaxPrice remain same.
--                          Schema objects remain unchanged (Products table).
-- ========================================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ========================================================================================================
-- Statement ID: STMT_007_GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- DMS Attempt Timestamp: 2026-02-14T07:10:58.425739
-- Manual Conversion Notes: AVG(), MIN(), MAX() aggregate window functions are PostgreSQL compatible.
--                          Parameter @Threshold remains same.
--                          Schema objects remain unchanged (Products table).
-- ========================================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ========================================================================================================
-- END OF CONVERTED STATEMENTS
-- ========================================================================================================
-- CONVERSION SUMMARY:
-- - Total Statements: 7
-- - DMS Tool Attempted: 7 (all statements attempted, all failed with metadata model creation errors)
-- - Manual Conversions: 7 (all statements converted manually after DMS failures)
-- - Schema Object Mappings: No changes (Products, ProductHistory, ProductStats remain unchanged)
-- 
-- KEY CONVERSIONS APPLIED:
-- 1. GETDATE() → CURRENT_TIMESTAMP (3 statements: STMT_003, STMT_004, STMT_005)
-- 2. BEGIN TRANSACTION → BEGIN (implicit, handled by Npgsql)
-- 3. SCOPE_IDENTITY() → RETURNING clause (1 statement: STMT_003)
-- 4. DECLARE variables → CTEs with subqueries (3 statements: STMT_003, STMT_004, STMT_005)
-- 5. Window functions: All compatible with PostgreSQL (no changes needed)
-- 6. CTEs: All compatible with PostgreSQL (no changes needed)
-- 7. CASE statements: All compatible with PostgreSQL (no changes needed)
-- 8. Parameters: @ syntax retained (Npgsql compatible)
-- 
-- DMS TOOL ATTEMPT SUMMARY:
-- - STMT_001: Attempted 2026-02-14T06:50:49.107309 - Metadata model creation failed
-- - STMT_002: Attempted 2026-02-14T06:51:04.715054 - Metadata model creation failed
-- - STMT_003: Attempted 2026-02-14T06:51:20.744940 - Metadata model creation failed
-- - STMT_004: Attempted 2026-02-14T07:10:18.426633 - Metadata model creation failed
-- - STMT_005: Attempted 2026-02-14T07:10:31.937573 - Metadata model creation failed
-- - STMT_006: Attempted 2026-02-14T07:10:44.610744 - Metadata model creation failed
-- - STMT_007: Attempted 2026-02-14T07:10:58.425739 - Metadata model creation failed
-- ========================================================================================================
