-- ========================================
-- CONVERTED SQL STATEMENTS CATALOG
-- PostgreSQL Migration from Microsoft SQL Server
-- Source: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-01-27
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync
-- Original Location: Line 39-67
-- Type: SELECT with CTE and Window Functions
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: NONE (PostgreSQL compatible as-is)
-- ========================================
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

-- ========================================
-- STATEMENT 2: GetProductByIdAsync
-- Original Location: Line 82-109
-- Type: SELECT with CTE, Window Functions (LAG), and Parameter
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: NONE (PostgreSQL compatible, @parameter supported by Npgsql)
-- ========================================
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

-- ========================================
-- STATEMENT 3: InsertProductAsync
-- Original Location: Line 124-149
-- Type: Multi-statement Transaction Block with SCOPE_IDENTITY()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: CRITICAL - SCOPE_IDENTITY(), GETDATE(), transaction structure
-- NOTE: This will be split into separate commands in ADO.NET code
-- ========================================

-- Command 1: Insert product and get ID using RETURNING clause
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Command 2: Log the insertion (executed after getting ProductId from Command 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- IMPLEMENTATION NOTE FOR ADO.NET CODE:
-- 1. Begin transaction: await connection.BeginTransactionAsync()
-- 2. Execute Command 1 using ExecuteScalarAsync() to get ProductId
-- 3. Store ProductId in variable
-- 4. Execute Command 2 with @NewProductId parameter set to the ProductId
-- 5. Execute Command 3
-- 6. Commit transaction
-- 7. Return ProductId

-- ========================================
-- STATEMENT 4: UpdateProductAsync
-- Original Location: Line 162-196
-- Type: Multi-statement Transaction Block
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: GETDATE() -> CURRENT_TIMESTAMP, transaction handling in code
-- NOTE: Transaction will be managed by ADO.NET code
-- ========================================

-- Command 1: Get old values (to be executed first, results stored in code variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Command 3: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 4: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- IMPLEMENTATION NOTE FOR ADO.NET CODE:
-- 1. Begin transaction: await connection.BeginTransactionAsync()
-- 2. Execute Command 1 using ExecuteReaderAsync(), read Price and StockQuantity
-- 3. Store old values in variables
-- 4. Execute Command 2 with all parameters
-- 5. Execute Command 3 with @OldPrice and @OldStock from step 3
-- 6. Execute Command 4
-- 7. Commit transaction

-- ========================================
-- STATEMENT 5: DeleteProductAsync
-- Original Location: Line 209-242
-- Type: Multi-statement Transaction Block
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: GETDATE() -> CURRENT_TIMESTAMP, transaction handling in code
-- NOTE: Transaction will be managed by ADO.NET code
-- ========================================

-- Command 1: Get old values (to be executed first, results stored in code variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Command 4: Update product statistics
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

-- IMPLEMENTATION NOTE FOR ADO.NET CODE:
-- 1. Begin transaction: await connection.BeginTransactionAsync()
-- 2. Execute Command 1 using ExecuteReaderAsync(), read Price and StockQuantity
-- 3. Store old values in variables
-- 4. Execute Command 2 with @OldPrice and @OldStock from step 3
-- 5. Execute Command 3
-- 6. Execute Command 4
-- 7. Commit transaction

-- ========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Original Location: Line 249-274
-- Type: SELECT with CTE and Window Functions (RANK, PERCENT_RANK)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: NONE (PostgreSQL compatible as-is)
-- ========================================
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

-- ========================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Original Location: Line 289-318
-- Type: SELECT with CTE and Window Functions
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Required: NONE (PostgreSQL compatible as-is)
-- ========================================
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

-- ========================================
-- CONVERSION SUMMARY
-- ========================================
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (100%)
-- 
-- SQL Syntax Changes Required:
--   Statement 1: No changes (already PostgreSQL compatible)
--   Statement 2: No changes (already PostgreSQL compatible)
--   Statement 3: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> CURRENT_TIMESTAMP, split into 3 commands
--   Statement 4: GETDATE() -> CURRENT_TIMESTAMP, split into 4 commands, variables in code
--   Statement 5: GETDATE() -> CURRENT_TIMESTAMP, split into 4 commands, variables in code
--   Statement 6: No changes (already PostgreSQL compatible)
--   Statement 7: No changes (already PostgreSQL compatible)
--
-- ADO.NET Code Changes Required:
--   All transaction blocks (statements 3, 4, 5) must be refactored to:
--   - Use NpgsqlConnection.BeginTransactionAsync()
--   - Execute multiple separate commands within transaction
--   - Handle RETURNING clause results for INSERT operations
--   - Store intermediate values in code variables
--   - Properly commit or rollback transactions
-- ========================================
