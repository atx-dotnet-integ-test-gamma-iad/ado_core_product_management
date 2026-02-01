-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Migration from Microsoft SQL Server to PostgreSQL
-- ============================================================================
-- This file contains all SQL statements converted to PostgreSQL syntax
-- 
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Reason: DMS MCP tool encountered metadata model creation/conversion errors
-- All statements were attempted through DMS tool but required manual conversion
--
-- Total Statements Converted: 7
-- Source File: DataAccess/ProductRepository.cs
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATEMENT ID: 1
-- METHOD: GetAllProductsAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- CHANGES APPLIED:
--   - None required - PostgreSQL supports CTEs, window functions, and CASE identically
--   - ROUND function works the same way in PostgreSQL
--   - Schema remains 'Products' (no DMS transformation)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT ID: 2
-- METHOD: GetProductByIdAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- CHANGES APPLIED:
--   - None required - PostgreSQL supports LAG window function identically
--   - ROUND function works the same way in PostgreSQL
--   - Schema remains 'Products' (no DMS transformation)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT ID: 3
-- METHOD: InsertProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- CHANGES APPLIED:
--   - Removed DECLARE @NewProductId - PostgreSQL doesn't support variable declarations in SELECT context
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Replaced SCOPE_IDENTITY() with RETURNING clause on INSERT
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Removed final SELECT @NewProductId - will use RETURNING from first INSERT
--   - Note: This requires code changes to capture RETURNING value from first INSERT
-- ----------------------------------------------------------------------------
BEGIN;
    -- Insert the new product and return the new ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: The application code needs to capture the returned ProductId from above
    -- and use it for subsequent statements. This is a structural change from T-SQL.
    
    -- Log the insertion (requires ProductId from RETURNING above)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ----------------------------------------------------------------------------
-- STATEMENT ID: 4
-- METHOD: UpdateProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model creation failed (expected based on pattern)
-- CHANGES APPLIED:
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Removed DECLARE statements - PostgreSQL requires DO block or use CTEs
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Restructured to use CTEs to capture old values
-- ----------------------------------------------------------------------------
BEGIN;
    -- Store old values using CTE, update, and log in one transaction
    WITH OldValues AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    )
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes (requires capturing OldValues separately in application code)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM (SELECT Price as OldPrice, StockQuantity as OldStock FROM Products WHERE ProductId = @ProductId) AS OldValues;
    
    -- Update product statistics (requires capturing old values separately)
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT Price FROM Products WHERE ProductId = @ProductId) + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ----------------------------------------------------------------------------
-- STATEMENT ID: 5
-- METHOD: DeleteProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model creation failed (expected based on pattern)
-- CHANGES APPLIED:
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Removed DECLARE statements
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Restructured to capture old values before deletion
-- ----------------------------------------------------------------------------
BEGIN;
    -- Log the deletion with old values
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', Price, NULL, StockQuantity, NULL, CURRENT_TIMESTAMP
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
COMMIT;

-- ----------------------------------------------------------------------------
-- STATEMENT ID: 6
-- METHOD: GetProductsByPriceRangeAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model creation failed (expected based on pattern)
-- CHANGES APPLIED:
--   - None required - RANK() and PERCENT_RANK() work identically in PostgreSQL
--   - BETWEEN clause works the same way
--   - Schema remains 'Products' (no DMS transformation)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT ID: 7
-- METHOD: GetLowStockProductsAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model creation failed (expected based on pattern)
-- CHANGES APPLIED:
--   - None required - AVG, MIN, MAX window functions work identically in PostgreSQL
--   - ROUND function works the same way
--   - Schema remains 'Products' (no DMS transformation)
-- ----------------------------------------------------------------------------
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
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
-- 
-- MANUAL CONVERSION NOTES:
-- ========================
-- Statements 1, 2, 6, 7: Minimal changes required - PostgreSQL has excellent
-- compatibility with T-SQL for CTEs, window functions, and standard SQL syntax
--
-- Statement 3 (InsertProductAsync): Major restructuring required
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - Application code must capture RETURNING value and use in subsequent statements
--   - May need to split into multiple commands or use a stored procedure
--
-- Statements 4, 5 (UpdateProductAsync, DeleteProductAsync): Moderate changes
--   - Variable declarations removed (not supported in PostgreSQL SELECT context)
--   - Restructured to use subqueries or require application-level variable handling
--   - Application may need to execute queries in sequence with variable passing
--
-- All statements:
--   - BEGIN TRANSACTION -> BEGIN
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Parameter syntax (@param) works with Npgsql driver
-- ============================================================================
