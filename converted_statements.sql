-- ===============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Syntax
-- Conversion Date: 2026-01-22
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All DMS attempts failed)
-- Purpose: PostgreSQL-compatible versions of all SQL Server T-SQL statements
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync() - CTE with Window Functions
-- Conversion Notes:
--   - CTE syntax is compatible between SQL Server and PostgreSQL
--   - Window functions (AVG OVER, COUNT OVER) are compatible
--   - CASE expressions are compatible
--   - ROUND function is compatible
--   - No schema name changes needed
-- ===============================================================================
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
    p.Name

-- ===============================================================================
-- STATEMENT 2: GetProductByIdAsync() - CTE with LAG Window Function
-- Conversion Notes:
--   - LAG window function is compatible
--   - @ProductId parameter kept as-is (Npgsql supports named parameters)
--   - CTE syntax is compatible
--   - LEFT JOIN is compatible
--   - ROUND and CASE expressions are compatible
-- ===============================================================================
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
WHERE p.ProductId = @ProductId

-- ===============================================================================
-- STATEMENT 3: InsertProductAsync() - Multi-statement Transaction
-- Conversion Notes:
--   - DECLARE @NewProductId INT removed (not needed with RETURNING)
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - SCOPE_IDENTITY() replaced with RETURNING ProductId
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Multi-statement block converted to use DO block or separate commands
--   - For ADO.NET: Split into multiple commands with transaction handling in C#
-- 
-- IMPORTANT: This needs to be split into multiple commands in C# code:
--   1. INSERT with RETURNING to get new ID
--   2. INSERT into ProductHistory
--   3. UPDATE ProductStats
--   All wrapped in a transaction managed by Npgsql
-- ===============================================================================

-- Command 1: Insert product and return the new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Command 2: Insert into history (use returned ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT 4: UpdateProductAsync() - Multi-statement Transaction
-- Conversion Notes:
--   - DECLARE statements not needed in PostgreSQL (can use WITH or separate queries)
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   - DECIMAL(18,2) is compatible with PostgreSQL
--   - For ADO.NET: Use WITH clause or separate SELECT, then UPDATE and INSERT
-- 
-- IMPORTANT: Can be executed as a single statement using WITH clause
-- ===============================================================================

WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, CURRENT_TIMESTAMP
FROM OldValues;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Alternative approach (simpler for ADO.NET - separate commands):
-- Command 1: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Command 3: Insert history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 4: Update stats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT 5: DeleteProductAsync() - Multi-statement Transaction
-- Conversion Notes:
--   - DECLARE statements not needed (use separate SELECT or WITH clause)
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
--   - CASE expression is compatible
--   - For ADO.NET: Separate commands in transaction
-- ===============================================================================

-- Command 1: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Insert history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Command 4: Update stats
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

-- ===============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync() - CTE with RANK Functions
-- Conversion Notes:
--   - CTE syntax is compatible
--   - RANK() OVER and PERCENT_RANK() OVER are compatible
--   - BETWEEN clause is compatible
--   - @MinPrice and @MaxPrice parameters kept as-is
--   - CASE expression is compatible
--   - No changes needed - fully compatible
-- ===============================================================================
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
ORDER BY rp.PriceRank

-- ===============================================================================
-- STATEMENT 7: GetLowStockProductsAsync() - CTE with Multiple Window Functions
-- Conversion Notes:
--   - CTE syntax is compatible
--   - AVG, MIN, MAX window functions are compatible
--   - @Threshold parameter kept as-is
--   - CASE expression is compatible
--   - ROUND function is compatible
--   - No changes needed - fully compatible
-- ===============================================================================
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
ORDER BY StockQuantity

-- ===============================================================================
-- CONVERSION SUMMARY
-- ===============================================================================
-- Total Statements Converted: 7
-- Fully Compatible (no changes): 4 (Statements 1, 2, 6, 7)
-- Minor Changes Required: 3 (Statements 3, 4, 5)
--
-- Key Conversions Applied:
-- 1. GETDATE() → CURRENT_TIMESTAMP (7 occurrences across statements 3, 4, 5)
-- 2. SCOPE_IDENTITY() → RETURNING clause (1 occurrence in statement 3)
-- 3. Multi-statement transactions split into separate commands for ADO.NET (statements 3, 4, 5)
-- 4. Named parameters (@ParameterName) kept as-is - Npgsql supports them
-- 5. DECLARE removed - not needed with PostgreSQL approach
--
-- Schema Changes: NONE
-- Table names remain unchanged
-- ===============================================================================
