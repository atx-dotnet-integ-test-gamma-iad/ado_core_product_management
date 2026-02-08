-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Database Migration: Microsoft SQL Server to PostgreSQL
-- Conversion Date: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- ============================================================================
-- Total Statements: 7
-- DMS Tool Status: All 7 statements attempted through DMS tool first
-- DMS Tool Error: Metadata model creation failed with RECEIVED status
-- Manual Conversion Applied: Yes, for all statements after DMS failure
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Line 16-47
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - CTEs: Compatible with PostgreSQL (no changes needed)
--   - AVG() OVER(): Compatible with PostgreSQL (no changes needed)
--   - COUNT(*) OVER(): Compatible with PostgreSQL (no changes needed)
--   - CASE statements: Compatible with PostgreSQL (no changes needed)
--   - ROUND(): Compatible with PostgreSQL (no changes needed)
-- Schema Objects: No name changes (Products table remains as-is)
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Line 58-85
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - LAG() OVER(): Compatible with PostgreSQL (no changes needed)
--   - Parameter @ProductId: Compatible with PostgreSQL (no changes needed)
--   - CASE statements: Compatible with PostgreSQL (no changes needed)
--   - ROUND(): Compatible with PostgreSQL (no changes needed)
-- Schema Objects: No name changes (Products table remains as-is)
-- Note: ProductHistory in CTE shadows actual ProductHistory table - intentional
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
-- STATEMENT 3: InsertProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Line 97-126
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Removed DECLARE @NewProductId: PostgreSQL doesn't need pre-declaration
--   - Removed BEGIN TRANSACTION: Will be handled at connection level in ADO.NET
--   - Removed SET @NewProductId = SCOPE_IDENTITY(): Replaced with RETURNING clause
--   - Changed GETDATE() to CURRENT_TIMESTAMP (PostgreSQL standard)
--   - Removed COMMIT: Will be handled at connection level in ADO.NET
--   - Combined INSERT with RETURNING to get new ID in single operation
--   - Removed final SELECT @NewProductId: RETURNING handles this
--   - Transaction statements removed: C# code handles transactions via connection
-- Schema Objects: No name changes
-- ============================================================================

-- Insert the new product and get the new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Log the insertion (separate statement in transaction)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (CURRVAL('products_productid_seq'), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (separate statement in transaction)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Line 138-173
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Removed BEGIN TRANSACTION: Will be handled at connection level
--   - Removed DECLARE statements: PostgreSQL uses DO block for variables, but we can use subqueries
--   - Changed approach: Use subquery in INSERT to get old values
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Removed COMMIT: Will be handled at connection level
-- Schema Objects: No name changes
-- ============================================================================

-- Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log the changes (using subquery to get old values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT 
    @ProductId, 
    'UPDATE', 
    Price, 
    @Price, 
    StockQuantity, 
    @StockQuantity, 
    CURRENT_TIMESTAMP
FROM Products
WHERE ProductId = @ProductId;

-- Update product statistics (using subquery to get old price)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT Price FROM Products WHERE ProductId = @ProductId) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Line 185-218
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Removed BEGIN TRANSACTION: Will be handled at connection level
--   - Removed DECLARE statements: Use CTE to capture values before delete
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Removed COMMIT: Will be handled at connection level
--   - Reordered: Must log history BEFORE deleting the product
-- Schema Objects: No name changes
-- ============================================================================

-- Log the deletion (must be done before delete to capture values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT 
    ProductId,
    'DELETE',
    Price,
    NULL,
    StockQuantity,
    NULL,
    CURRENT_TIMESTAMP
FROM Products
WHERE ProductId = @ProductId;

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT Price FROM Products WHERE ProductId = @ProductId)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Line 230-255
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - RANK() OVER(): Compatible with PostgreSQL (no changes needed)
--   - PERCENT_RANK() OVER(): Compatible with PostgreSQL (no changes needed)
--   - BETWEEN: Compatible with PostgreSQL (no changes needed)
--   - Parameters @MinPrice, @MaxPrice: Compatible with PostgreSQL (no changes needed)
-- Schema Objects: No name changes
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED TO POSTGRESQL
-- ============================================================================
-- Original SQL Server Statement: See extracted_statements.sql Line 267-295
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - AVG() OVER(): Compatible with PostgreSQL (no changes needed)
--   - MIN() OVER(): Compatible with PostgreSQL (no changes needed)
--   - MAX() OVER(): Compatible with PostgreSQL (no changes needed)
--   - ROUND(): Compatible with PostgreSQL (no changes needed)
--   - Parameter @Threshold: Compatible with PostgreSQL (no changes needed)
-- Schema Objects: No name changes
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
-- END OF CONVERTED STATEMENTS
-- ============================================================================
-- Conversion Summary:
-- Total Statements: 7
-- Successfully Converted: 7
-- Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- DMS Tool Status: Failed for all statements with metadata model error
-- 
-- Key PostgreSQL Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT statements
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. BEGIN TRANSACTION / COMMIT → Removed (handled by ADO.NET connection)
-- 4. DECLARE statements → Eliminated using subqueries or RETURNING
-- 5. Window functions → Compatible, no changes needed
-- 6. CTEs → Compatible, no changes needed
-- 7. CASE statements → Compatible, no changes needed
-- 8. Parameter syntax (@ParamName) → Compatible with Npgsql
-- 
-- Schema Object Changes:
-- - No table or column name changes required
-- - All objects maintain original names
-- ============================================================================
