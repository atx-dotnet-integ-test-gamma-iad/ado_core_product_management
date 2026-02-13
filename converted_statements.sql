-- ============================================================================
-- PostgreSQL Converted SQL Statements
-- Source: ProductRepository.cs
-- Purpose: PostgreSQL equivalents of all SQL Server statements
-- Conversion Method: Manual (after DMS tool failures)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original Method: GetAllProductsAsync
-- Conversion: Manual (DMS tool failed)
-- Changes: No syntax changes needed - PostgreSQL supports CTEs and window functions
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Original Method: GetProductByIdAsync
-- Conversion: Manual (DMS tool failed)
-- Changes: No syntax changes needed - PostgreSQL supports CTEs, LAG, and parameters
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Original Method: InsertProductAsync
-- Conversion: Manual (DMS tool failed)
-- Changes:
--   1. Removed DECLARE @NewProductId - PostgreSQL handles this differently
--   2. Removed BEGIN TRANSACTION/COMMIT - will be handled by application code
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause
--   4. Replaced GETDATE() with CURRENT_TIMESTAMP
--   5. Combined INSERT and ID retrieval into single statement with RETURNING
-- Note: Transaction management will be handled at application level via NpgsqlTransaction
-- ----------------------------------------------------------------------------
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
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1
RETURNING (SELECT ProductId FROM inserted_product);

-- NOTE: The above is too complex for a single statement. Breaking into separate statements:

-- Part 1: Insert product and get ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Part 2: Insert into ProductHistory (using the returned ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Part 3: Update ProductStats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ----------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original Method: UpdateProductAsync
-- Conversion: Manual (DMS tool failed)
-- Changes:
--   1. Removed BEGIN TRANSACTION/COMMIT - will be handled by application code
--   2. Removed DECLARE statements - will use DO block or handle in application
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
-- Note: Transaction management will be handled at application level
-- PostgreSQL version using DO block:
-- ----------------------------------------------------------------------------
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

-- Simplified version (breaking into multiple statements for ADO.NET execution):
-- Statement 4a: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4c: Insert history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update stats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ----------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original Method: DeleteProductAsync
-- Conversion: Manual (DMS tool failed)
-- Changes:
--   1. Removed BEGIN TRANSACTION/COMMIT - will be handled by application code
--   2. Removed DECLARE statements - will handle in application or use DO block
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
-- Breaking into multiple statements for ADO.NET execution:
-- ----------------------------------------------------------------------------
-- Statement 5a: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Insert history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update stats
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

-- ----------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original Method: GetProductsByPriceRangeAsync
-- Conversion: Manual (DMS tool failed)
-- Changes: No syntax changes needed - PostgreSQL supports RANK and PERCENT_RANK
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Original Method: GetLowStockProductsAsync
-- Conversion: Manual (DMS tool failed)
-- Changes: No syntax changes needed - PostgreSQL supports aggregate window functions
-- ----------------------------------------------------------------------------
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
-- Total Statements Converted: 7
-- Conversion Method: Manual (after DMS tool failures)
-- 
-- Key PostgreSQL Transformations Applied:
--   1. SCOPE_IDENTITY() → RETURNING clause pattern
--   2. GETDATE() → CURRENT_TIMESTAMP
--   3. BEGIN TRANSACTION/COMMIT → Handled at application level via NpgsqlTransaction
--   4. DECLARE variables → DO blocks or application-level handling
--   5. Multi-statement batches → Separated for ADO.NET execution
--
-- Statements requiring multi-step execution (due to transaction blocks):
--   - Statement 3 (InsertProductAsync): 3 separate statements
--   - Statement 4 (UpdateProductAsync): 4 separate statements
--   - Statement 5 (DeleteProductAsync): 4 separate statements
--
-- Statements with no syntax changes (PostgreSQL compatible):
--   - Statement 1 (GetAllProductsAsync)
--   - Statement 2 (GetProductByIdAsync)
--   - Statement 6 (GetProductsByPriceRangeAsync)
--   - Statement 7 (GetLowStockProductsAsync)
-- ============================================================================
