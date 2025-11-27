-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: AdoCore Application
-- Generated: Step 2 - Convert All SQL Statements Using DMS MCP Tool
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all 7 statements)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions and CASE Expressions
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: None (fully compatible)
-- Schema Object Names: No changes
-- ============================================================================

-- ORIGINAL MS SQL:
-- [See extracted_statements.sql]

-- CONVERTED PostgreSQL:
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
-- - CTEs fully compatible (WITH clause)
-- - Window functions (AVG OVER, COUNT OVER) compatible
-- - CASE expressions compatible
-- - ROUND function compatible
-- - No changes needed from original

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: None (fully compatible)
-- Schema Object Names: No changes
-- ============================================================================

-- CONVERTED PostgreSQL:
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
-- - LAG window function fully compatible
-- - CTEs compatible
-- - Parameter @ProductId works with Npgsql
-- - No changes needed from original

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: CRITICAL - SCOPE_IDENTITY(), GETDATE(), transaction syntax
-- Schema Object Names: No changes
-- ============================================================================

-- CONVERTED PostgreSQL (Split into multiple statements for application execution):

-- Statement 3a: Insert Product with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Insert into ProductHistory
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update ProductStats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion Notes:
-- CRITICAL CHANGES:
-- - SCOPE_IDENTITY() replaced with RETURNING ProductId on INSERT
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - DECLARE @NewProductId removed (value captured from RETURNING in application code)
-- - BEGIN TRANSACTION/COMMIT removed (managed by NpgsqlTransaction in application)
-- - Split into 3 separate statements to be executed within application-managed transaction
-- - Application needs to capture ProductId from RETURNING and use in subsequent statements

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: CRITICAL - GETDATE(), variable declarations, transaction syntax
-- Schema Object Names: No changes
-- ============================================================================

-- CONVERTED PostgreSQL (Split into multiple statements for application execution):

-- Statement 4a: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update Product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4c: Insert into ProductHistory
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update ProductStats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion Notes:
-- CRITICAL CHANGES:
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - DECLARE @OldPrice, @OldStock removed (values captured in application from Statement 4a)
-- - BEGIN TRANSACTION/COMMIT removed (managed by NpgsqlTransaction in application)
-- - Split into 4 separate statements to be executed within application-managed transaction
-- - Application needs to capture OldPrice and OldStock from first SELECT

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with Statistics Updates
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: CRITICAL - GETDATE(), variable declarations, transaction syntax
-- Schema Object Names: No changes
-- ============================================================================

-- CONVERTED PostgreSQL (Split into multiple statements for application execution):

-- Statement 5a: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Insert into ProductHistory
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete Product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update ProductStats
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
-- CRITICAL CHANGES:
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - DECLARE @OldPrice, @OldStock removed (values captured in application from Statement 5a)
-- - BEGIN TRANSACTION/COMMIT removed (managed by NpgsqlTransaction in application)
-- - Split into 4 separate statements to be executed within application-managed transaction
-- - Application needs to capture OldPrice and OldStock from first SELECT
-- - CASE expression is compatible with PostgreSQL

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK Window Functions
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: None (fully compatible)
-- Schema Object Names: No changes
-- ============================================================================

-- CONVERTED PostgreSQL:
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
-- - RANK() and PERCENT_RANK() window functions fully compatible
-- - CTEs compatible
-- - No changes needed from original

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - Multiple Window Functions
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: None (fully compatible)
-- Schema Object Names: No changes
-- ============================================================================

-- CONVERTED PostgreSQL:
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
-- - AVG(), MIN(), MAX() window functions fully compatible
-- - CTEs compatible
-- - ROUND function compatible
-- - No changes needed from original

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total SQL Statements Converted: 7
-- DMS Tool Successful Conversions: 0
-- Manual Conversions After DMS Failure: 7
-- 
-- Statements Requiring Code Changes:
-- - Statement 1: None (direct replacement)
-- - Statement 2: None (direct replacement)
-- - Statement 3: CRITICAL - Split into 3 statements, use RETURNING, capture ProductId
-- - Statement 4: CRITICAL - Split into 4 statements, capture old values in code
-- - Statement 5: CRITICAL - Split into 4 statements, capture old values in code
-- - Statement 6: None (direct replacement)
-- - Statement 7: None (direct replacement)
--
-- Key Transformation Patterns:
-- 1. SCOPE_IDENTITY() → RETURNING clause
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. DECLARE @Variable → Application-level variable handling
-- 4. BEGIN TRANSACTION/COMMIT → NpgsqlTransaction management in application
-- 5. Multi-statement batches → Separate NpgsqlCommand objects in transaction
--
-- Schema Object Names: No changes required (all table names remain the same)
-- ============================================================================
