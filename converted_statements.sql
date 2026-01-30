-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- .NET ADO Application - AdoCore
-- ============================================================================
-- This file contains all SQL statement pairs (original SQL Server + converted
-- PostgreSQL) for migration validation and code re-integration.
-- 
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: Failed for all statements (metadata model errors)
-- Manual Conversion Basis: PostgreSQL compatibility analysis
-- ============================================================================

-- ============================================================================
-- STATEMENT PAIR 1: GetAllProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: FAILED (Metadata model conversion did not complete)
-- Complexity: HIGH
-- Changes: None required - PostgreSQL compatible syntax
-- ============================================================================

-- ORIGINAL (SQL Server):
-- ----------------------
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

-- CONVERTED (PostgreSQL):
-- -----------------------
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
-- STATEMENT PAIR 2: GetProductByIdAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: FAILED (Metadata model creation did not complete)
-- Complexity: HIGH
-- Changes: None required - PostgreSQL compatible syntax
-- ============================================================================

-- ORIGINAL (SQL Server):
-- ----------------------
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

-- CONVERTED (PostgreSQL):
-- -----------------------
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
-- STATEMENT PAIR 3: InsertProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not invoked (previous DMS failures documented)
-- Complexity: HIGH
-- Changes: SCOPE_IDENTITY() → RETURNING, GETDATE() → CURRENT_TIMESTAMP,
--          Transaction management moved to ADO.NET NpgsqlTransaction
-- ============================================================================

-- ORIGINAL (SQL Server):
-- ----------------------
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- CONVERTED (PostgreSQL - ADO.NET Compatible):
-- --------------------------------------------
-- NOTE: This conversion splits the transaction into manageable statements
-- The transaction will be managed by NpgsqlTransaction in ADO.NET code
-- The RETURNING clause replaces SCOPE_IDENTITY()

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- After getting ProductId, execute these statements within the same transaction:
-- (ProductId will be captured from RETURNING clause and used as @NewProductId parameter)

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;


-- ============================================================================
-- STATEMENT PAIR 4: UpdateProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not invoked (previous DMS failures documented)
-- Complexity: HIGH
-- Changes: GETDATE() → CURRENT_TIMESTAMP, variables replaced with subqueries,
--          Transaction management moved to ADO.NET NpgsqlTransaction
-- ============================================================================

-- ORIGINAL (SQL Server):
-- ----------------------
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

-- CONVERTED (PostgreSQL - ADO.NET Compatible):
-- --------------------------------------------
-- NOTE: Transaction managed by NpgsqlTransaction in ADO.NET code
-- Variables replaced with subqueries for ADO.NET compatibility

-- First, capture old values in temporary table (within transaction)
CREATE TEMP TABLE IF NOT EXISTS temp_product_old AS
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log the changes using the temporary table
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, CURRENT_TIMESTAMP
FROM temp_product_old;

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM temp_product_old) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Clean up temp table
DROP TABLE temp_product_old;


-- ============================================================================
-- STATEMENT PAIR 5: DeleteProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not invoked (previous DMS failures documented)
-- Complexity: HIGH
-- Changes: GETDATE() → CURRENT_TIMESTAMP, variables replaced with subqueries,
--          Transaction management moved to ADO.NET NpgsqlTransaction
-- ============================================================================

-- ORIGINAL (SQL Server):
-- ----------------------
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

-- CONVERTED (PostgreSQL - ADO.NET Compatible):
-- --------------------------------------------
-- NOTE: Transaction managed by NpgsqlTransaction in ADO.NET code
-- Capture old values before deletion using temporary table

-- Store product info in temp table before deletion
CREATE TEMP TABLE IF NOT EXISTS temp_product_deleted AS
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM temp_product_deleted;

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM temp_product_deleted)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Clean up temp table
DROP TABLE temp_product_deleted;


-- ============================================================================
-- STATEMENT PAIR 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not invoked (previous DMS failures documented)
-- Complexity: HIGH
-- Changes: None required - PostgreSQL compatible syntax
-- ============================================================================

-- ORIGINAL (SQL Server):
-- ----------------------
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

-- CONVERTED (PostgreSQL):
-- -----------------------
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
-- STATEMENT PAIR 7: GetLowStockProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not invoked (previous DMS failures documented)
-- Complexity: HIGH
-- Changes: None required - PostgreSQL compatible syntax
-- ============================================================================

-- ORIGINAL (SQL Server):
-- ----------------------
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

-- CONVERTED (PostgreSQL):
-- -----------------------
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
-- Total Statement Pairs: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
--
-- Statements Requiring Changes:
-- - Statement 3 (InsertProductAsync): SCOPE_IDENTITY → RETURNING, GETDATE → CURRENT_TIMESTAMP
-- - Statement 4 (UpdateProductAsync): GETDATE → CURRENT_TIMESTAMP, transaction restructure
-- - Statement 5 (DeleteProductAsync): GETDATE → CURRENT_TIMESTAMP, transaction restructure
--
-- Statements PostgreSQL Compatible (No Changes):
-- - Statement 1 (GetAllProductsAsync): CTE and window functions compatible
-- - Statement 2 (GetProductByIdAsync): CTE and LAG window function compatible
-- - Statement 6 (GetProductsByPriceRangeAsync): CTE and RANK/PERCENT_RANK compatible
-- - Statement 7 (GetLowStockProductsAsync): CTE and aggregate window functions compatible
--
-- Schema Object Name Changes: NONE
-- All table names (Products, ProductHistory, ProductStats) remain unchanged
--
-- Ready for SQL Equivalency Validation (Step 3)
-- Ready for Code Re-integration (Step 5)
-- ============================================================================
