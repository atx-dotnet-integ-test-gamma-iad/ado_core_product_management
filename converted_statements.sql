-- ===============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Syntax
-- Purpose: PostgreSQL-compatible versions of extracted SQL Server statements
-- Total Statements: 7
-- Conversion Method: Manual conversion after DMS tool failures (documented in dms_conversion_log.json)
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with window functions
-- Source File: ProductRepository.cs
-- Source Method: GetAllProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Window functions syntax compatible with PostgreSQL (no changes needed)
--   - ROUND function compatible (no changes needed)
--   - Schema name removed (PostgreSQL uses public schema by default)
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG window function
-- Source File: ProductRepository.cs
-- Source Method: GetProductByIdAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - LAG window function syntax compatible with PostgreSQL (no changes needed)
--   - Parameter @ProductId remains compatible with Npgsql named parameters
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
-- STATEMENT 3: InsertProductAsync - Multi-statement transaction (CONVERTED TO POSTGRESQL)
-- Source File: ProductRepository.cs
-- Source Method: InsertProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed DECLARE statement (PostgreSQL doesn't need it in this context)
--   - Removed BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction in C# code)
--   - Changed SCOPE_IDENTITY() to use RETURNING clause for getting inserted ID
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Combined into transaction-friendly format for Npgsql
-- NOTE: This will be executed as separate commands within a C# transaction block
-- ===============================================================================
-- Insert the new product and get the ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Log the insertion (executed after getting ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-statement transaction (CONVERTED TO POSTGRESQL)
-- Source File: ProductRepository.cs
-- Source Method: UpdateProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction in C# code)
--   - Removed DECLARE statements (variables will be handled in C# code or via CTE)
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Restructured to use CTE for capturing old values
-- ===============================================================================
-- Get old values and update in one statement using CTE
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
WHERE ProductId = @ProductId
RETURNING (SELECT OldPrice FROM OldValues), (SELECT OldStock FROM OldValues);

-- Log the changes (executed after update, using returned old values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-statement transaction (CONVERTED TO POSTGRESQL)
-- Source File: ProductRepository.cs
-- Source Method: DeleteProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction in C# code)
--   - Removed DECLARE statements (variables will be handled via CTE)
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Restructured to use CTE for capturing values before delete
-- ===============================================================================
-- Get values before deletion using CTE
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
-- Log the deletion first
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM OldValues;

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics (using CTE values)
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Source File: ProductRepository.cs
-- Source Method: GetProductsByPriceRangeAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - RANK() and PERCENT_RANK() window functions compatible with PostgreSQL (no changes needed)
--   - Parameters remain compatible
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with multiple window functions
-- Source File: ProductRepository.cs
-- Source Method: GetLowStockProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Window functions (AVG, MIN, MAX) compatible with PostgreSQL (no changes needed)
--   - Parameter remains compatible
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
-- END OF CONVERTED STATEMENTS
-- Total Count: 7 SQL Statements
-- Conversion Notes:
-- - Statements 1, 2, 6, 7: Minimal changes - window functions already PostgreSQL compatible
-- - Statements 3, 4, 5: Major restructuring required for transaction handling and variable management
-- - All GETDATE() converted to CURRENT_TIMESTAMP
-- - SCOPE_IDENTITY() converted to RETURNING clause
-- - Transaction management moved to C# code level (using NpgsqlTransaction)
-- ===============================================================================
