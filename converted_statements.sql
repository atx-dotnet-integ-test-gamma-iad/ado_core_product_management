/*
================================================================================
SQL Statement Conversion Catalog for PostgreSQL Migration
================================================================================
Source File: ProductRepository.cs
Conversion Date: 2026-02-16
Total Statements: 7
Conversion Method: MANUAL_AFTER_DMS_FAILURE
DMS Tool Status: All statements encountered error - "Metadata model creation failed: 
                 {'error': 'Unknown metadata model creation status: RECEIVED'}"
Purpose: PostgreSQL converted statements for code reintegration
================================================================================
*/

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - PostgreSQL Conversion
-- ============================================================================
-- Method: GetAllProductsAsync()
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Window functions syntax compatible between SQL Server and PostgreSQL
--   - CASE expressions compatible
--   - ROUND function compatible
--   - Table names kept as-is (no schema transformation from DMS)
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
-- STATEMENT 2: GetProductByIdAsync - PostgreSQL Conversion
-- ============================================================================
-- Method: GetProductByIdAsync(int productId)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - LAG window function compatible between SQL Server and PostgreSQL
--   - CASE expressions compatible
--   - ROUND function compatible
--   - Parameter syntax @ProductId compatible with Npgsql
--   - Table names kept as-is (no schema transformation from DMS)
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
-- STATEMENT 3: InsertProductAsync - PostgreSQL Conversion
-- ============================================================================
-- Method: InsertProductAsync(Product product)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Removed DECLARE @NewProductId INT (variables handled differently in PostgreSQL)
--   - Removed BEGIN TRANSACTION/COMMIT (transactions managed by ADO.NET connection)
--   - Removed SET @NewProductId = SCOPE_IDENTITY()
--   - Changed to use RETURNING clause to get the new ProductId
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Multiple INSERTs and UPDATE split into separate statements (to be executed in sequence)
--   - Table names kept as-is (no schema transformation from DMS)
-- Note: This is now multiple statements that need to be executed separately in a transaction
-- ============================================================================

-- Part 1: Insert the new product and get the ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Part 2: Log the insertion (to be executed after getting @NewProductId from Part 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Part 3: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - PostgreSQL Conversion
-- ============================================================================
-- Method: UpdateProductAsync(Product product)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (transactions managed by ADO.NET connection)
--   - Kept DECLARE statements but PostgreSQL uses DO blocks for this pattern
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Variable assignments need to be refactored into subqueries or CTEs
--   - Table names kept as-is (no schema transformation from DMS)
-- Note: This requires refactoring into a CTE-based approach for PostgreSQL
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
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Part 2: Log the changes (execute after update, using stored old values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, CURRENT_TIMESTAMP
FROM OldValues;

-- Part 3: Update product statistics (using old price from stored values)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - PostgreSQL Conversion
-- ============================================================================
-- Method: DeleteProductAsync(int productId)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (transactions managed by ADO.NET connection)
--   - Removed DECLARE statements - using CTE pattern instead
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Table names kept as-is (no schema transformation from DMS)
-- Note: Requires CTE-based approach for capturing values before deletion
-- ============================================================================

WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM OldValues;

-- Part 2: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Part 3: Update product statistics (using old price stored before deletion)
WITH OldValues AS (
    SELECT Price as OldPrice
    FROM ProductHistory
    WHERE ProductId = @ProductId AND Action = 'DELETE'
    ORDER BY ActionDate DESC
    LIMIT 1
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - PostgreSQL Conversion
-- ============================================================================
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - RANK() and PERCENT_RANK() window functions compatible
--   - BETWEEN operator compatible
--   - CASE expressions compatible
--   - Table names kept as-is (no schema transformation from DMS)
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
-- STATEMENT 7: GetLowStockProductsAsync - PostgreSQL Conversion
-- ============================================================================
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Changes:
--   - AVG/MIN/MAX window functions compatible
--   - CASE expressions compatible
--   - ROUND function compatible
--   - Table names kept as-is (no schema transformation from DMS)
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
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Processed: 7
-- DMS Tool Status: All 7 statements encountered DMS error
-- Manual Conversion Applied: All 7 statements
-- Schema Object Name Changes: None (DMS did not provide any transformations)
-- Key PostgreSQL Changes:
--   1. GETDATE() → CURRENT_TIMESTAMP
--   2. SCOPE_IDENTITY() → RETURNING clause
--   3. BEGIN TRANSACTION/COMMIT removed (managed by ADO.NET)
--   4. Variable declarations replaced with CTEs where applicable
--   5. Multi-statement transactions refactored for proper execution order
-- ============================================================================
