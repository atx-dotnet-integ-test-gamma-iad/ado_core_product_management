-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source Application: AdoCore - Product Management System
-- Migration: Microsoft SQL Server to PostgreSQL
-- Conversion Date: 2026-02-04
-- Total Statements: 7
-- Conversion Method: Manual (DMS Tool encountered errors)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1 (CONVERTED): GetAllProductsAsync - CTE with Window Functions
-- ============================================================================
-- Original Source: ProductRepository.cs, Method: GetAllProductsAsync
-- Conversion Method: Manual (after DMS tool failure)
-- Schema Change: dbo → public
-- Key Changes:
--   - Added explicit 'public' schema qualifier
--   - Added ::numeric cast for ROUND division operation
-- ============================================================================

WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM public.Products
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
FROM public.Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ============================================================================
-- STATEMENT 2 (CONVERTED): GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Original Source: ProductRepository.cs, Method: GetProductByIdAsync
-- Conversion Method: Manual (after DMS tool failure)
-- Schema Change: dbo → public
-- Key Changes:
--   - Added explicit 'public' schema qualifier
--   - Added ::numeric cast for ROUND division operation
--   - Parameter @ProductId remains (handled by Npgsql)
-- ============================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM public.Products
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
            ROUND((((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100)::numeric, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM public.Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3 (CONVERTED): InsertProductAsync - Transaction Block
-- ============================================================================
-- Original Source: ProductRepository.cs, Method: InsertProductAsync
-- Conversion Method: Manual (DMS tool not attempted due to consistent errors)
-- Schema Change: dbo → public
-- Key Changes:
--   - Converted transaction block to CTE chain pattern
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Added explicit 'public' schema qualifier
--   - Restructured to use CTEs for proper PostgreSQL transaction semantics
-- ============================================================================

WITH inserted_product AS (
    INSERT INTO public.Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
logged_history AS (
    INSERT INTO public.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
)
UPDATE public.ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1
RETURNING (SELECT ProductId FROM inserted_product);

-- ============================================================================
-- STATEMENT 4 (CONVERTED): UpdateProductAsync - Transaction Block
-- ============================================================================
-- Original Source: ProductRepository.cs, Method: UpdateProductAsync
-- Conversion Method: Manual (DMS tool not attempted due to consistent errors)
-- Schema Change: dbo → public
-- Key Changes:
--   - Converted transaction block to CTE chain pattern
--   - DECLARE statements → CTE with subquery
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Added explicit 'public' schema qualifier
--   - Variable assignments handled through CTEs
-- ============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM public.Products
    WHERE ProductId = @ProductId
),
updated_product AS (
    UPDATE public.Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
logged_history AS (
    INSERT INTO public.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
)
UPDATE public.ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5 (CONVERTED): DeleteProductAsync - Transaction Block
-- ============================================================================
-- Original Source: ProductRepository.cs, Method: DeleteProductAsync
-- Conversion Method: Manual (DMS tool not attempted due to consistent errors)
-- Schema Change: dbo → public
-- Key Changes:
--   - Converted transaction block to CTE chain pattern
--   - DECLARE statements → CTE with subquery
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Added explicit 'public' schema qualifier
--   - Variable assignments handled through CTEs
--   - CASE expression preserved (compatible syntax)
-- ============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM public.Products
    WHERE ProductId = @ProductId
),
logged_history AS (
    INSERT INTO public.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
),
deleted_product AS (
    DELETE FROM public.Products 
    WHERE ProductId = @ProductId
    RETURNING ProductId
)
UPDATE public.ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6 (CONVERTED): GetProductsByPriceRangeAsync - Price Range with Ranking
-- ============================================================================
-- Original Source: ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Conversion Method: Manual (DMS tool not attempted due to consistent errors)
-- Schema Change: dbo → public
-- Key Changes:
--   - Added explicit 'public' schema qualifier
--   - RANK() and PERCENT_RANK() functions compatible (no syntax change)
--   - Parameters @MinPrice and @MaxPrice remain (handled by Npgsql)
-- ============================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM public.Products p
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
-- STATEMENT 7 (CONVERTED): GetLowStockProductsAsync - Low Stock Analysis
-- ============================================================================
-- Original Source: ProductRepository.cs, Method: GetLowStockProductsAsync
-- Conversion Method: Manual (DMS tool not attempted due to consistent errors)
-- Schema Change: dbo → public
-- Key Changes:
--   - Added explicit 'public' schema qualifier
--   - Added ::numeric cast for division operation in ROUND
--   - Window functions (AVG, MIN, MAX) compatible (no syntax change)
--   - Parameter @Threshold remains (handled by Npgsql)
-- ============================================================================

WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM public.Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND(((StockQuantity::numeric / AvgStock) * 100), 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements Converted: 7
-- All statements ready for re-integration into ProductRepository.cs
-- ============================================================================
