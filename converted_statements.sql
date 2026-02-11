-- ============================================================================
-- CONVERTED SQL STATEMENTS FROM SQL SERVER TO POSTGRESQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Date: Migration Phase 2
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- DMS Tool Status: All conversions failed with metadata model creation error
-- ============================================================================

-- ============================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Original Method: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 38-72
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None - PostgreSQL supports this syntax identically
-- Schema Object Changes: None
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
-- CONVERTED STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Original Method: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 78-109
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None - PostgreSQL supports LAG window function identically
-- Schema Object Changes: None
-- Notes: @ProductId parameter is compatible with Npgsql
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
-- CONVERTED STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Original Method: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 117-141
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. Removed DECLARE @NewProductId INT - handled by RETURNING clause
--   2. BEGIN TRANSACTION -> BEGIN
--   3. SCOPE_IDENTITY() replaced with RETURNING ProductId on INSERT
--   4. GETDATE() -> NOW() (3 occurrences)
--   5. Removed SET @NewProductId = SCOPE_IDENTITY()
--   6. Removed final SELECT @NewProductId - use RETURNING instead
-- Schema Object Changes: None
-- Implementation Note: The RETURNING clause will return the new ProductId directly
-- ============================================================================

BEGIN;
    -- Insert the new product and return the new ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: The above RETURNING will provide @NewProductId in application code
    -- The following statements reference it via last inserted ID
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (currval(pg_get_serial_sequence('Products', 'ProductId')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ============================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Original Method: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 149-179
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. Wrapped in DO block for variable support
--   2. DECLARE @OldPrice DECIMAL(18,2) -> DECLARE v_OldPrice DECIMAL(18,2)
--   3. DECLARE @OldStock INT -> DECLARE v_OldStock INT
--   4. SELECT ... INTO variable syntax adjusted for PostgreSQL
--   5. GETDATE() -> NOW() (3 occurrences)
--   6. Variable references updated to v_OldPrice, v_OldStock
-- Schema Object Changes: None
-- ============================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
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
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
END $$;

-- ============================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Original Method: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 187-220
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   1. Wrapped in DO block for variable support
--   2. DECLARE @OldPrice DECIMAL(18,2) -> DECLARE v_OldPrice DECIMAL(18,2)
--   3. DECLARE @OldStock INT -> DECLARE v_OldStock INT
--   4. SELECT ... INTO variable syntax adjusted for PostgreSQL
--   5. GETDATE() -> NOW() (2 occurrences)
--   6. Variable references updated to v_OldPrice, v_OldStock
-- Schema Object Changes: None
-- ============================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - v_OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = NOW()
    WHERE StatId = 1;
END $$;

-- ============================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Original Method: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 228-253
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None - PostgreSQL supports RANK() and PERCENT_RANK() identically
-- Schema Object Changes: None
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
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Original Method: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 261-288
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied: None - PostgreSQL supports all window functions identically
-- Schema Object Changes: None
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
-- END OF CONVERTED SQL STATEMENTS
-- ============================================================================
-- SUMMARY:
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- DMS Tool Failure Reason: Metadata model creation error (infrastructure issue)
-- 
-- Key Conversions Applied:
-- - SCOPE_IDENTITY() -> RETURNING clause + currval()
-- - GETDATE() -> NOW()
-- - BEGIN TRANSACTION -> BEGIN
-- - DECLARE statements -> PostgreSQL DO block syntax
-- - Variable names: @ prefix maintained for Npgsql compatibility
-- - Internal variables: @ prefix changed to v_ prefix
-- 
-- Schema Object Changes: NONE
-- All table names, column names, and schema references remain unchanged
-- ============================================================================
