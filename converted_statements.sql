-- ============================================================================
-- SQL STATEMENTS CONVERSION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All 7 statements)
-- DMS Tool Status: All statements failed DMS conversion
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- ============================================================================
-- Original SQL Server Statement:
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
--     p.Name

-- DMS Tool Output:
-- Status: error
-- Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Timestamp: 2026-01-20T14:25:09.441937

-- PostgreSQL Converted Statement (Manual):
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
-- - CTEs are supported in PostgreSQL with identical syntax
-- - Window functions (AVG OVER, COUNT OVER) are identical in PostgreSQL
-- - CASE expressions are identical in PostgreSQL
-- - ROUND function is identical in PostgreSQL
-- - No schema name changes required
-- - Statement is fully compatible with PostgreSQL

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- ============================================================================
-- DMS Tool Output:
-- Status: error
-- Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Timestamp: 2026-01-20T14:28:30.455147

-- PostgreSQL Converted Statement (Manual):
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
-- - CTEs are supported in PostgreSQL with identical syntax
-- - LAG window function is identical in PostgreSQL
-- - Parameter @ProductId is supported by Npgsql (named parameters)
-- - No schema name changes required
-- - Statement is fully compatible with PostgreSQL

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- ============================================================================
-- DMS Tool Output:
-- Status: error
-- Error: Metadata model creation failed: {'error': "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"}
-- Timestamp: 2026-01-20T14:29:19.675933

-- PostgreSQL Converted Statement (Manual):
-- Note: Transaction handling in ADO.NET will be done at code level
-- This statement returns the new ProductId using RETURNING clause instead of SCOPE_IDENTITY()
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Additional statements to be executed in same transaction:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion Notes:
-- - BEGIN TRANSACTION/COMMIT removed - will be handled by C# code using NpgsqlTransaction
-- - SCOPE_IDENTITY() replaced with RETURNING clause in INSERT statement
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - DECLARE @NewProductId removed - will capture from RETURNING clause in C# code
-- - SET @NewProductId removed - will use value from RETURNING clause
-- - Multiple statements will be executed sequentially in a transaction block in C# code
-- - No schema name changes required

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- ============================================================================
-- DMS Tool Output:
-- Status: error
-- Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Timestamp: 2026-01-20T14:32:19.913745

-- PostgreSQL Converted Statement (Manual):
-- Note: Transaction handling and variable declarations will be done at code level
-- These statements will be executed sequentially in a transaction

-- Statement 1: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 2: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 3: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Conversion Notes:
-- - BEGIN TRANSACTION/COMMIT removed - will be handled by C# code using NpgsqlTransaction
-- - DECLARE @OldPrice and @OldStock removed - will capture values in C# code
-- - GETDATE() replaced with CURRENT_TIMESTAMP (4 occurrences)
-- - Multiple statements will be executed sequentially in a transaction block in C# code
-- - @OldPrice and @OldStock will be C# variables populated from first SELECT
-- - No schema name changes required

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- ============================================================================
-- DMS Tool Output:
-- Status: error
-- Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Timestamp: 2026-01-20T14:35:39.223715

-- PostgreSQL Converted Statement (Manual):
-- Note: Transaction handling and variable declarations will be done at code level
-- These statements will be executed sequentially in a transaction

-- Statement 1: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 2: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 3: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 4: Update product statistics
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
-- - BEGIN TRANSACTION/COMMIT removed - will be handled by C# code using NpgsqlTransaction
-- - DECLARE @OldPrice and @OldStock removed - will capture values in C# code
-- - GETDATE() replaced with CURRENT_TIMESTAMP (2 occurrences)
-- - Multiple statements will be executed sequentially in a transaction block in C# code
-- - @OldPrice and @OldStock will be C# variables populated from first SELECT
-- - No schema name changes required

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- ============================================================================
-- DMS Tool Output:
-- Status: error
-- Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Timestamp: 2026-01-20T14:39:09.876026

-- PostgreSQL Converted Statement (Manual):
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
-- - CTEs are supported in PostgreSQL with identical syntax
-- - RANK() and PERCENT_RANK() window functions are identical in PostgreSQL
-- - CASE expressions are identical in PostgreSQL
-- - Parameters @MinPrice and @MaxPrice are supported by Npgsql
-- - No schema name changes required
-- - Statement is fully compatible with PostgreSQL

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- ============================================================================
-- DMS Tool Output:
-- Status: error
-- Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Timestamp: 2026-01-20T14:42:29.085175

-- PostgreSQL Converted Statement (Manual):
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
-- - CTEs are supported in PostgreSQL with identical syntax
-- - Window functions (AVG, MIN, MAX with OVER) are identical in PostgreSQL
-- - CASE expressions are identical in PostgreSQL
-- - ROUND function is identical in PostgreSQL
-- - Parameter @Threshold is supported by Npgsql
-- - No schema name changes required
-- - Statement is fully compatible with PostgreSQL

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total SQL Statements Processed: 7
-- Statements Successfully Converted by DMS Tool: 0
-- Statements Requiring Manual Conversion After DMS Failure: 7
-- 
-- DMS Tool Failure Analysis:
-- - All 7 statements failed DMS conversion
-- - Errors: "Metadata model conversion did not complete after 15 attempts" (6 statements)
-- - Errors: "Statement definition is not valid" (1 statement - InsertProductAsync)
-- 
-- Manual Conversion Approach:
-- - CTEs and Window Functions: Identical syntax in PostgreSQL (Statements 1, 2, 6, 7)
-- - GETDATE(): Replaced with CURRENT_TIMESTAMP (Statements 3, 4, 5)
-- - SCOPE_IDENTITY(): Replaced with RETURNING clause (Statement 3)
-- - BEGIN TRANSACTION/COMMIT: Moved to C# code level with NpgsqlTransaction (Statements 3, 4, 5)
-- - DECLARE variables: Moved to C# code level (Statements 3, 4, 5)
-- - Named parameters (@ParameterName): Supported by Npgsql without changes
-- 
-- Schema Object Name Changes:
-- - No schema name changes were required
-- - All table names remain unchanged (Products, ProductHistory, ProductStats)
-- 
-- PostgreSQL Compatibility:
-- - All 7 statements are fully compatible with PostgreSQL after manual conversion
-- - CTEs, window functions (LAG, RANK, PERCENT_RANK, AVG, MIN, MAX, COUNT), and CASE expressions work identically
-- - Main differences are in transaction handling and identity retrieval, handled at code level
-- ============================================================================
