-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Source: Microsoft SQL Server
-- Target: PostgreSQL
-- Conversion Date: 2026-02-08
-- Total Statements: 7
-- Conversion Method: Manual (after DMS tool failures)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetAllProductsAsync()
-- Conversion Notes:
-- - CTEs and window functions (AVG OVER, COUNT OVER) are compatible
-- - ROUND function syntax is compatible
-- - CASE expressions are compatible
-- - No schema object name changes required
-- DMS Tool Status: ERROR - Metadata model creation failed
-- ============================================================================
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId
-- Conversion Notes:
-- - LAG window function is compatible
-- - CTE syntax is compatible
-- - Parameter syntax @ProductId is compatible with PostgreSQL (also supports $1)
-- - ROUND function syntax is compatible
-- DMS Tool Status: ERROR - Metadata model creation failed
-- ============================================================================
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
-- STATEMENT 3: InsertProductAsync (CONVERTED TO POSTGRESQL)
-- Source Method: InsertProductAsync(Product product)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Conversion Notes:
-- - DECLARE removed (will use DO block or handle in application code)
-- - BEGIN TRANSACTION; COMMIT; syntax compatible
-- - SCOPE_IDENTITY() converted to RETURNING clause
-- - GETDATE() converted to NOW()
-- - Transaction will be handled by application code (BeginTransactionAsync)
-- - Modified to use RETURNING clause for getting new ID
-- DMS Tool Status: ERROR - Metadata model creation failed
-- ============================================================================
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED TO POSTGRESQL)
-- Source Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Conversion Notes:
-- - Transaction will be handled by application code
-- - DECLARE variables converted to subquery pattern
-- - GETDATE() converted to NOW()
-- - Need to fetch old values before update using CTE or subquery
-- DMS Tool Status: ERROR - Metadata model creation failed
-- ============================================================================
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
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, NOW()
FROM OldValues;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues) + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED TO POSTGRESQL)
-- Source Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId
-- Conversion Notes:
-- - Transaction will be handled by application code
-- - DECLARE variables converted to CTE pattern
-- - GETDATE() converted to NOW()
-- - Store old values before deletion
-- DMS Tool Status: ERROR - Metadata model creation failed
-- ============================================================================
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, NOW()
FROM OldValues;

DELETE FROM Products 
WHERE ProductId = @ProductId;

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice, @MaxPrice
-- Conversion Notes:
-- - RANK() and PERCENT_RANK() window functions are compatible
-- - CTE syntax is compatible
-- - BETWEEN operator is compatible
-- - CASE expressions are compatible
-- DMS Tool Status: ERROR - Metadata model creation failed
-- ============================================================================
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED TO POSTGRESQL)
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold
-- Conversion Notes:
-- - AVG, MIN, MAX window functions are compatible
-- - CTE syntax is compatible
-- - ROUND function syntax is compatible
-- - CASE expressions are compatible
-- DMS Tool Status: ERROR - Metadata model creation failed
-- ============================================================================
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
-- END OF CONVERTED SQL STATEMENTS
-- ============================================================================
