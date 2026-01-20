-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Source: ADO .NET Application Migration from SQL Server to PostgreSQL
-- Conversion Date: 2026-01-20
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool timeout)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Added ::numeric cast for ROUND function
-- Schema Changes: None
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
    ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2) as PricePercentageOfAverage
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Added ::numeric cast for ROUND function
-- Schema Changes: None
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
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice)::numeric * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED - MULTI-PART TRANSACTION)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Split into multiple statements to execute within C# transaction
--          SCOPE_IDENTITY() replaced with RETURNING clause
--          GETDATE() replaced with CURRENT_TIMESTAMP
-- Schema Changes: None
-- IMPORTANT: Execute these statements in sequence within a transaction in C# code
-- ============================================================================

-- Part 1: Insert new product and get the new ID
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING ProductId;

-- Part 2: Log the insertion (use returned ProductId from Part 1)
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
-- STATEMENT 4: UpdateProductAsync (CONVERTED - MULTI-PART TRANSACTION)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Split into multiple statements to execute within C# transaction
--          GETDATE() replaced with CURRENT_TIMESTAMP
--          Variable assignments moved to C# code
-- Schema Changes: None
-- IMPORTANT: Execute these statements in sequence within a transaction in C# code
-- ============================================================================

-- Part 1: Get old values (execute first, store in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Part 2: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Part 3: Log the changes (use old values from Part 1 stored in C# variables)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Part 4: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED - MULTI-PART TRANSACTION)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Split into multiple statements to execute within C# transaction
--          GETDATE() replaced with CURRENT_TIMESTAMP
--          Variable assignments moved to C# code
-- Schema Changes: None
-- IMPORTANT: Execute these statements in sequence within a transaction in C# code
-- ============================================================================

-- Part 1: Get old values (execute first, store in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Part 2: Log the deletion (use old values from Part 1 stored in C# variables)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Part 3: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Part 4: Update product statistics
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None - fully compatible with PostgreSQL
-- Schema Changes: None
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
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Added ::numeric cast for integer division in ROUND
-- Schema Changes: None
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
    ROUND((StockQuantity::numeric / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Converted: 7
-- DMS Tool Status: All attempts resulted in timeout (metadata model conversion failure)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
--
-- Key Transformations Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP
-- 2. SCOPE_IDENTITY() → RETURNING clause in INSERT
-- 3. ROUND with division → Added ::numeric casts for proper type handling
-- 4. Multi-statement transactions split into parts for C# transaction management
-- 5. Variable declarations moved from T-SQL to C# code
--
-- Schema Object Name Changes: NONE
-- All table names (Products, ProductHistory, ProductStats) remain unchanged
--
-- PostgreSQL-Compatible Features (no changes needed):
-- - CTEs (WITH clause)
-- - Window functions (AVG/COUNT/LAG/RANK/PERCENT_RANK/MIN/MAX OVER)
-- - CASE statements
-- - JOIN operations
-- - Parameters (@ParamName format works with Npgsql)
-- ============================================================================
