-- ==================================================================================
-- CONVERTED SQL STATEMENTS - MS SQL SERVER TO POSTGRESQL
-- ==================================================================================
-- Conversion Date: 2025-01-31
-- Tool: dms-mcp____statement_conversion_tool (with manual fallback)
-- Total Statements: 7
-- Successfully Converted by DMS: 0
-- Manually Converted After DMS Failure: 7
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1 of 7: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR (Metadata model conversion timeout)
-- Changes Required: NONE (PostgreSQL compatible)
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2 of 7: GetProductByIdAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR (Metadata model creation timeout)
-- Changes Required: NONE (PostgreSQL compatible)
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3 of 7: InsertProductAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR (Metadata model creation timeout)
-- Changes Required: GETDATE() → CURRENT_TIMESTAMP, SCOPE_IDENTITY() → RETURNING
-- ==================================================================================

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
-- Note: PostgreSQL uses RETURNING clause instead of SCOPE_IDENTITY()
-- The application code will need to capture the returned ProductId
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The following statements will be executed after capturing the returned ProductId
-- in the application code (C#). This is a structural change from the single batch
-- transaction to multiple statement executions within a transaction context.

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 4 of 7: UpdateProductAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR (Metadata model conversion timeout)
-- Changes Required: GETDATE() → CURRENT_TIMESTAMP, BEGIN TRANSACTION → BEGIN
-- ==================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: Transaction management (BEGIN/COMMIT) will be handled in C# code
-- PostgreSQL supports variable declarations but syntax is slightly different
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

-- ==================================================================================
-- STATEMENT 5 of 7: DeleteProductAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR (Metadata model creation timeout)
-- Changes Required: GETDATE() → CURRENT_TIMESTAMP, BEGIN TRANSACTION → BEGIN
-- ==================================================================================

-- ORIGINAL MS SQL STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: Transaction management (BEGIN/COMMIT) will be handled in C# code
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

-- ==================================================================================
-- STATEMENT 6 of 7: GetProductsByPriceRangeAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR (Metadata model creation timeout)
-- Changes Required: NONE (PostgreSQL compatible)
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7 of 7: GetLowStockProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR (Metadata model conversion timeout)
-- Changes Required: NONE (PostgreSQL compatible)
-- ==================================================================================

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

-- ==================================================================================
-- CONVERSION SUMMARY
-- ==================================================================================
-- Total Statements Processed: 7
-- Successfully Converted by DMS: 0
-- Manually Converted After DMS Failure: 7
-- Requiring Manual Review: 2 (Statements 3, 4, 5 - transaction structure changes)
-- Failed Conversions: 0
--
-- Key Transformations Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
-- 2. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
-- 3. BEGIN TRANSACTION → Transaction handled in C# code (Statements 3, 4, 5)
-- 4. DECLARE @Variable → DO $$ DECLARE v_Variable (Statements 4, 5)
-- 5. Window functions: Compatible, no changes (Statements 1, 2, 6, 7)
-- 6. CTEs: Compatible, no changes (All statements with WITH)
-- 7. CASE expressions: Compatible, no changes (All statements with CASE)
-- 8. ROUND function: Compatible, no changes (Statements 1, 2, 7)
--
-- Schema Object Name Changes: NONE
-- All table references (Products, ProductHistory, ProductStats) remain unchanged
--
-- Notes for Code Integration:
-- - Statements 1, 2, 6, 7: Direct replacement, no code structure changes
-- - Statement 3: Requires C# code changes to handle RETURNING clause
-- - Statements 4, 5: May require refactoring to multiple SQL commands or use
--   of stored procedures if DO $$ blocks don't work well with parameterized queries
-- ==================================================================================
