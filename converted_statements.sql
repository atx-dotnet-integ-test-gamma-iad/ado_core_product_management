-- ====================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- PostgreSQL Compatible SQL Statements
-- Converted from Microsoft SQL Server
-- ====================================================================
-- CONVERSION METHOD: Manual after DMS tool failure
-- All statements were attempted through DMS MCP tool first
-- DMS tool consistently returned metadata model creation errors
-- Manual conversion applied using PostgreSQL syntax best practices
-- ====================================================================

-- ====================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ====================================================================
-- Original Source: DataAccess/ProductRepository.cs, GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- PostgreSQL Changes Applied:
--   - CTEs are compatible (no changes needed)
--   - Window functions AVG() OVER() and COUNT() OVER() are compatible
--   - CASE expressions are compatible
--   - ROUND() function is compatible
--   - Schema: Tables remain unqualified (will use public schema by default)
-- ====================================================================
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

-- ====================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ====================================================================
-- Original Source: DataAccess/ProductRepository.cs, GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes Applied:
--   - Changed @ProductId to $1 (PostgreSQL positional parameter)
--   - LAG() OVER() window function is compatible
--   - CTE syntax is compatible
--   - LEFT JOIN is compatible
--   - CASE expression is compatible
--   - ROUND() function is compatible
-- ====================================================================
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- ====================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- ====================================================================
-- Original Source: DataAccess/ProductRepository.cs, InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes Applied:
--   - Removed DECLARE @NewProductId INT (not needed with RETURNING clause)
--   - Removed explicit BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction)
--   - Replaced SCOPE_IDENTITY() with RETURNING ProductId in INSERT
--   - Changed @Name, @Description, @Price, @StockQuantity to $1, $2, $3, $4
--   - Replaced GETDATE() with NOW()
--   - Combined into single statement with CTE and RETURNING for the new ProductId
--   - Note: This will be executed as separate statements in code
-- ====================================================================
-- Insert the new product and return the ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;

-- Log the insertion (separate statement)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, NOW());

-- Update product statistics (separate statement)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ====================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ====================================================================
-- Original Source: DataAccess/ProductRepository.cs, UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes Applied:
--   - Removed explicit BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction)
--   - Removed DECLARE statements (use subquery or separate SELECT)
--   - Changed @ProductId, @Name, @Description, @Price, @StockQuantity to $1, $2, $3, $4, $5
--   - Replaced GETDATE() with NOW()
--   - Split into separate statements (will be wrapped in NpgsqlTransaction)
-- ====================================================================
-- Store old values in a CTE or separate query
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
)
-- Update the product
UPDATE Products
SET 
    Name = $2,
    Description = $3,
    Price = $4,
    StockQuantity = $5,
    ModifiedDate = NOW()
WHERE ProductId = $1;

-- Log the changes (separate statement using subquery)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT $1, 'UPDATE', Price, $2, StockQuantity, $3, NOW()
FROM Products
WHERE ProductId = $1;

-- Update product statistics (separate statement)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ====================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ====================================================================
-- Original Source: DataAccess/ProductRepository.cs, DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes Applied:
--   - Removed explicit BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction)
--   - Removed DECLARE statements
--   - Changed @ProductId to $1
--   - Replaced GETDATE() with NOW()
--   - Split into separate statements with subqueries
-- ====================================================================
-- Log the deletion (before delete, using subquery)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT ProductId, 'DELETE', Price, NULL, StockQuantity, NULL, NOW()
FROM Products
WHERE ProductId = $1;

-- Delete the product
DELETE FROM Products 
WHERE ProductId = $1;

-- Update product statistics (using stored values)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ====================================================================
-- Original Source: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes Applied:
--   - Changed @MinPrice and @MaxPrice to $1 and $2
--   - RANK() OVER() window function is compatible
--   - PERCENT_RANK() OVER() window function is compatible
--   - CTE syntax is compatible
--   - BETWEEN operator is compatible
-- ====================================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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

-- ====================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ====================================================================
-- Original Source: DataAccess/ProductRepository.cs, GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes Applied:
--   - Changed @Threshold to $1
--   - AVG() OVER(), MIN() OVER(), MAX() OVER() window functions are compatible
--   - CTE syntax is compatible
--   - ROUND() function is compatible
--   - CASE expression is compatible
-- ====================================================================
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ====================================================================
-- END OF CONVERTED SQL STATEMENTS CATALOG
-- Total Statements Converted: 7
-- Conversion Method: All MANUAL_AFTER_DMS_FAILURE
-- Conversion Date: 2026-02-10
-- ====================================================================
