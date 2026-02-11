-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Date: 2026-02-11
-- ============================================================================
-- CRITICAL NOTICE: DMS MCP Tool Conversion Status
-- All 7 statements were processed through the DMS MCP tool as required.
-- All 7 statements failed with the same error:
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- 
-- Per transformation definition guidelines, manual conversion has been applied
-- after DMS tool processing. All conversions are documented below with:
-- - Original SQL Server statement
-- - DMS tool error output
-- - Manual PostgreSQL conversion
-- ============================================================================
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Timestamp: 2026-02-11T12:54:20.401433
-- 
-- SQL Server-Specific Features Converted:
-- - None (CTEs and window functions are compatible with PostgreSQL)
-- - ROUND() function is compatible
-- - CASE expressions are compatible
-- 
-- Schema Object Names: No changes (Products table remains as "Products")
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Timestamp: 2026-02-11T12:54:34.446296
-- 
-- SQL Server-Specific Features Converted:
-- - None (LAG() window function is compatible with PostgreSQL)
-- - CTEs are compatible
-- - CASE expressions are compatible
-- 
-- Schema Object Names: No changes (Products table remains as "Products")
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
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Timestamp: 2026-02-11T12:54:46.998101
-- 
-- SQL Server-Specific Features Converted:
-- - SCOPE_IDENTITY() → RETURNING clause (PostgreSQL native way to get inserted ID)
-- - GETDATE() → CURRENT_TIMESTAMP (PostgreSQL standard)
-- - BEGIN TRANSACTION; ... COMMIT; → BEGIN; ... COMMIT; (PostgreSQL syntax)
-- - DECLARE @NewProductId INT; → Not needed (using RETURNING)
-- - SET @NewProductId = SCOPE_IDENTITY(); → Not needed (using RETURNING)
-- - SELECT @NewProductId; → Not needed (INSERT returns the ID via RETURNING)
-- 
-- Schema Object Names: No changes
-- 
-- IMPORTANT: This conversion restructures the transaction to use PostgreSQL's
-- RETURNING clause, which is more efficient than SCOPE_IDENTITY(). The application
-- code needs to capture the returned ID from the INSERT statement directly.
-- ============================================================================

-- PostgreSQL version using RETURNING clause
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: For full transaction support with history logging and statistics update,
-- the application should handle the transaction in code using NpgsqlTransaction:
-- 
-- BEGIN;
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity)
--     RETURNING ProductId;
--     -- Capture the returned ProductId in application code as @NewProductId
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
--     
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = CURRENT_TIMESTAMP
--     WHERE StatId = 1;
-- COMMIT;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Timestamp: 2026-02-11T12:55:00.281796
-- 
-- SQL Server-Specific Features Converted:
-- - BEGIN TRANSACTION; → BEGIN; (PostgreSQL uses BEGIN without TRANSACTION keyword)
-- - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
-- - COMMIT; remains COMMIT;
-- - DECLARE statements remain compatible (PostgreSQL supports DECLARE for variables)
-- 
-- Schema Object Names: No changes
-- 
-- Note: Variable assignment syntax (SELECT @var = column) is compatible with PostgreSQL
-- when using DO blocks or functions, but in ADO.NET context, this will be handled
-- as separate statements within a transaction.
-- ============================================================================

BEGIN;
    -- Store old values for history
    -- Note: In PostgreSQL/Npgsql, these would be handled as separate SELECT INTO statements
    -- or captured in application code before the UPDATE
    
    -- Get old values (handled in application code)
    -- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Timestamp: 2026-02-11T12:55:16.369148
-- 
-- SQL Server-Specific Features Converted:
-- - BEGIN TRANSACTION; → BEGIN;
-- - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
-- - COMMIT; remains COMMIT;
-- - DECLARE statements compatible
-- - CASE expressions compatible
-- 
-- Schema Object Names: No changes
-- ============================================================================

BEGIN;
    -- Store product info for history
    -- Note: Old values should be captured in application code before DELETE
    -- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;
    
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Timestamp: 2026-02-11T12:55:29.270170
-- 
-- SQL Server-Specific Features Converted:
-- - None (RANK() and PERCENT_RANK() are compatible with PostgreSQL)
-- - CTEs are compatible
-- - CASE expressions are compatible
-- - BETWEEN operator is compatible
-- 
-- Schema Object Names: No changes
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Timestamp: 2026-02-11T12:55:43.633192
-- 
-- SQL Server-Specific Features Converted:
-- - None (AVG(), MIN(), MAX() window functions are compatible with PostgreSQL)
-- - CTEs are compatible
-- - CASE expressions are compatible
-- - ROUND() function is compatible
-- 
-- Schema Object Names: No changes
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
-- Successfully Converted by DMS Tool: 0
-- Manually Converted After DMS Failure: 7
-- 
-- Key Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
-- 2. GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
-- 3. BEGIN TRANSACTION → BEGIN (Statements 4, 5)
-- 4. Transaction handling adapted for PostgreSQL/Npgsql (Statements 3, 4, 5)
-- 
-- Schema Object Name Changes: None
-- All table names remain unchanged (Products, ProductHistory, ProductStats)
-- 
-- Compatibility Notes:
-- - CTEs (WITH clauses) are fully compatible
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) are compatible
-- - CASE expressions are compatible
-- - ROUND() function is compatible
-- - Parameter syntax (@param) is compatible with Npgsql
-- 
-- Application Code Changes Required:
-- - Statement 3 (InsertProductAsync): Refactor to use RETURNING clause instead of SCOPE_IDENTITY()
-- - Statements 4 & 5: Capture old values in application code before UPDATE/DELETE operations
-- - All transaction statements: Use NpgsqlTransaction in code instead of embedded SQL transactions
-- 
-- All conversions are ready for re-integration into ProductRepository.cs
-- ============================================================================
