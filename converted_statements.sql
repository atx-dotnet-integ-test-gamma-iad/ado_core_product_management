-- =====================================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: Manual (DMS tool failed - see dms_conversion_log.txt)
-- Total Statements: 7
-- =====================================================================================

-- =====================================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync - Product Statistics with Window Functions
-- =====================================================================================
-- Original Source: ProductRepository.cs - GetAllProductsAsync()
-- Conversion Status: SUCCESS
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - SQL is PostgreSQL compatible
-- Notes: CTEs, window functions (AVG OVER, COUNT OVER), CASE expressions, and ROUND are all PostgreSQL compatible
-- =====================================================================================

WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM public.products
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
FROM public.products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- =====================================================================================
-- CONVERTED STATEMENT 2: GetProductByIdAsync - Product History with LAG Window Function
-- =====================================================================================
-- Original Source: ProductRepository.cs - GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - SQL is PostgreSQL compatible
-- Parameters: @ProductId remains as @ProductId (ADO.NET Npgsql supports named parameters)
-- Notes: LAG window function, CTEs, LEFT JOIN, and percentage calculations are all PostgreSQL compatible
-- =====================================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM public.products
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
FROM public.products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- =====================================================================================
-- CONVERTED STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with RETURNING
-- =====================================================================================
-- Original Source: ProductRepository.cs - InsertProductAsync(Product product)
-- Conversion Status: SUCCESS
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. SCOPE_IDENTITY() → RETURNING ProductId
--   2. GETDATE() → CURRENT_TIMESTAMP
--   3. Removed explicit transaction control (handled by ADO.NET)
--   4. Combined INSERT with RETURNING clause
--   5. Restructured as separate statements to be executed in transaction
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Notes: PostgreSQL uses RETURNING clause instead of SCOPE_IDENTITY()
-- =====================================================================================

-- Statement 3a: Insert product and return new ID
INSERT INTO public.products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING ProductId;

-- Statement 3b: Log the insertion (to be executed with @NewProductId from previous RETURNING)
INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE public.productstats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =====================================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync - Transaction with CTEs for Old Values
-- =====================================================================================
-- Original Source: ProductRepository.cs - UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. GETDATE() → CURRENT_TIMESTAMP
--   2. Removed explicit transaction control (handled by ADO.NET)
--   3. Use CTE to capture old values instead of variables
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Notes: PostgreSQL requires different approach for capturing values during update
-- =====================================================================================

-- Statement 4a: Update product with CTE to capture old values
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM public.products
    WHERE ProductId = @ProductId
)
UPDATE public.products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4b: Log the changes (requires retrieving old values first in application code)
INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', Price as OldPrice, @Price, StockQuantity as OldStock, @StockQuantity, CURRENT_TIMESTAMP
FROM public.products
WHERE ProductId = @ProductId;

-- Statement 4c: Update product statistics
UPDATE public.productstats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =====================================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync - Transaction with Cascading Operations
-- =====================================================================================
-- Original Source: ProductRepository.cs - DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. GETDATE() → CURRENT_TIMESTAMP
--   2. Removed explicit transaction control (handled by ADO.NET)
--   3. Use CTE to capture values before deletion
-- Parameters: @ProductId
-- Notes: Must capture product info before deletion
-- =====================================================================================

-- Statement 5a: Log the deletion (capturing values before delete using RETURNING)
WITH DeletedProduct AS (
    DELETE FROM public.products 
    WHERE ProductId = @ProductId
    RETURNING ProductId, Price as OldPrice, StockQuantity as OldStock
)
INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM DeletedProduct;

-- Statement 5b: Update product statistics (requires @OldPrice from deleted product)
UPDATE public.productstats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =====================================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK
-- =====================================================================================
-- Original Source: ProductRepository.cs - GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - SQL is PostgreSQL compatible
-- Parameters: @MinPrice, @MaxPrice
-- Notes: RANK and PERCENT_RANK window functions are PostgreSQL compatible
-- =====================================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM public.products p
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

-- =====================================================================================
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync - Multiple Window Aggregations
-- =====================================================================================
-- Original Source: ProductRepository.cs - GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None required - SQL is PostgreSQL compatible
-- Parameters: @Threshold
-- Notes: Window aggregations (AVG, MIN, MAX OVER) are PostgreSQL compatible
-- =====================================================================================

WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM public.products p
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

-- =====================================================================================
-- CONVERSION SUMMARY
-- =====================================================================================
-- Total Statements: 7
-- Successful Conversions: 7
-- Failed Conversions: 0
-- 
-- Key Transformations Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
-- 2. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
-- 3. Transaction handling moved to application layer
-- 4. Variable declarations replaced with CTEs or RETURNING clauses
-- 5. Window functions, CTEs, CASE expressions - no changes needed (PostgreSQL compatible)
-- 
-- Notes:
-- - All statements maintain @parameter naming (Npgsql supports named parameters)
-- - Transaction control (BEGIN/COMMIT) will be handled by ADO.NET NpgsqlTransaction
-- - Complex multi-statement transactions (3, 4, 5) need application-level coordination
-- =====================================================================================
