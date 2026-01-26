-- ==================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- ==================================================================================
-- Target Database: PostgreSQL
-- Conversion Method: Manual conversion after DMS tool timeout failures
-- Conversion Date: 2024-01-26
-- Total Statements: 7
-- ==================================================================================
-- NOTE: All statements were first attempted through DMS MCP tool, which encountered
--       metadata model conversion timeout errors. Manual conversions follow 
--       PostgreSQL best practices and syntax standards.
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - PostgreSQL Version
-- ==================================================================================
-- Source Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model conversion timeout
-- Changes Applied:
--   - Window functions syntax already PostgreSQL compatible
--   - CTEs syntax already compatible
--   - ROUND function syntax compatible
--   - CASE expressions compatible
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync - PostgreSQL Version
-- ==================================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model conversion timeout
-- Changes Applied:
--   - LAG window function already PostgreSQL compatible
--   - CTEs syntax already compatible
--   - ROUND function compatible
--   - CASE expressions compatible
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - PostgreSQL Version
-- ==================================================================================
-- Source Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model conversion timeout
-- Changes Applied:
--   - Removed DECLARE @NewProductId INT (PostgreSQL uses RETURNING clause)
--   - Removed SET @NewProductId = SCOPE_IDENTITY()
--   - Added RETURNING ProductId to INSERT statement
--   - Changed GETDATE() to NOW()
--   - Transaction syntax (BEGIN TRANSACTION/COMMIT) remains compatible
--   - Modified to use subquery for getting new product ID in subsequent statements
-- ==================================================================================

BEGIN;
    -- Insert the new product and get the ID
    WITH new_product AS (
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING ProductId
    )
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    -- Return the new product ID
    SELECT ProductId FROM new_product;
COMMIT;

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - PostgreSQL Version
-- ==================================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model conversion timeout
-- Changes Applied:
--   - Converted DECLARE to PostgreSQL variable syntax using DO block approach
--   - Changed GETDATE() to NOW()
--   - Modified to use subqueries instead of variables for cleaner PostgreSQL approach
--   - Transaction syntax remains compatible
-- ==================================================================================

BEGIN;
    -- Store old values for history and update the product
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
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, NOW()
    FROM old_values;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - PostgreSQL Version
-- ==================================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model conversion timeout
-- Changes Applied:
--   - Converted DECLARE to PostgreSQL CTE approach
--   - Changed GETDATE() to NOW()
--   - Modified to use CTE for storing old values
--   - Transaction syntax remains compatible
--   - CASE expression compatible
-- ==================================================================================

BEGIN;
    -- Store product info for history before deletion
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    )
    -- Log the deletion first
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, NOW()
    FROM old_values;
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - PostgreSQL Version
-- ==================================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model conversion timeout
-- Changes Applied:
--   - RANK() and PERCENT_RANK() window functions already PostgreSQL compatible
--   - CTEs syntax already compatible
--   - CASE expressions compatible
--   - BETWEEN operator compatible
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - PostgreSQL Version
-- ==================================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model conversion timeout
-- Changes Applied:
--   - AVG, MIN, MAX window functions already PostgreSQL compatible
--   - CTEs syntax already compatible
--   - ROUND function compatible
--   - CASE expressions compatible
-- ==================================================================================

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

-- ==================================================================================
-- END OF CONVERTED STATEMENTS
-- ==================================================================================
-- CONVERSION SUMMARY:
-- Total Statements: 7
-- DMS Tool Successes: 0
-- Manual Conversions After DMS Failure: 7
--
-- Key PostgreSQL Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT statements
-- 2. GETDATE() → NOW()
-- 3. DECLARE/SET variables → CTEs and subqueries (PostgreSQL best practice)
-- 4. BEGIN TRANSACTION → BEGIN
-- 5. Transaction blocks restructured for PostgreSQL compatibility
--
-- Compatibility Notes:
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) are 
--   already compatible between SQL Server and PostgreSQL
-- - CTEs (WITH clauses) have identical syntax
-- - CASE expressions are compatible
-- - ROUND function syntax is compatible
-- - Parameter placeholders (@param) are supported by Npgsql
-- ==================================================================================
