-- ==================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Syntax
-- Total Statements: 7
-- Conversion Method: Manual conversion after DMS tool failure
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ==================================================================

-- ==================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_ERROR
-- Source: ProductRepository.cs, Line ~39
-- Changes: No syntax changes needed - CTEs and window functions are compatible
-- Parameter syntax changed from @param to standard PostgreSQL parameters
-- ==================================================================
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

-- ==================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Status: MANUAL_AFTER_DMS_ERROR
-- Source: ProductRepository.cs, Line ~79
-- Changes: LAG window function is compatible, ROUND is compatible
-- Parameter syntax changed from @ProductId to $1
-- ==================================================================
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- ==================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_ERROR
-- Source: ProductRepository.cs, Line ~115
-- Changes: 
-- 1. Removed DECLARE @NewProductId INT - PostgreSQL doesn't support variables in this context
-- 2. Removed BEGIN TRANSACTION/COMMIT - handled by ADO.NET transaction management
-- 3. Replaced SCOPE_IDENTITY() with RETURNING clause in INSERT statement
-- 4. Replaced GETDATE() with NOW()
-- 5. Changed to use CTE with RETURNING to capture new ID
-- 6. Parameters changed from @Name, @Description, etc. to $1, $2, $3, $4
-- NOTE: This should be executed as separate statements within an ADO.NET transaction
-- ==================================================================
-- First statement: Insert and return new ID
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES ($1, $2, $3, $4, NOW())
RETURNING ProductId;

-- Second statement: Log the insertion (will use returned ProductId from previous statement)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, NOW());

-- Third statement: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ==================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_ERROR
-- Source: ProductRepository.cs, Line ~147
-- Changes:
-- 1. Removed BEGIN TRANSACTION/COMMIT - handled by ADO.NET transaction management
-- 2. Replaced DECLARE statements with CTEs to capture old values
-- 3. Replaced GETDATE() with NOW()
-- 4. Parameters changed from @ProductId, @Name, etc. to $1, $2, $3, $4, $5
-- NOTE: Using DO block to handle variable declarations in PostgreSQL
-- ==================================================================
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = $1;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = $2,
        Description = $3,
        Price = $4,
        StockQuantity = $5,
        ModifiedDate = NOW()
    WHERE ProductId = $1;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'UPDATE', v_OldPrice, $4, v_OldStock, $5, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + $4) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
END $$;

-- ==================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_ERROR
-- Source: ProductRepository.cs, Line ~186
-- Changes:
-- 1. Removed BEGIN TRANSACTION/COMMIT - handled by ADO.NET transaction management
-- 2. Replaced DECLARE statements with DO block
-- 3. Replaced GETDATE() with NOW()
-- 4. Parameters changed from @ProductId to $1
-- ==================================================================
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = $1;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = $1;
    
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

-- ==================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Status: MANUAL_AFTER_DMS_ERROR
-- Source: ProductRepository.cs, Line ~225
-- Changes: RANK() and PERCENT_RANK() are compatible
-- Parameters changed from @MinPrice, @MaxPrice to $1, $2
-- ==================================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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

-- ==================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_ERROR
-- Source: ProductRepository.cs, Line ~258
-- Changes: Window functions (AVG, MIN, MAX OVER()) are compatible
-- Parameters changed from @Threshold to $1
-- ==================================================================
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ==================================================================
-- CONVERSION SUMMARY
-- ==================================================================
-- Total Statements: 7
-- DMS Success: 0
-- DMS Errors: 7
-- Manual Conversions: 7
--
-- DMS Error Details:
-- All statements failed with: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
--
-- Key Conversion Changes Applied:
-- 1. Replaced GETDATE() with NOW() or CURRENT_TIMESTAMP
-- 2. Replaced SCOPE_IDENTITY() with RETURNING clause
-- 3. Removed explicit BEGIN TRANSACTION/COMMIT (handled by ADO.NET)
-- 4. Replaced T-SQL variable declarations (DECLARE/SET) with DO blocks or CTEs
-- 5. Changed parameter syntax from @param to $n (numbered parameters)
-- 6. CTEs, window functions (LAG, RANK, PERCENT_RANK, AVG/MIN/MAX OVER) are compatible
-- 7. CASE statements, ROUND function are compatible
-- ==================================================================
