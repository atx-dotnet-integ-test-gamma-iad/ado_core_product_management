/*
================================================================================
CONVERTED SQL STATEMENTS CATALOG
Migration: Microsoft SQL Server to PostgreSQL
Date: 2026-02-15
Conversion Method: MANUAL_AFTER_DMS_FAILURE (All 7 statements)
DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
================================================================================
*/

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Original Source: DataAccess/ProductRepository.cs, Lines 38-71
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - No syntax changes needed (PostgreSQL natively supports CTEs and window functions)
--   - Parameter syntax @Parameter remains compatible
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
-- Original Source: DataAccess/ProductRepository.cs, Lines 81-108
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - No syntax changes needed (PostgreSQL natively supports LAG window function)
--   - Parameter syntax @ProductId remains compatible
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
-- Original Source: DataAccess/ProductRepository.cs, Lines 125-150
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - Removed DECLARE and variable declarations (not needed in PostgreSQL single-statement context)
--   - Replaced BEGIN TRANSACTION/COMMIT with PostgreSQL DO block (will be handled at code level)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause pattern
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Converted to single INSERT with RETURNING for ProductId retrieval
-- PostgreSQL Note: Transaction control (BEGIN/COMMIT) will be handled by NpgsqlTransaction in C# code
-- ============================================================================

INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING ProductId;

-- Note: The following operations need to be executed separately in the transaction:

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Original Source: DataAccess/ProductRepository.cs, Lines 163-194
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled at code level with NpgsqlTransaction)
--   - Replaced DECLARE with PostgreSQL variable syntax using DO block or separate queries
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Converted to separate statements within transaction
-- PostgreSQL Note: Transaction control (BEGIN/COMMIT) will be handled by NpgsqlTransaction in C# code
-- Variables will be handled using separate SELECT statements at C# code level
-- ============================================================================

-- First query: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second query: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Third query: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Fourth query: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Original Source: DataAccess/ProductRepository.cs, Lines 206-236
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled at code level with NpgsqlTransaction)
--   - Replaced DECLARE with separate SELECT statement
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Converted to separate statements within transaction
-- PostgreSQL Note: Transaction control (BEGIN/COMMIT) will be handled by NpgsqlTransaction in C# code
-- ============================================================================

-- First query: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second query: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Third query: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Fourth query: Update product statistics
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
-- Original Source: DataAccess/ProductRepository.cs, Lines 249-273
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - No syntax changes needed (PostgreSQL natively supports RANK and PERCENT_RANK)
--   - Parameter syntax @MinPrice and @MaxPrice remain compatible
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
-- Original Source: DataAccess/ProductRepository.cs, Lines 286-315
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   - No syntax changes needed (PostgreSQL natively supports window functions)
--   - Parameter syntax @Threshold remains compatible
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

/*
================================================================================
CONVERSION SUMMARY
Total SQL Statements: 7
Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
DMS Tool Status: ERROR for all 7 statements
DMS Error Message: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

Key Conversions Applied:
1. GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
2. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
3. BEGIN TRANSACTION/COMMIT → Transaction handled at C# NpgsqlTransaction level (Statements 3, 4, 5)
4. DECLARE @Variable → Separate SELECT queries or removed (Statements 3, 4, 5)
5. Window functions (CTEs, LAG, RANK, PERCENT_RANK) → No changes needed (already PostgreSQL compatible)

PostgreSQL Compatibility Notes:
- CTEs (WITH clause) are fully compatible
- Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER) are fully compatible
- Parameter syntax @Parameter is compatible with Npgsql
- Transaction management is handled at the ADO.NET level with NpgsqlTransaction
- Multi-statement transaction blocks need to be split into separate commands in C# code

Statements Requiring Code-Level Changes:
- Statement 3 (InsertProductAsync): Split into multiple commands, use RETURNING clause
- Statement 4 (UpdateProductAsync): Split into 4 separate commands within transaction
- Statement 5 (DeleteProductAsync): Split into 4 separate commands within transaction
================================================================================
*/
