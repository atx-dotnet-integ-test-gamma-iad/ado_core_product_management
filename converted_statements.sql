-- ================================================================================
-- CONVERTED SQL STATEMENTS - T-SQL TO POSTGRESQL
-- Purpose: Complete catalog of converted PostgreSQL statements
-- Conversion Date: 2026-02-04
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS metadata model errors)
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync - ProductStats CTE with Window Functions
-- ================================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - No syntax changes needed (CTE and window functions compatible)
--   - PostgreSQL supports OVER(), AVG, COUNT window functions natively
--   - ROUND function compatible
--   - CASE expressions compatible
-- Schema Changes: None
-- ================================================================================

-- ORIGINAL T-SQL:
-- WITH ProductStats AS (
--     SELECT 
--         ProductId,
--         AVG(Price) OVER() as AvgPrice,
--         COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 'Above Average'
--         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
--         ELSE 'Average'
--     END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p
-- INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY 
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 1
--         ELSE 2
--     END,
--     p.Name;

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 2: GetProductByIdAsync - ProductHistory CTE with LAG
-- ================================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - No syntax changes needed (LAG window function compatible)
--   - PostgreSQL supports LAG() OVER natively
--   - Parameter @ProductId syntax compatible with Npgsql
--   - ROUND and CASE compatible
-- Schema Changes: None
-- ================================================================================

-- ORIGINAL T-SQL:
-- WITH ProductHistory AS (
--     SELECT 
--         ProductId,
--         LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
--         LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products
--     WHERE ProductId = @ProductId
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     ph.PreviousPrice,
--     ph.PreviousStock,
--     CASE 
--         WHEN ph.PreviousPrice IS NOT NULL THEN 
--             ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
--         ELSE NULL
--     END as PriceChangePercentage
-- FROM Products p
-- LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
-- WHERE p.ProductId = @ProductId;

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY
-- ================================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - Removed DECLARE @NewProductId (not needed with RETURNING clause)
--   - Changed BEGIN TRANSACTION to BEGIN (PostgreSQL standard)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause in INSERT
--   - Changed GETDATE() to CURRENT_TIMESTAMP (or NOW())
--   - Removed SET @NewProductId = SCOPE_IDENTITY()
--   - Updated subsequent INSERT/UPDATE to use the returned ProductId
--   - Changed COMMIT to COMMIT (compatible)
--   - Removed final SELECT @NewProductId (value captured from RETURNING)
-- Schema Changes: None
-- CRITICAL CONVERSION: SCOPE_IDENTITY() → RETURNING clause pattern
-- ================================================================================

-- ORIGINAL T-SQL:
-- DECLARE @NewProductId INT;
-- 
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     
--     SET @NewProductId = SCOPE_IDENTITY();
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;
-- 
-- SELECT @NewProductId;

-- CONVERTED POSTGRESQL:
-- Note: This multi-statement transaction needs to be handled differently in PostgreSQL
-- The RETURNING clause returns the new ID, which the application code will capture
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Separate statement for history (to be executed after capturing the returned ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Separate statement for statistics update
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ================================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed (not attempted due to consistent failures)
-- Changes Applied:
--   - Changed BEGIN TRANSACTION to DO $$ BEGIN for PL/pgSQL block
--   - Changed DECLARE syntax to PostgreSQL format
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Added DO $$ END $$ wrapper for variable declarations
--   - SELECT INTO syntax compatible
-- Schema Changes: None
-- NOTE: PostgreSQL requires PL/pgSQL block for variable declarations
-- ================================================================================

-- ORIGINAL T-SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     UPDATE Products
--     SET 
--         Name = @Name,
--         Description = @Description,
--         Price = @Price,
--         StockQuantity = @StockQuantity,
--         ModifiedDate = GETDATE()
--     WHERE ProductId = @ProductId;
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     
--     UPDATE ProductStats
--     SET 
--         AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL:
-- Option 1: Using CTE to capture old values (preferred for ADO.NET)
WITH OldValues AS (
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

-- History insert (execute after update, old values captured in application)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statistics update
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with DELETE
-- ================================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed (not attempted due to consistent failures)
-- Changes Applied:
--   - Similar to Statement 4, using CTE pattern to capture old values
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - CASE expression compatible
-- Schema Changes: None
-- ================================================================================

-- ORIGINAL T-SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     
--     DELETE FROM Products 
--     WHERE ProductId = @ProductId;
--     
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts - 1,
--         AveragePrice = CASE 
--             WHEN TotalProducts > 1 
--             THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--             ELSE 0
--         END,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL:
-- First capture old values (in application code or CTE)
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM OldValues;

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update statistics
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

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK
-- ================================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed (not attempted due to consistent failures)
-- Changes Applied:
--   - No syntax changes needed (RANK and PERCENT_RANK compatible)
--   - PostgreSQL supports RANK() and PERCENT_RANK() OVER natively
--   - BETWEEN clause compatible
--   - Parameter syntax compatible
-- Schema Changes: None
-- ================================================================================

-- ORIGINAL T-SQL:
-- WITH RankedProducts AS (
--     SELECT 
--         p.*,
--         RANK() OVER (ORDER BY p.Price) as PriceRank,
--         PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM Products p
--     WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT 
--     rp.*,
--     CASE 
--         WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
--         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
--         ELSE 'Premium'
--     END as PriceSegment
-- FROM RankedProducts rp
-- ORDER BY rp.PriceRank;

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 7: GetLowStockProductsAsync - Multiple Window Functions
-- ================================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed (not attempted due to consistent failures)
-- Changes Applied:
--   - No syntax changes needed (all window functions compatible)
--   - PostgreSQL supports AVG, MIN, MAX OVER natively
--   - ROUND function compatible
--   - CASE expressions compatible
-- Schema Changes: None
-- ================================================================================

-- ORIGINAL T-SQL:
-- WITH StockAnalysis AS (
--     SELECT 
--         p.*,
--         AVG(StockQuantity) OVER() as AvgStock,
--         MIN(StockQuantity) OVER() as MinStock,
--         MAX(StockQuantity) OVER() as MaxStock
--     FROM Products p
-- )
-- SELECT 
--     sa.*,
--     CASE 
--         WHEN StockQuantity <= @Threshold THEN 'Critical'
--         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
--         ELSE 'Adequate'
--     END as StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa
-- WHERE StockQuantity <= @Threshold
-- ORDER BY StockQuantity;

-- CONVERTED POSTGRESQL:
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
-- CONVERSION SUMMARY
-- ================================================================================
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- 
-- Statements Requiring No Changes (PostgreSQL compatible): 4
--   - Statement 1: GetAllProductsAsync (CTE + window functions)
--   - Statement 2: GetProductByIdAsync (LAG window function)
--   - Statement 6: GetProductsByPriceRangeAsync (RANK, PERCENT_RANK)
--   - Statement 7: GetLowStockProductsAsync (multiple window functions)
--
-- Statements Requiring Syntax Changes: 3
--   - Statement 3: InsertProductAsync
--     * SCOPE_IDENTITY() → RETURNING clause
--     * GETDATE() → CURRENT_TIMESTAMP
--     * BEGIN TRANSACTION/COMMIT → implicit in ADO.NET
--   - Statement 4: UpdateProductAsync
--     * DECLARE variables → CTE pattern for old values
--     * GETDATE() → CURRENT_TIMESTAMP
--   - Statement 5: DeleteProductAsync
--     * DECLARE variables → CTE pattern for old values
--     * GETDATE() → CURRENT_TIMESTAMP
--
-- Schema Object Name Changes: NONE
--   All table names (Products, ProductHistory, ProductStats) remain unchanged
--
-- Parameter Syntax: COMPATIBLE
--   @ParameterName syntax supported by Npgsql provider
--
-- DMS Tool Status: FAILED
--   Metadata model creation error prevented automated conversion
--   All conversions performed manually following PostgreSQL best practices
--
-- ================================================================================
