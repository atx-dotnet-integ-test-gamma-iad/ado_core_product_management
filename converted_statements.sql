-- ===============================================================================
-- PostgreSQL Converted SQL Statement Catalog
-- Generated for SQL Server to PostgreSQL Migration
-- Source Application: AdoCore
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All DMS attempts failed)
-- ===============================================================================

-- ===============================================================================
-- Statement ID: 1 (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Conversion Notes: 
--   - Window functions syntax compatible between SQL Server and PostgreSQL
--   - CASE expressions compatible
--   - ROUND function compatible
--   - Schema: dbo.Products → public.Products (default schema)
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
-- Statement ID: 2 (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Conversion Notes:
--   - LAG window function is compatible with PostgreSQL
--   - CASE and ROUND functions compatible
--   - Parameter syntax: @ProductId remains compatible with Npgsql
--   - Schema: default to public
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
-- Statement ID: 3 (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid
-- Conversion Notes:
--   - Removed DECLARE statement (not needed in inline SQL for PostgreSQL)
--   - SCOPE_IDENTITY() replaced with RETURNING clause on INSERT
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - Transaction structure maintained with DO block or split into separate commands
--   - CRITICAL: This conversion changes the structure significantly
--   - The INSERT now uses RETURNING ProductId to get the new ID directly
--   - Subsequent statements reference the returned ID
-- ===============================================================================
BEGIN;
    WITH inserted_product AS (
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING ProductId
    )
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM inserted_product;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    SELECT ProductId FROM Products ORDER BY ProductId DESC LIMIT 1;
COMMIT;

-- ===============================================================================
-- Statement ID: 4 (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Conversion Notes:
--   - BEGIN TRANSACTION → BEGIN
--   - GETDATE() → NOW()
--   - Removed DECLARE statements (handled differently in PostgreSQL)
--   - Variable assignment converted to subqueries where needed
--   - Schema: default to public
-- ===============================================================================
BEGIN;
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
        ModifiedDate = NOW()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, NOW()
    FROM old_values;
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ===============================================================================
-- Statement ID: 5 (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Conversion Notes:
--   - BEGIN TRANSACTION → BEGIN
--   - GETDATE() → NOW()
--   - Removed DECLARE statements
--   - Variable assignment converted to CTE
--   - CASE expression compatible
--   - Schema: default to public
-- ===============================================================================
BEGIN;
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    )
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, NOW()
    FROM old_values;
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM (SELECT Price as OldPrice FROM Products WHERE ProductId = @ProductId) AS temp)) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ===============================================================================
-- Statement ID: 6 (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion did not complete after 15 attempts
-- Conversion Notes:
--   - RANK() and PERCENT_RANK() window functions are fully compatible
--   - CASE expressions compatible
--   - BETWEEN operator compatible
--   - Parameters @MinPrice and @MaxPrice compatible with Npgsql
--   - Schema: default to public
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
-- Statement ID: 7 (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation did not complete after 15 attempts
-- Conversion Notes:
--   - Multiple window functions (AVG, MIN, MAX OVER) are compatible
--   - CASE expressions compatible
--   - ROUND function compatible
--   - Parameter @Threshold compatible with Npgsql
--   - Schema: default to public
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
-- CONVERSION SUMMARY
-- ===============================================================================
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (100%)
-- DMS Tool Success Rate: 0/7 (0%)
-- 
-- Critical Conversions:
--   1. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
--   2. GETDATE() → NOW() (Statements 3, 4, 5)
--   3. BEGIN TRANSACTION → BEGIN (Statements 3, 4, 5)
--   4. DECLARE variables → CTE or subqueries (Statements 3, 4, 5)
--
-- Compatible Syntax (No Changes Required):
--   - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER)
--   - CASE expressions
--   - ROUND function
--   - JOIN operations
--   - CTEs (WITH clauses)
--   - Named parameters (@ParamName) - Npgsql supports this
--
-- Schema Changes:
--   - No explicit schema changes from DMS
--   - Defaulting to public schema in PostgreSQL
--   - Table names remain the same: Products, ProductHistory, ProductStats
-- ===============================================================================
