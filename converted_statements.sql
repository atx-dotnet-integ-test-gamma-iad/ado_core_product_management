-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Conversion Date: 2025-01-31
-- Source: Microsoft SQL Server T-SQL
-- Target: PostgreSQL
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Changes: NONE - Already PostgreSQL compatible
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (int)
-- Changes: NONE - Already PostgreSQL compatible
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
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Changes: MAJOR RESTRUCTURING REQUIRED
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Multi-statement transaction split into separate commands
-- Note: This requires CODE CHANGES in ProductRepository.cs to execute
--       as multiple NpgsqlCommand objects within a single transaction
-- ============================================================================

-- First command: Insert product and get ID using RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Second command: Insert into ProductHistory (use returned ID)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Third command: Update ProductStats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Changes: Transaction split into multiple commands, GETDATE → CURRENT_TIMESTAMP
-- Note: This requires CODE CHANGES in ProductRepository.cs
-- ============================================================================

-- First command: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Second command: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Third command: Insert history (use old values from first command)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Fourth command: Update stats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId
-- Changes: Transaction split into multiple commands, GETDATE → CURRENT_TIMESTAMP
-- Note: This requires CODE CHANGES in ProductRepository.cs
-- ============================================================================

-- First command: Get old values before delete
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Second command: Insert history record
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Third command: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Fourth command: Update stats
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice, @MaxPrice
-- Changes: NONE - Already PostgreSQL compatible
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold
-- Changes: NONE - Already PostgreSQL compatible
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
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- Conversion Method for ALL: MANUAL_AFTER_DMS_FAILURE
-- Reason: DMS MCP tool failed for all statements (metadata model creation/conversion timeouts)
--
-- Statements with No Changes (Already PostgreSQL Compatible): 4
--   - Statement 1: GetAllProductsAsync
--   - Statement 2: GetProductByIdAsync
--   - Statement 6: GetProductsByPriceRangeAsync
--   - Statement 7: GetLowStockProductsAsync
--
-- Statements Requiring Code Changes: 3
--   - Statement 3: InsertProductAsync (Major: RETURNING clause, transaction restructure)
--   - Statement 4: UpdateProductAsync (Moderate: Split into multiple commands)
--   - Statement 5: DeleteProductAsync (Moderate: Split into multiple commands)
--
-- Key Transformations Applied:
--   1. GETDATE() → CURRENT_TIMESTAMP (3 statements)
--   2. SCOPE_IDENTITY() → RETURNING clause (1 statement)
--   3. Multi-statement DECLARE/BEGIN TRANSACTION → Separate commands (3 statements)
--   4. All parameter syntax (@Parameter) remains compatible with Npgsql
--
-- CRITICAL: Statements 3, 4, and 5 require APPLICATION CODE CHANGES in
--           ProductRepository.cs to properly handle the restructured SQL
-- ============================================================================
