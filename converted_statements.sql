-- ================================================================================
-- PostgreSQL Converted SQL Statements
-- Conversion Method: Manual conversion after DMS tool failure
-- Date: 2026-02-15
-- ================================================================================
-- All statements were passed through the DMS MCP tool first (as required), but
-- the tool failed with "Unknown metadata model creation status: RECEIVED" error.
-- Manual conversions were performed following PostgreSQL best practices.
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ================================================================================
-- Conversion Notes:
-- - CTE syntax is compatible between MS SQL and PostgreSQL
-- - Window functions (AVG, COUNT) are supported in PostgreSQL
-- - CASE expressions work the same way
-- - ROUND function syntax is identical
-- - No changes needed except removing brackets from table/column names
-- ================================================================================

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
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ================================================================================
-- Conversion Notes:
-- - LAG window function is fully supported in PostgreSQL
-- - Parameters use the same syntax (@ProductId works in Npgsql)
-- - CTE syntax is identical
-- - CASE expressions are compatible
-- ================================================================================

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
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction
-- ================================================================================
-- Conversion Notes:
-- - BEGIN TRANSACTION is replaced with BEGIN (PostgreSQL standard)
-- - SCOPE_IDENTITY() is replaced with RETURNING clause on INSERT
-- - GETDATE() is replaced with CURRENT_TIMESTAMP
-- - Variable declarations stay the same but need DO block for procedural code
-- - Transaction is restructured to return the new ID via RETURNING
-- - Since this will be executed via ExecuteScalarAsync in C#, we restructure
--   to use WITH clause and RETURNING to capture the ID
-- ================================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
),
stats_update AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM inserted_product;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ================================================================================
-- Conversion Notes:
-- - PostgreSQL supports DO blocks for procedural code with variables
-- - GETDATE() is replaced with CURRENT_TIMESTAMP
-- - Since this is executed via ExecuteNonQueryAsync, we can use a DO block
-- - Variable assignment from SELECT is supported in PostgreSQL
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with Conditional Logic
-- ================================================================================
-- Conversion Notes:
-- - Similar to Statement 4, using DO block for procedural code
-- - GETDATE() is replaced with CURRENT_TIMESTAMP
-- - CASE expression in UPDATE is fully compatible
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ================================================================================
-- Conversion Notes:
-- - RANK() and PERCENT_RANK() are fully supported in PostgreSQL
-- - BETWEEN clause works identically
-- - CTE syntax is the same
-- - No changes needed
-- ================================================================================

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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ================================================================================
-- Conversion Notes:
-- - All window functions (AVG, MIN, MAX) are fully supported
-- - ROUND function works the same way
-- - CASE expression is compatible
-- - No changes needed
-- ================================================================================

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
-- Total Statements Converted: 7
-- Conversion Method: Manual (after DMS tool failure)
-- 
-- Key Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
-- 2. GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
-- 3. BEGIN TRANSACTION/COMMIT → DO blocks for procedural code (Statements 3, 4, 5)
-- 4. Variable naming: @VarName → v_VarName in DO blocks
-- 5. Removed SQL Server specific brackets from identifiers
-- 
-- PostgreSQL Features Utilized:
-- - CTEs (WITH clauses) - fully compatible
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) - fully compatible
-- - CASE expressions - fully compatible
-- - DO blocks for procedural code with variables
-- - RETURNING clause for capturing inserted IDs
-- - WITH clause for chaining multiple DML statements
-- ================================================================================
