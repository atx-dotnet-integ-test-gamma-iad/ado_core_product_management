-- ================================================================================
-- CONVERTED SQL STATEMENTS - MS SQL SERVER TO POSTGRESQL
-- Microsoft SQL Server to PostgreSQL Migration
-- DMS Tool Status: All conversions failed - Manual conversion applied
-- Total Statements: 7
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ================================================================================
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- DMS Timestamp: 2026-01-21T06:21:08.865148
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ================================================================================

-- ORIGINAL MS SQL:
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
    p.Name
*/

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

-- Conversion Notes: 
-- This query is already PostgreSQL compatible. Window functions, CTEs, and CASE 
-- expressions work identically in PostgreSQL. No changes required.

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ================================================================================
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- DMS Timestamp: 2026-01-21T06:24:30.195940
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ================================================================================

-- ORIGINAL MS SQL:
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
WHERE p.ProductId = @ProductId
*/

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

-- Conversion Notes:
-- LAG window function is fully supported in PostgreSQL. Parameter @ProductId can be
-- used as-is with Npgsql's named parameter support. No changes required.

-- ================================================================================
-- STATEMENT 3: InsertProductAsync
-- ================================================================================
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"}
-- DMS Timestamp: 2026-01-21T06:25:18.184879
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ================================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
-- Note: This conversion uses PostgreSQL's RETURNING clause instead of SCOPE_IDENTITY()
-- The multi-statement transaction needs to be handled differently in ADO.NET with Npgsql

DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product and capture the ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    -- Return the new product ID
    RAISE NOTICE 'NewProductId: %', v_NewProductId;
END $$;

-- ALTERNATE CONVERSION (Better for ADO.NET):
-- Since ADO.NET transactions are handled at the connection level, convert to separate statements:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then in code, capture the returned ProductId and use it for subsequent statements:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion Notes:
-- Key changes:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT statement
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. BEGIN TRANSACTION/COMMIT → Handled by NpgsqlConnection.BeginTransaction()
-- 4. DECLARE @var → Not needed in code, use RETURNING instead
-- 5. Transaction management moved to application code level

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync
-- ================================================================================
-- DMS Tool Status: Not attempted (learned from previous failures)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ================================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
-- Store old values for history (using CTE to capture in one query)
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
WHERE ProductId = @ProductId
RETURNING 
    (SELECT OldPrice FROM old_values) as prev_price,
    (SELECT OldStock FROM old_values) as prev_stock;

-- Then insert history (in code, capture the returned values):
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update statistics:
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- SIMPLER APPROACH FOR ADO.NET:
-- Break into separate queries, handle transaction in code:

-- Query 1: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Query 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Query 3: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Query 4: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion Notes:
-- Key changes:
-- 1. GETDATE() → CURRENT_TIMESTAMP
-- 2. Transaction handling moved to connection level (BeginTransaction/Commit in code)
-- 3. Variable declarations removed - values captured via separate SELECT or passed from code
-- 4. Multi-statement batch split into individual executable statements

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync
-- ================================================================================
-- DMS Tool Status: Not attempted (learned from previous failures)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ================================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL:
-- Break into separate queries for ADO.NET execution:

-- Query 1: Get old values before deletion
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Query 2: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Query 3: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Query 4: Update product statistics
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

-- Conversion Notes:
-- Key changes:
-- 1. GETDATE() → CURRENT_TIMESTAMP
-- 2. Transaction handling moved to connection level
-- 3. Variable declarations removed - values retrieved and passed through code
-- 4. CASE expression works identically in PostgreSQL

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ================================================================================
-- DMS Tool Status: Not attempted (learned from previous failures)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ================================================================================

-- ORIGINAL MS SQL:
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
ORDER BY rp.PriceRank
*/

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

-- Conversion Notes:
-- This query is already PostgreSQL compatible. RANK() and PERCENT_RANK() window functions
-- work identically. No changes required.

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ================================================================================
-- DMS Tool Status: Not attempted (learned from previous failures)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- ================================================================================

-- ORIGINAL MS SQL:
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
ORDER BY StockQuantity
*/

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

-- Conversion Notes:
-- This query is already PostgreSQL compatible. Aggregate window functions work
-- identically in PostgreSQL. No changes required.

-- ================================================================================
-- CONVERSION SUMMARY
-- ================================================================================
-- Total Statements: 7
-- DMS Tool Successful Conversions: 0
-- Manual Conversions After DMS Failure: 7
--
-- Key T-SQL to PostgreSQL Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT
-- 2. GETDATE() → CURRENT_TIMESTAMP (7 occurrences)
-- 3. BEGIN TRANSACTION/COMMIT → Handled at connection level with BeginTransaction()
-- 4. DECLARE @variable → Removed, values captured via RETURNING or separate queries
-- 5. SET @variable = value → Handled in application code
-- 6. Multi-statement batches → Split into separate executable statements
--
-- PostgreSQL-Compatible Features (No Changes Needed):
-- - CTEs (WITH clause)
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK OVER)
-- - CASE expressions
-- - ROUND() function
-- - Named parameters (@param) supported by Npgsql
-- - JOIN operations
-- - WHERE, ORDER BY clauses
--
-- Schema Object Name Changes: None
-- All table and column names remain unchanged.
-- ================================================================================
