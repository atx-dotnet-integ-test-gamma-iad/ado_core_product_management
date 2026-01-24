-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Compatible
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered errors)
-- Target Database: PostgreSQL
-- Conversion Date: 2026-01-24
-- ============================================================================

-- IMPORTANT: All statements were passed through the DMS MCP tool first (as required)
-- but the tool encountered conversion errors. Manual conversions were then applied
-- based on PostgreSQL best practices. See dms_conversion_log.txt for details.

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetAllProductsAsync
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - Window functions: Compatible, no changes needed
--   - CASE expressions: Compatible, no changes needed
--   - ROUND function: Compatible, no changes needed
--   - Table/schema names: No changes by DMS, using default
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetProductByIdAsync
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - LAG window function: Compatible, no changes needed
--   - LEFT JOIN: Compatible, no changes needed
--   - Parameter @ProductId: Compatible with Npgsql
--   - CASE and ROUND: Compatible, no changes needed
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
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - InsertProductAsync
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed DECLARE and multi-statement transaction (will handle in C# code)
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Split into separate statements (will be executed separately in C# with transaction)
-- ============================================================================

-- Sub-statement 3.1: INSERT into Products with RETURNING (replaces SCOPE_IDENTITY)
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Sub-statement 3.2: INSERT into ProductHistory (logging)
-- Note: @NewProductId will be obtained from RETURNING clause above
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Sub-statement 3.3: UPDATE ProductStats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - UpdateProductAsync
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed DECLARE and BEGIN TRANSACTION (will handle in C# code)
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Split into separate statements for C# transaction handling
--   - Store old values using CTE approach
-- ============================================================================

-- Sub-statement 4.1: SELECT old values (will be retrieved in C# first)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Sub-statement 4.2: UPDATE Products
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Sub-statement 4.3: INSERT into ProductHistory (logging)
-- Note: @OldPrice and @OldStock will be obtained from SELECT above in C# code
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Sub-statement 4.4: UPDATE ProductStats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - DeleteProductAsync
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed DECLARE and BEGIN TRANSACTION (will handle in C# code)
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Split into separate statements for C# transaction handling
-- ============================================================================

-- Sub-statement 5.1: SELECT product info (will be retrieved in C# first)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Sub-statement 5.2: INSERT into ProductHistory (logging)
-- Note: @OldPrice and @OldStock will be obtained from SELECT above in C# code
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Sub-statement 5.3: DELETE from Products
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Sub-statement 5.4: UPDATE ProductStats with CASE
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - RANK() and PERCENT_RANK() window functions: Compatible, no changes needed
--   - CASE expression: Compatible, no changes needed
--   - Parameters @MinPrice, @MaxPrice: Compatible with Npgsql
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetLowStockProductsAsync
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - AVG, MIN, MAX window functions with OVER: Compatible, no changes needed
--   - CASE expression: Compatible, no changes needed
--   - ROUND function: Compatible, no changes needed
--   - Parameter @Threshold: Compatible with Npgsql
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
-- Total Statements Converted: 7 main statements
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- DMS Tool Status: Failed for all statements (timeout/conversion errors)
--
-- Key PostgreSQL Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT statement
-- 2. GETDATE() → CURRENT_TIMESTAMP (15 occurrences converted)
-- 3. Multi-statement transactions split into separate statements (C# will handle)
-- 4. DECLARE statements removed (C# will handle variable storage)
-- 5. BEGIN TRANSACTION/COMMIT removed (C# will handle with NpgsqlTransaction)
--
-- Compatible SQL Server Features (no conversion needed):
-- 1. CTE (WITH) syntax - fully compatible with PostgreSQL
-- 2. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER) - compatible
-- 3. CASE expressions - fully compatible
-- 4. ROUND function - compatible
-- 5. JOIN syntax (INNER JOIN, LEFT JOIN) - compatible
-- 6. Parameter syntax (@param) - compatible with Npgsql provider
-- 7. BETWEEN operator - compatible
--
-- Schema/Table Name Changes:
-- - No schema name changes (DMS tool did not convert successfully)
-- - All tables remain: Products, ProductHistory, ProductStats
-- - Default PostgreSQL schema will be used (public)
--
-- Implementation Notes for C# Code:
-- 1. Transaction handling: Use NpgsqlTransaction for multi-statement operations
-- 2. RETURNING clause: Read result directly from ExecuteScalarAsync()
-- 3. Variable storage: Store intermediate values (OldPrice, OldStock) in C# variables
-- 4. Parameter binding: Continue using AddWithValue with @param syntax (Npgsql compatible)
-- ============================================================================
