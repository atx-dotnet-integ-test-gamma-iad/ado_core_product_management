-- =============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Conversion Method: Manual (DMS Tool Unavailable)
-- Target Database: PostgreSQL
-- Total Statements: 7
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- =============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: GetAllProductsAsync()
-- Complexity: HIGH - CTE with window functions, CASE expressions
-- Parameters: None
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - Window functions (AVG OVER, COUNT OVER): Compatible, no changes needed
--   - CASE expressions: Compatible, no changes needed
--   - ROUND function: Compatible, no changes needed
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- =============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: GetProductByIdAsync(int productId)
-- Complexity: HIGH - CTE with LAG window function
-- Parameters: @ProductId (int)
-- Changes Applied:
--   - LAG window function: Compatible, no changes needed
--   - CTE syntax: Compatible, no changes needed
--   - Parameter @ProductId: Kept as named parameter (Npgsql supports named parameters)
--   - CASE expressions: Compatible, no changes needed
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- =============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: InsertProductAsync(Product product)
-- Complexity: HIGH - Transaction with RETURNING clause (replaces SCOPE_IDENTITY)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Changes Applied:
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - SCOPE_IDENTITY() → RETURNING clause on INSERT statement
--   - GETDATE() → NOW() (3 occurrences)
--   - COMMIT → COMMIT (kept as is)
--   - Removed DECLARE @NewProductId - using RETURNING instead
--   - Combined INSERT with RETURNING to get new ID in a single operation
--   - Transaction now returns the ProductId directly from the INSERT RETURNING
-- IMPORTANT: In application code, this must be executed as a single transaction
--            and the RETURNING value must be captured from the first INSERT
-- =============================================================================

BEGIN;
    WITH new_product AS (
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING ProductId
    ),
    history_insert AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
        FROM new_product
        RETURNING ProductId
    )
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
    
    SELECT ProductId FROM new_product;
COMMIT;

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- =============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: UpdateProductAsync(Product product)
-- Complexity: HIGH - Transaction with CTEs to capture old values
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Changes Applied:
--   - BEGIN TRANSACTION → BEGIN
--   - DECLARE variables → CTE to capture old values
--   - GETDATE() → NOW() (3 occurrences)
--   - SELECT @OldPrice = Price, @OldStock = StockQuantity → CTE subquery
--   - Modified to use CTEs for capturing old values before update
-- =============================================================================

BEGIN;
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    ),
    product_update AS (
        UPDATE Products
        SET 
            Name = @Name,
            Description = @Description,
            Price = @Price,
            StockQuantity = @StockQuantity,
            ModifiedDate = NOW()
        WHERE ProductId = @ProductId
        RETURNING ProductId
    ),
    history_insert AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, NOW()
        FROM old_values ov
        RETURNING ProductId
    )
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- =============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: DeleteProductAsync(int productId)
-- Complexity: HIGH - Transaction with CTEs to capture values before delete
-- Parameters: @ProductId
-- Changes Applied:
--   - BEGIN TRANSACTION → BEGIN
--   - DECLARE variables → CTE to capture old values
--   - GETDATE() → NOW() (2 occurrences)
--   - SELECT @OldPrice = Price → CTE subquery
--   - CASE expression: Compatible, no changes needed
-- =============================================================================

BEGIN;
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    ),
    history_insert AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, NOW()
        FROM old_values
        RETURNING ProductId
    ),
    product_delete AS (
        DELETE FROM Products 
        WHERE ProductId = @ProductId
        RETURNING ProductId
    )
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

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- =============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Complexity: HIGH - CTE with RANK and PERCENT_RANK window functions
-- Parameters: @MinPrice, @MaxPrice
-- Changes Applied:
--   - RANK() window function: Compatible, no changes needed
--   - PERCENT_RANK() window function: Compatible, no changes needed
--   - CTE syntax: Compatible, no changes needed
--   - CASE expressions: Compatible, no changes needed
--   - Parameters @MinPrice, @MaxPrice: Kept as named parameters
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- =============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Complexity: HIGH - CTE with multiple window functions
-- Parameters: @Threshold
-- Changes Applied:
--   - AVG/MIN/MAX OVER() window functions: Compatible, no changes needed
--   - CTE syntax: Compatible, no changes needed
--   - CASE expressions: Compatible, no changes needed
--   - ROUND function: Compatible, no changes needed
--   - Parameter @Threshold: Kept as named parameter
-- =============================================================================

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

-- =============================================================================
-- CONVERSION SUMMARY
-- =============================================================================
-- Total Statements Converted: 7
-- Conversion Method: Manual (DMS Tool metadata model creation failed)
-- 
-- Key Conversions Applied:
-- 1. BEGIN TRANSACTION → BEGIN (3 statements: Insert, Update, Delete)
-- 2. COMMIT → COMMIT (3 statements: Insert, Update, Delete)
-- 3. GETDATE() → NOW() (8 occurrences across Insert, Update, Delete statements)
-- 4. SCOPE_IDENTITY() → RETURNING clause + CTE (1 statement: Insert)
-- 5. DECLARE variables → CTEs for value capture (3 statements: Insert, Update, Delete)
-- 6. Named parameters (@param) → Kept as named (Npgsql supports them)
-- 
-- Statements Requiring No Changes (PostgreSQL Compatible):
-- - Window functions (LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER, MIN OVER, MAX OVER)
-- - CTE (WITH) syntax
-- - CASE expressions
-- - ROUND function
-- - INNER JOIN, LEFT JOIN
-- - BETWEEN operator
-- 
-- Special Notes:
-- - Transaction statements (Insert, Update, Delete) restructured to use CTEs
-- - Insert statement uses RETURNING clause to get new ProductId
-- - Named parameters retained for better code readability in ADO.NET
-- - All schema object names remain unchanged (Products, ProductHistory, ProductStats)
-- =============================================================================
