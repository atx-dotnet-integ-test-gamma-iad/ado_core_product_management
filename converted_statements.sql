-- ================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Microsoft SQL Server to PostgreSQL Migration
-- ================================================================================
-- This file contains all SQL statements after conversion to PostgreSQL syntax
-- Methods with transactions have been refactored to use ADO.NET transaction objects
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool failed)
-- Changes: None required - statement is PostgreSQL compatible
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
-- STATEMENT 2: GetProductByIdAsync
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool failed)
-- Changes: None required - statement is PostgreSQL compatible
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
-- STATEMENT 3a: InsertProductAsync - Insert Statement
-- File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Conversion Method: ADO.NET TRANSACTION REFACTORING
-- Changes: 
--   - Removed DECLARE @NewProductId INT and SET @NewProductId = LASTVAL()
--   - Replaced with PostgreSQL RETURNING clause
--   - Transaction handling moved to ADO.NET BeginTransactionAsync/CommitAsync
-- ================================================================================
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- ================================================================================
-- STATEMENT 3b: InsertProductAsync - History Insert
-- ================================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- ================================================================================
-- STATEMENT 3c: InsertProductAsync - Stats Update
-- ================================================================================
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 4a: UpdateProductAsync - Select Old Values
-- File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Conversion Method: ADO.NET TRANSACTION REFACTORING
-- Changes:
--   - Removed DECLARE @OldPrice and @OldStock
--   - Old values retrieved via SELECT into C# variables
--   - Transaction handling moved to ADO.NET BeginTransactionAsync/CommitAsync
--   - GETDATE() replaced with CURRENT_TIMESTAMP
-- ================================================================================
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- ================================================================================
-- STATEMENT 4b: UpdateProductAsync - Update Product
-- ================================================================================
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- ================================================================================
-- STATEMENT 4c: UpdateProductAsync - Insert History
-- ================================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- ================================================================================
-- STATEMENT 4d: UpdateProductAsync - Update Stats
-- ================================================================================
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 5a: DeleteProductAsync - Select Old Values
-- File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Conversion Method: ADO.NET TRANSACTION REFACTORING
-- Changes:
--   - Removed DECLARE @OldPrice and @OldStock
--   - Old values retrieved via SELECT into C# variables
--   - Transaction handling moved to ADO.NET BeginTransactionAsync/CommitAsync
--   - GETDATE() replaced with CURRENT_TIMESTAMP
-- ================================================================================
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- ================================================================================
-- STATEMENT 5b: DeleteProductAsync - Insert History
-- ================================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- ================================================================================
-- STATEMENT 5c: DeleteProductAsync - Delete Product
-- ================================================================================
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- ================================================================================
-- STATEMENT 5d: DeleteProductAsync - Update Stats
-- ================================================================================
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool failed)
-- Changes: None required - statement is PostgreSQL compatible
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
-- STATEMENT 7: GetLowStockProductsAsync
-- File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool failed)
-- Changes: None required - statement is PostgreSQL compatible
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
-- Total Original Statements: 7
-- Total Converted Statements: 16 (some statements split into multiple for ADO.NET transaction handling)
-- 
-- Conversion Breakdown:
-- - 4 statements unchanged (already PostgreSQL compatible)
-- - 3 statements refactored from SQL Server transaction blocks to ADO.NET transactions
--   (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
--
-- Key Changes Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. DECLARE/SET variables → C# local variables with SELECT INTO
-- 4. BEGIN TRANSACTION/COMMIT → ADO.NET BeginTransactionAsync()/CommitAsync()
-- 5. Multi-statement transaction blocks → Separate SQL commands within ADO.NET transaction
-- ================================================================================
