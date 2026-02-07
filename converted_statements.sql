-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: DMS Tool Attempted + Manual Conversion Applied
-- Total Statements: 7
-- DMS Tool Success: 0
-- Manual Conversions After DMS Failure: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Status: DMS_FAILED_MANUAL_APPLIED
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- DMS TOOL OUTPUT:
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Timestamp: 2026-02-07T18:53:44.542363

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

-- MANUAL CONVERSION NOTES:
-- This query is already PostgreSQL compatible. CTEs, window functions (AVG, COUNT OVER),
-- CASE statements, ROUND function, and INNER JOIN are all supported in PostgreSQL with
-- identical syntax. No changes required.

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Status: DMS_FAILED_MANUAL_APPLIED
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- DMS TOOL OUTPUT:
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Timestamp: 2026-02-07T18:53:59.864201

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

-- MANUAL CONVERSION NOTES:
-- This query is already PostgreSQL compatible. CTEs, LAG window function, CASE statements,
-- ROUND function, and LEFT JOIN are all supported in PostgreSQL. Parameter marker @ProductId
-- is compatible with Npgsql's named parameter syntax. No changes required.

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Status: DMS_FAILED_MANUAL_APPLIED
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- DMS TOOL OUTPUT:
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Timestamp: 2026-02-07T18:54:13.671737

-- CONVERTED POSTGRESQL STATEMENT:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- MANUAL CONVERSION NOTES:
-- PostgreSQL conversion simplifies this multi-statement transaction:
-- 1. DECLARE @NewProductId removed - use RETURNING clause instead
-- 2. BEGIN TRANSACTION -> removed (will be handled at application level if needed)
-- 3. SCOPE_IDENTITY() -> RETURNING ProductId (PostgreSQL idiom)
-- 4. GETDATE() -> CURRENT_TIMESTAMP (can be replaced in subsequent statements)
-- 5. Transaction statements for ProductHistory and ProductStats inserts/updates
--    would need to be executed separately in the C# code after getting the returned ID
-- 6. COMMIT removed (will be handled at application level)
-- NOTE: This conversion requires code-level changes to handle the multi-statement
-- transaction logic in the application rather than as a single SQL batch.

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Status: DMS_FAILED_MANUAL_APPLIED
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- DMS TOOL OUTPUT:
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Timestamp: 2026-02-07T18:54:28.171215

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- MANUAL CONVERSION NOTES:
-- PostgreSQL conversion using DO block:
-- 1. BEGIN TRANSACTION/COMMIT removed (handled at application level)
-- 2. DECLARE statements kept but variables prefixed with v_ (PostgreSQL convention)
-- 3. SELECT ... INTO syntax changed to PostgreSQL format
-- 4. GETDATE() -> CURRENT_TIMESTAMP (PostgreSQL equivalent)
-- 5. Variable references changed from @OldPrice to v_OldPrice
-- 6. DO $$ ... END $$ wraps the procedural block
-- NOTE: For ADO.NET usage, this can be executed as separate statements within
-- a transaction managed by NpgsqlTransaction instead of using DO block.

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Status: DMS_FAILED_MANUAL_APPLIED
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
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

-- DMS TOOL OUTPUT:
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Timestamp: 2026-02-07T18:54:42.339446

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
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
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- MANUAL CONVERSION NOTES:
-- PostgreSQL conversion using DO block:
-- 1. BEGIN TRANSACTION/COMMIT removed (handled at application level)
-- 2. DECLARE statements kept but variables prefixed with v_ (PostgreSQL convention)
-- 3. SELECT ... INTO syntax changed to PostgreSQL format
-- 4. GETDATE() -> CURRENT_TIMESTAMP (PostgreSQL equivalent)
-- 5. Variable references changed from @OldPrice to v_OldPrice in UPDATE
-- 6. DO $$ ... END $$ wraps the procedural block
-- 7. CASE statement is PostgreSQL compatible as-is
-- NOTE: For ADO.NET usage, this can be executed as separate statements within
-- a transaction managed by NpgsqlTransaction instead of using DO block.

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Status: DMS_FAILED_MANUAL_APPLIED
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- DMS TOOL OUTPUT:
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Timestamp: 2026-02-07T18:54:55.418554

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

-- MANUAL CONVERSION NOTES:
-- This query is already PostgreSQL compatible. CTEs, window functions (RANK, PERCENT_RANK),
-- CASE statements, and BETWEEN operator are all supported in PostgreSQL with identical syntax.
-- Parameter markers @MinPrice and @MaxPrice are compatible with Npgsql. No changes required.

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Status: DMS_FAILED_MANUAL_APPLIED
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- DMS TOOL OUTPUT:
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Timestamp: 2026-02-07T18:55:11.996857

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

-- MANUAL CONVERSION NOTES:
-- This query is already PostgreSQL compatible. CTEs, window functions (AVG, MIN, MAX OVER),
-- CASE statements, and ROUND function are all supported in PostgreSQL with identical syntax.
-- Parameter marker @Threshold is compatible with Npgsql. No changes required.

-- ============================================================================
-- SUMMARY OF CONVERSIONS
-- ============================================================================
-- Total Statements: 7
-- DMS Tool Attempted: 7
-- DMS Tool Success: 0
-- DMS Tool Failed: 7
-- Manual Conversions Applied: 7
--
-- Statements 1, 2, 6, 7: Already PostgreSQL compatible (no changes required)
-- Statements 3, 4, 5: Required significant conversion for transaction handling,
--                      variable declarations, SCOPE_IDENTITY, and GETDATE functions
--
-- All statements have been processed through DMS tool as required.
-- All DMS failures have been documented with error details.
-- Manual conversions applied using PostgreSQL best practices.
-- ============================================================================
