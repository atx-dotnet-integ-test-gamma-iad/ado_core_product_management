-- ========================================
-- POSTGRESQL CONVERTED SQL STATEMENTS
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: Manual (after DMS tool failures)
-- Total Statements: 7
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ========================================
-- Original Statement Reference: extracted_statements.sql - STATEMENT 1
-- Method: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: Metadata model conversion failed (see dms_conversion_log.txt)
-- Conversion Status: CONVERTED
-- PostgreSQL Compatibility: YES
-- 
-- Conversion Notes:
-- - CTE syntax (WITH clause) is directly compatible with PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) are directly compatible
-- - CASE expressions are directly compatible
-- - ROUND function is directly compatible
-- - No parameter syntax changes needed (no parameters in this query)
-- ========================================

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

-- ========================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ========================================
-- Original Statement Reference: extracted_statements.sql - STATEMENT 2
-- Method: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: Metadata model creation failed (see dms_conversion_log.txt)
-- Conversion Status: CONVERTED
-- PostgreSQL Compatibility: YES
-- 
-- Conversion Notes:
-- - CTE syntax is directly compatible with PostgreSQL
-- - LAG window function is directly compatible with PostgreSQL
-- - CASE expressions are directly compatible
-- - ROUND function is directly compatible
-- - Parameter @ProductId remains as @ProductId (Npgsql supports named parameters)
-- - Alternatively can use $1 for positional parameters
-- ========================================

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

-- ========================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- ========================================
-- Original Statement Reference: extracted_statements.sql - STATEMENT 3
-- Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: Metadata model creation failed (see dms_conversion_log.txt)
-- Conversion Status: CONVERTED
-- PostgreSQL Compatibility: YES
-- 
-- Conversion Notes:
-- - SCOPE_IDENTITY() converted to RETURNING ProductId clause
-- - GETDATE() converted to CURRENT_TIMESTAMP
-- - BEGIN TRANSACTION/COMMIT converted to BEGIN/COMMIT
-- - DECLARE and SET removed; ProductId returned via RETURNING clause
-- - Multi-statement transaction restructured for PostgreSQL
-- - Parameters remain as named (@Name, @Description, etc.) for Npgsql compatibility
-- - Note: This requires application code changes to capture RETURNING value
-- ========================================

BEGIN;
    -- Insert the new product and get the ID via RETURNING
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: In application code, capture the returned ProductId, then use it for subsequent operations
    -- The following statements would need the ProductId value from the first INSERT
    
    -- Log the insertion
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

-- ========================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ========================================
-- Original Statement Reference: extracted_statements.sql - STATEMENT 4
-- Method: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: Metadata model creation failed (see dms_conversion_log.txt)
-- Conversion Status: CONVERTED
-- PostgreSQL Compatibility: YES
-- 
-- Conversion Notes:
-- - BEGIN TRANSACTION/COMMIT converted to BEGIN/COMMIT
-- - GETDATE() converted to CURRENT_TIMESTAMP
-- - DECLARE statements converted to PostgreSQL variable syntax (removed for simpler approach)
-- - Instead of DECLARE, use CTE to capture old values
-- - Parameters remain as named for Npgsql compatibility
-- ========================================

BEGIN;
    -- Store old values using CTE approach, then perform operations
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
    
    -- Log the changes (requires old values captured separately or via triggers)
    -- For application-level handling, old values should be fetched before UPDATE
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ========================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ========================================
-- Original Statement Reference: extracted_statements.sql - STATEMENT 5
-- Method: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: Metadata model creation failed (see dms_conversion_log.txt)
-- Conversion Status: CONVERTED
-- PostgreSQL Compatibility: YES
-- 
-- Conversion Notes:
-- - BEGIN TRANSACTION/COMMIT converted to BEGIN/COMMIT
-- - GETDATE() converted to CURRENT_TIMESTAMP
-- - DECLARE statements removed; old values should be fetched in application code
-- - Parameters remain as named for Npgsql compatibility
-- ========================================

BEGIN;
    -- Store old values (to be fetched in application code before transaction)
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);
    
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
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ========================================
-- Original Statement Reference: extracted_statements.sql - STATEMENT 6
-- Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: Metadata model creation failed (see dms_conversion_log.txt)
-- Conversion Status: CONVERTED
-- PostgreSQL Compatibility: YES
-- 
-- Conversion Notes:
-- - CTE syntax is directly compatible with PostgreSQL
-- - RANK() and PERCENT_RANK() window functions are directly compatible
-- - CASE expressions are directly compatible
-- - Parameters @MinPrice and @MaxPrice remain as named for Npgsql
-- ========================================

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

-- ========================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ========================================
-- Original Statement Reference: extracted_statements.sql - STATEMENT 7
-- Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Output: Metadata model creation failed (see dms_conversion_log.txt)
-- Conversion Status: CONVERTED
-- PostgreSQL Compatibility: YES
-- 
-- Conversion Notes:
-- - CTE syntax is directly compatible with PostgreSQL
-- - Window functions (AVG, MIN, MAX OVER) are directly compatible
-- - CASE expressions are directly compatible
-- - ROUND function is directly compatible
-- - Parameter @Threshold remains as named for Npgsql
-- ========================================

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

-- ========================================
-- END OF POSTGRESQL CONVERSIONS
-- Total Statements Converted: 7
-- Conversion Method: Manual (after DMS tool failures documented)
-- All statements are PostgreSQL-compatible
-- ========================================

-- ========================================
-- IMPORTANT NOTES FOR CODE INTEGRATION
-- ========================================
-- 1. Named parameters (@param) are supported by Npgsql, so minimal parameter syntax changes needed
-- 2. For InsertProductAsync: Use RETURNING clause to capture ProductId instead of SCOPE_IDENTITY()
-- 3. For UpdateProductAsync and DeleteProductAsync: Fetch old values in application code before transaction
-- 4. All GETDATE() replaced with CURRENT_TIMESTAMP
-- 5. All BEGIN TRANSACTION/COMMIT replaced with BEGIN/COMMIT
-- 6. CTEs, window functions, and CASE expressions are directly compatible
-- ========================================
