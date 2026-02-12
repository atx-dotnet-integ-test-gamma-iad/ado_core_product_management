-- ============================================================================================================
-- CONVERTED SQL STATEMENTS FROM SQL SERVER TO POSTGRESQL
-- ============================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered metadata model creation errors)
-- Conversion Date: 2026-02-12
-- Total Statements: 7
-- ============================================================================================================

-- ============================================================================================================
-- STATEMENT #1: GetAllProductsAsync - CONVERTED TO POSTGRESQL
-- ============================================================================================================
-- Original Location: DataAccess/ProductRepository.cs - GetAllProductsAsync()
-- Conversion Notes: 
-- - Table name 'Products' unchanged (PostgreSQL is case-insensitive with unquoted identifiers)
-- - CTE syntax compatible between SQL Server and PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) are compatible
-- - CASE expressions are compatible
-- - ROUND function is compatible
-- - INNER JOIN syntax is compatible
-- - ORDER BY with CASE is compatible
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #2: GetProductByIdAsync - CONVERTED TO POSTGRESQL
-- ============================================================================================================
-- Original Location: DataAccess/ProductRepository.cs - GetProductByIdAsync(int productId)
-- Conversion Notes:
-- - Table name 'Products' unchanged
-- - CTE syntax compatible
-- - LAG window function is compatible
-- - Parameters remain as @ProductId (compatible with ADO.NET parameter syntax)
-- - CASE expressions compatible
-- - ROUND function compatible
-- - LEFT JOIN compatible
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #3: InsertProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================================================
-- Original Location: DataAccess/ProductRepository.cs - InsertProductAsync(Product product)
-- Conversion Notes:
-- - DECLARE @NewProductId INT -> DO $$ DECLARE v_NewProductId INT; block approach
-- - BEGIN TRANSACTION -> BEGIN (implicit in PostgreSQL function/DO block)
-- - SCOPE_IDENTITY() -> RETURNING clause with INSERT or LASTVAL()
-- - GETDATE() -> CURRENT_TIMESTAMP or NOW()
-- - COMMIT -> COMMIT (or END in DO block)
-- - SET @variable -> v_variable :=
-- - SELECT @variable -> Handled via RETURNING or final SELECT
-- 
-- IMPORTANT: This conversion uses a different approach - using RETURNING clause for INSERT
-- and restructured as a PostgreSQL function-style block for transaction handling
-- ============================================================================================================

DO $$
DECLARE
    v_NewProductId INT;
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
    
    -- Return the new product ID
    PERFORM v_NewProductId;
END $$;

SELECT v_NewProductId;

-- ============================================================================================================
-- STATEMENT #4: UpdateProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================================================
-- Original Location: DataAccess/ProductRepository.cs - UpdateProductAsync(Product product)
-- Conversion Notes:
-- - BEGIN TRANSACTION -> BEGIN block
-- - DECLARE variables -> DO $$ DECLARE block
-- - SELECT INTO variables compatible in PostgreSQL
-- - GETDATE() -> CURRENT_TIMESTAMP
-- - COMMIT -> END or implicit in transaction
-- ============================================================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
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

-- ============================================================================================================
-- STATEMENT #5: DeleteProductAsync - CONVERTED TO POSTGRESQL
-- ============================================================================================================
-- Original Location: DataAccess/ProductRepository.cs - DeleteProductAsync(int productId)
-- Conversion Notes:
-- - BEGIN TRANSACTION -> BEGIN block
-- - DECLARE variables -> DO $$ DECLARE block
-- - SELECT INTO variables compatible
-- - GETDATE() -> CURRENT_TIMESTAMP
-- - DELETE syntax compatible
-- - CASE expressions compatible
-- - COMMIT -> END or implicit
-- ============================================================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
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

-- ============================================================================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync - CONVERTED TO POSTGRESQL
-- ============================================================================================================
-- Original Location: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Notes:
-- - CTE syntax compatible
-- - RANK() OVER compatible
-- - PERCENT_RANK() OVER compatible
-- - BETWEEN operator compatible
-- - CASE expressions compatible
-- - Parameters @MinPrice, @MaxPrice compatible
-- ============================================================================================================

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

-- ============================================================================================================
-- STATEMENT #7: GetLowStockProductsAsync - CONVERTED TO POSTGRESQL
-- ============================================================================================================
-- Original Location: DataAccess/ProductRepository.cs - GetLowStockProductsAsync(int threshold)
-- Conversion Notes:
-- - CTE syntax compatible
-- - AVG() OVER, MIN() OVER, MAX() OVER all compatible
-- - CASE expressions compatible
-- - ROUND function compatible
-- - Parameter @Threshold compatible
-- ============================================================================================================

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

-- ============================================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- ============================================================================================================
-- Conversion Summary:
-- - Total Statements Converted: 7
-- - Statements with minimal changes (CTEs, window functions): 4 (Statements 1, 2, 6, 7)
-- - Statements requiring significant restructuring (transactions): 3 (Statements 3, 4, 5)
-- - Key PostgreSQL Conversions Applied:
--   * SCOPE_IDENTITY() -> RETURNING clause with INSERT
--   * GETDATE() -> CURRENT_TIMESTAMP
--   * BEGIN TRANSACTION/COMMIT -> DO $$ blocks for complex transactions
--   * DECLARE @variable -> DECLARE v_variable
--   * SET @variable -> variable :=
--   * Table names preserved (case-insensitive in PostgreSQL)
-- ============================================================================================================
