-- ================================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Date: 2026-01-19
-- Total Statements: 7
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 40-69
-- Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS_FAILURE - Manual PostgreSQL conversion applied
-- Changes Applied:
--   - No syntax changes needed (CTEs, window functions, CASE are PostgreSQL compatible)
--   - Table names remain unchanged (Products)
--   - ROUND function is PostgreSQL compatible
--   - INNER JOIN syntax is PostgreSQL compatible

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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 84-111
-- Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS_FAILURE - Manual PostgreSQL conversion applied
-- Changes Applied:
--   - No syntax changes needed (LAG window function is PostgreSQL compatible)
--   - Table names remain unchanged (Products)
--   - Parameter @ProductId kept as-is (ADO.NET will handle parameter syntax)
--   - ROUND and CASE expressions are PostgreSQL compatible

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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 126-148
-- Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS_FAILURE - Manual PostgreSQL conversion applied
-- Changes Applied:
--   - Removed DECLARE statement (PostgreSQL uses DO blocks or handles differently in procedures)
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Changed SCOPE_IDENTITY() to RETURNING clause in INSERT
--   - Changed GETDATE() to CURRENT_TIMESTAMP (PostgreSQL function)
--   - Restructured to return inserted ProductId using RETURNING
--   - Note: This will need code-level changes to handle RETURNING clause properly

DO $$
DECLARE v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ALTERNATIVE SIMPLIFIED VERSION (for use with ExecuteScalarAsync):
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 163-189
-- Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS_FAILURE - Manual PostgreSQL conversion applied
-- Changes Applied:
--   - Changed BEGIN TRANSACTION to BEGIN (though not needed in code as ADO.NET handles transactions)
--   - Changed DECLARE @var to PostgreSQL variable syntax (in DO block)
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Note: Transaction management should be handled at application level with NpgsqlTransaction

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
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ALTERNATIVE: Breaking into separate statements (recommended for ADO.NET)
-- Statement 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Statement 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 3: Log changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 204-231
-- Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS_NOT_ATTEMPTED - Manual PostgreSQL conversion applied
-- Changes Applied:
--   - Changed BEGIN TRANSACTION to BEGIN (transaction handled at application level)
--   - Changed DECLARE @var to PostgreSQL variable syntax
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - CASE expression is PostgreSQL compatible

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
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
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
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ALTERNATIVE: Breaking into separate statements (recommended for ADO.NET)
-- Statement 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Statement 2: Log deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 3: Delete product
DELETE FROM Products WHERE ProductId = @ProductId;

-- Statement 4: Update statistics
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

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 246-267
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS_FAILURE - Manual PostgreSQL conversion applied
-- Changes Applied:
--   - No syntax changes needed (RANK, PERCENT_RANK window functions are PostgreSQL compatible)
--   - Table names remain unchanged (Products)
--   - CASE expression is PostgreSQL compatible
--   - BETWEEN operator is PostgreSQL compatible

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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 284-306
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS_NOT_ATTEMPTED - Manual PostgreSQL conversion applied
-- Changes Applied:
--   - No syntax changes needed (Window functions AVG, MIN, MAX are PostgreSQL compatible)
--   - Table names remain unchanged (Products)
--   - CASE expression is PostgreSQL compatible
--   - ROUND function is PostgreSQL compatible

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

-- ================================================================================
-- CONVERSION SUMMARY
-- ================================================================================
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- 
-- Key Transformations Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
-- 2. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
-- 3. BEGIN TRANSACTION → BEGIN (Statements 3, 4, 5)
-- 4. DECLARE @var → DECLARE v_var (Statements 3, 4, 5)
-- 5. Transaction blocks converted to DO $$ blocks or separate statements
-- 
-- Statements Requiring No Changes (PostgreSQL Compatible):
-- - Statement 1: CTE with window functions (AVG, COUNT OVER)
-- - Statement 2: CTE with LAG window function
-- - Statement 6: CTE with RANK, PERCENT_RANK
-- - Statement 7: CTE with AVG, MIN, MAX window functions
-- 
-- Statements Requiring Transaction Refactoring:
-- - Statement 3: InsertProductAsync - Will use simplified RETURNING approach
-- - Statement 4: UpdateProductAsync - Will break into multiple statements
-- - Statement 5: DeleteProductAsync - Will break into multiple statements
-- 
-- Schema Changes:
-- - No schema object name changes required
-- - All table references remain: Products, ProductHistory, ProductStats
-- ================================================================================
